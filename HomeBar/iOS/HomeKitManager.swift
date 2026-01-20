//
//  HomeKitManager.swift
//  HomeBar
//
//  HomeKit manager that implements Mac2iOS protocol
//

import Foundation
import HomeKit
import os.log

private let logger = Logger(subsystem: "com.nickustinov.homebar", category: "HomeKitManager")

class HomeKitManager: NSObject, Mac2iOS, HMHomeManagerDelegate {
    
    private var homeManager: HMHomeManager?
    private var currentHome: HMHome?
    
    weak var macOSDelegate: iOS2Mac?
    
    // MARK: - Cached data (stored properties for thread safety)
    
    private(set) var homes: [HomeInfo] = []
    private(set) var rooms: [RoomInfo] = []
    private(set) var accessories: [AccessoryInfo] = []
    private(set) var scenes: [SceneInfo] = []
    
    var selectedHomeIdentifier: UUID? {
        get { currentHome?.uniqueIdentifier }
        set {
            if let id = newValue, let manager = homeManager {
                currentHome = manager.homes.first { $0.uniqueIdentifier == id }
            } else {
                currentHome = homeManager?.primaryHome ?? homeManager?.homes.first
            }
            fetchDataAndReloadMenu()
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        logger.info("HomeKitManager init")
        
        // Initialize HomeManager
        homeManager = HMHomeManager()
        homeManager?.delegate = self
    }
    
    // MARK: - Data fetching
    
    private func fetchDataAndReloadMenu() {
        guard let manager = homeManager else {
            logger.error("No homeManager")
            return
        }
        
        // Populate homes
        homes = manager.homes.map { home in
            HomeInfo(
                uniqueIdentifier: home.uniqueIdentifier,
                name: home.name,
                isPrimary: home == manager.primaryHome
            )
        }
        
        guard let home = currentHome else {
            logger.info("No current home selected")
            rooms = []
            accessories = []
            scenes = []
            sendMenuDataAsJSON()
            return
        }
        
        logger.info("Fetching data for home: \(home.name, privacy: .public)")
        
        // Populate rooms
        rooms = home.rooms.map { room in
            RoomInfo(uniqueIdentifier: room.uniqueIdentifier, name: room.name)
        }.sorted { $0.name < $1.name }
        
        // Populate accessories
        accessories = home.accessories.map { accessory in
            let services = accessory.services.compactMap { service -> ServiceInfo? in
                let supportedTypes = [
                    HMServiceTypeLightbulb,
                    HMServiceTypeSwitch,
                    HMServiceTypeOutlet,
                    HMServiceTypeThermostat,
                    HMServiceTypeHeaterCooler,
                    HMServiceTypeLockMechanism,
                    HMServiceTypeWindowCovering,
                    HMServiceTypeTemperatureSensor,
                    HMServiceTypeHumiditySensor,
                    HMServiceTypeMotionSensor,
                    HMServiceTypeFan,
                    HMServiceTypeGarageDoorOpener,
                    HMServiceTypeContactSensor
                ]
                guard supportedTypes.contains(service.serviceType) else { return nil }

                return ServiceInfo(
                    uniqueIdentifier: service.uniqueIdentifier,
                    name: service.name ?? accessory.name,
                    serviceType: service.serviceType,
                    accessoryName: accessory.name,
                    roomIdentifier: accessory.room?.uniqueIdentifier
                )
            }

            return AccessoryInfo(
                uniqueIdentifier: accessory.uniqueIdentifier,
                name: accessory.name,
                roomIdentifier: accessory.room?.uniqueIdentifier,
                services: services,
                isReachable: accessory.isReachable
            )
        }

        // Populate scenes (exclude built-in automation types)
        let builtInTypes = [
            HMActionSetTypeSleep,
            HMActionSetTypeWakeUp,
            HMActionSetTypeHomeDeparture,
            HMActionSetTypeHomeArrival,
            HMActionSetTypeTriggerOwned
        ]
        scenes = home.actionSets
            .filter { !builtInTypes.contains($0.actionSetType) }
            .map { SceneInfo(uniqueIdentifier: $0.uniqueIdentifier, name: $0.name) }
            .sorted { $0.name < $1.name }
        
        logger.info("Data fetched - rooms: \(self.rooms.count), accessories: \(self.accessories.count), scenes: \(self.scenes.count)")
        
        // Set up delegates
        home.delegate = self
        for accessory in home.accessories {
            accessory.delegate = self
        }
        
        // Serialize to JSON for safe cross-module transfer
        sendMenuDataAsJSON()
    }
    
    // MARK: - Mac2iOS Methods
    
    func reloadHomeKit() {
        fetchDataAndReloadMenu()
    }
    
    func executeScene(identifier: UUID) {
        guard let home = currentHome,
              let actionSet = home.actionSets.first(where: { $0.uniqueIdentifier == identifier }) else { return }
        
        home.executeActionSet(actionSet) { error in
            if let error = error {
                logger.error("Failed to execute scene: \(error.localizedDescription)")
                self.macOSDelegate?.showError(message: "Failed to execute scene: \(error.localizedDescription)")
            }
        }
    }
    
    func readCharacteristic(identifier: UUID) {
        guard let characteristic = findCharacteristic(identifier: identifier) else { return }

        // Check if characteristic is readable
        guard characteristic.properties.contains(HMCharacteristicPropertyReadable) else {
            return
        }

        // Check if accessory is reachable
        guard characteristic.service?.accessory?.isReachable == true else {
            return
        }

        characteristic.readValue { error in
            if error != nil {
                // Silently ignore read failures - device may be temporarily unreachable
                return
            }
            if let value = characteristic.value {
                DispatchQueue.main.async {
                    self.macOSDelegate?.updateCharacteristic(identifier: identifier, value: value)
                }
            }
        }
    }
    
    func writeCharacteristic(identifier: UUID, value: Any) {
        guard let characteristic = findCharacteristic(identifier: identifier) else {
            logger.error("Characteristic not found: \(identifier)")
            return
        }

        // Log characteristic info
        let metadata = characteristic.metadata
        logger.info("""
            WRITE REQUEST:
            - Characteristic: \(characteristic.characteristicType, privacy: .public)
            - Format: \(metadata?.format ?? "nil", privacy: .public)
            - Min: \(String(describing: metadata?.minimumValue))
            - Max: \(String(describing: metadata?.maximumValue))
            - Step: \(String(describing: metadata?.stepValue))
            - Input value: \(String(describing: value)) (type: \(type(of: value)))
            - Writable: \(characteristic.properties.contains(HMCharacteristicPropertyWritable))
            """)

        // Convert value to the format expected by the characteristic
        let convertedValue: Any
        if let format = metadata?.format {
            switch format {
            case HMCharacteristicMetadataFormatFloat:
                if let num = value as? NSNumber {
                    convertedValue = num.floatValue
                } else if let num = value as? Double {
                    convertedValue = Float(num)
                } else if let num = value as? Int {
                    convertedValue = Float(num)
                } else {
                    convertedValue = value
                }
            case HMCharacteristicMetadataFormatInt,
                 HMCharacteristicMetadataFormatUInt8,
                 HMCharacteristicMetadataFormatUInt16,
                 HMCharacteristicMetadataFormatUInt32,
                 HMCharacteristicMetadataFormatUInt64:
                if let num = value as? NSNumber {
                    convertedValue = num.intValue
                } else if let num = value as? Double {
                    convertedValue = Int(num)
                } else if let num = value as? Float {
                    convertedValue = Int(num)
                } else {
                    convertedValue = value
                }
            case HMCharacteristicMetadataFormatBool:
                if let num = value as? NSNumber {
                    convertedValue = num.boolValue
                } else if let num = value as? Int {
                    convertedValue = num != 0
                } else {
                    convertedValue = value
                }
            default:
                convertedValue = value
            }
        } else {
            convertedValue = value
        }

        logger.info("Converted value: \(String(describing: convertedValue)) (type: \(type(of: convertedValue)))")

        characteristic.writeValue(convertedValue) { error in
            if let error = error {
                let nsError = error as NSError
                logger.error("""
                    WRITE FAILED:
                    - Error: \(error.localizedDescription)
                    - Code: \(nsError.code)
                    - Domain: \(nsError.domain)
                    - UserInfo: \(nsError.userInfo)
                    """)
                self.macOSDelegate?.showError(message: "Failed to update: \(error.localizedDescription)")
            } else {
                logger.info("WRITE SUCCESS for \(characteristic.characteristicType, privacy: .public)")
            }
        }
    }
    
    func getCharacteristicValue(identifier: UUID) -> Any? {
        return findCharacteristic(identifier: identifier)?.value
    }
    
    // MARK: - Helper Methods
    
    private func sendMenuDataAsJSON() {
        // Convert to Codable structs
        let homeData = homes.map { HomeData(uniqueIdentifier: $0.uniqueIdentifier, name: $0.name, isPrimary: $0.isPrimary) }
        let roomData = rooms.map { RoomData(uniqueIdentifier: $0.uniqueIdentifier, name: $0.name) }
        let accessoryData = accessories.map { acc in
            AccessoryData(
                uniqueIdentifier: acc.uniqueIdentifier,
                name: acc.name,
                roomIdentifier: acc.roomIdentifier,
                services: acc.services.map { svc in
                    self.buildServiceData(from: svc)
                },
                isReachable: acc.isReachable
            )
        }
        let sceneData = scenes.map { SceneData(uniqueIdentifier: $0.uniqueIdentifier, name: $0.name) }

        let menuData = MenuData(homes: homeData, rooms: roomData, accessories: accessoryData, scenes: sceneData, selectedHomeId: selectedHomeIdentifier)

        do {
            let jsonData = try JSONEncoder().encode(menuData)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                logger.info("Sending JSON menu data (\(jsonString.count) chars)")
                DispatchQueue.main.async {
                    self.macOSDelegate?.reloadMenuWithJSON(jsonString)
                }
            }
        } catch {
            logger.error("Failed to encode menu data: \(error.localizedDescription)")
        }
    }

    private func buildServiceData(from svc: ServiceInfo) -> ServiceData {
        // Find the original HMService to extract characteristic UUIDs
        guard let hmService = findService(identifier: svc.uniqueIdentifier) else {
            return ServiceData(
                uniqueIdentifier: svc.uniqueIdentifier,
                name: svc.name,
                serviceType: svc.serviceType,
                accessoryName: svc.accessoryName,
                roomIdentifier: svc.roomIdentifier
            )
        }

        // Helper to find characteristic UUID by type (using our constants for unavailable HMCharacteristicType*)
        func charId(_ type: String) -> UUID? {
            hmService.characteristics.first { $0.characteristicType == type }?.uniqueIdentifier
        }

        // Helper to find characteristic by type
        func findChar(_ type: String) -> HMCharacteristic? {
            hmService.characteristics.first { $0.characteristicType == type }
        }

        // Get rotation speed min/max from metadata
        let rotationSpeedChar = findChar(CharacteristicTypes.rotationSpeed)
        let rotationSpeedMin = rotationSpeedChar?.metadata?.minimumValue?.doubleValue
        let rotationSpeedMax = rotationSpeedChar?.metadata?.maximumValue?.doubleValue

        return ServiceData(
            uniqueIdentifier: svc.uniqueIdentifier,
            name: svc.name,
            serviceType: svc.serviceType,
            accessoryName: svc.accessoryName,
            roomIdentifier: svc.roomIdentifier,
            powerStateId: charId(HMCharacteristicTypePowerState),
            brightnessId: charId(HMCharacteristicTypeBrightness),
            currentTemperatureId: charId(HMCharacteristicTypeCurrentTemperature),
            targetTemperatureId: charId(HMCharacteristicTypeTargetTemperature),
            heatingCoolingStateId: charId(HMCharacteristicTypeCurrentHeatingCooling),
            targetHeatingCoolingStateId: charId(HMCharacteristicTypeTargetHeatingCooling),
            lockCurrentStateId: charId(CharacteristicTypes.lockCurrentState),
            lockTargetStateId: charId(CharacteristicTypes.lockTargetState),
            currentPositionId: charId(HMCharacteristicTypeCurrentPosition),
            targetPositionId: charId(HMCharacteristicTypeTargetPosition),
            humidityId: charId(HMCharacteristicTypeCurrentRelativeHumidity),
            motionDetectedId: charId(HMCharacteristicTypeMotionDetected),
            // HeaterCooler (AC) characteristics
            activeId: charId(CharacteristicTypes.active),
            currentHeaterCoolerStateId: charId(CharacteristicTypes.currentHeaterCoolerState),
            targetHeaterCoolerStateId: charId(CharacteristicTypes.targetHeaterCoolerState),
            coolingThresholdTemperatureId: charId(CharacteristicTypes.coolingThresholdTemperature),
            heatingThresholdTemperatureId: charId(CharacteristicTypes.heatingThresholdTemperature),
            // Fan characteristics
            rotationSpeedId: charId(CharacteristicTypes.rotationSpeed),
            rotationSpeedMin: rotationSpeedMin,
            rotationSpeedMax: rotationSpeedMax,
            // Garage door characteristics
            currentDoorStateId: charId(CharacteristicTypes.currentDoorState),
            targetDoorStateId: charId(CharacteristicTypes.targetDoorState),
            obstructionDetectedId: charId(CharacteristicTypes.obstructionDetected),
            // Contact sensor characteristics
            contactSensorStateId: charId(CharacteristicTypes.contactSensorState)
        )
    }

    private func findService(identifier: UUID) -> HMService? {
        guard let home = currentHome else { return nil }

        for accessory in home.accessories {
            if let service = accessory.services.first(where: { $0.uniqueIdentifier == identifier }) {
                return service
            }
        }
        return nil
    }
    
    private func findCharacteristic(identifier: UUID) -> HMCharacteristic? {
        guard let home = currentHome else { return nil }
        
        for accessory in home.accessories {
            for service in accessory.services {
                if let characteristic = service.characteristics.first(where: { $0.uniqueIdentifier == identifier }) {
                    return characteristic
                }
            }
        }
        return nil
    }
    
    // MARK: - HMHomeManagerDelegate
    
    func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        logger.info("Authorization status: \(status.rawValue)")
        
        if status.contains(.authorized) {
            logger.info("HomeKit authorized")
        } else if status.contains(.determined) {
            logger.warning("HomeKit not authorized")
            DispatchQueue.main.async {
                self.macOSDelegate?.showError(message: "HomeKit access denied. Enable in System Settings > Privacy & Security > HomeKit")
            }
        }
    }
    
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        logger.info("homeManagerDidUpdateHomes - count: \(manager.homes.count)")
        
        // Select home if none selected
        if currentHome == nil {
            currentHome = manager.primaryHome ?? manager.homes.first
            logger.info("Selected home: \(self.currentHome?.name ?? "none", privacy: .public)")
        }
        
        fetchDataAndReloadMenu()
    }
}

// MARK: - HMHomeDelegate

extension HomeKitManager: HMHomeDelegate {
    func home(_ home: HMHome, didAdd accessory: HMAccessory) {
        accessory.delegate = self
        fetchDataAndReloadMenu()
    }
    
    func home(_ home: HMHome, didRemove accessory: HMAccessory) {
        fetchDataAndReloadMenu()
    }
    
    func home(_ home: HMHome, didAdd room: HMRoom) {
        fetchDataAndReloadMenu()
    }
    
    func home(_ home: HMHome, didRemove room: HMRoom) {
        fetchDataAndReloadMenu()
    }
    
    func home(_ home: HMHome, didAdd actionSet: HMActionSet) {
        fetchDataAndReloadMenu()
    }
    
    func home(_ home: HMHome, didRemove actionSet: HMActionSet) {
        fetchDataAndReloadMenu()
    }
}

// MARK: - HMAccessoryDelegate

extension HomeKitManager: HMAccessoryDelegate {
    func accessoryDidUpdateReachability(_ accessory: HMAccessory) {
        macOSDelegate?.setReachability(accessoryIdentifier: accessory.uniqueIdentifier, isReachable: accessory.isReachable)
    }
    
    func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        if let value = characteristic.value {
            macOSDelegate?.updateCharacteristic(identifier: characteristic.uniqueIdentifier, value: value)
        }
    }
}
