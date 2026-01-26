//
//  ThermostatMenuItemTests.swift
//  macOSBridgeTests
//
//  Tests for ThermostatMenuItem including Auto mode thresholds
//

import XCTest
import AppKit
@testable import macOSBridge

final class ThermostatMenuItemTests: XCTestCase {

    // MARK: - Test helpers

    private func createTestServiceData(
        currentTemperatureId: UUID? = UUID(),
        targetTemperatureId: UUID? = UUID(),
        heatingCoolingStateId: UUID? = nil,
        targetHeatingCoolingStateId: UUID? = nil,
        coolingThresholdTemperatureId: UUID? = nil,
        heatingThresholdTemperatureId: UUID? = nil
    ) -> ServiceData {
        ServiceData(
            uniqueIdentifier: UUID(),
            name: "Test Thermostat",
            serviceType: ServiceTypes.thermostat,
            accessoryName: "Test Accessory",
            roomIdentifier: nil,
            currentTemperatureId: currentTemperatureId,
            targetTemperatureId: targetTemperatureId,
            heatingCoolingStateId: heatingCoolingStateId,
            targetHeatingCoolingStateId: targetHeatingCoolingStateId,
            coolingThresholdTemperatureId: coolingThresholdTemperatureId,
            heatingThresholdTemperatureId: heatingThresholdTemperatureId
        )
    }

    // MARK: - Initialisation tests

    func testInitSetsServiceData() {
        let serviceData = createTestServiceData()
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertEqual(menuItem.serviceData.name, "Test Thermostat")
        XCTAssertEqual(menuItem.serviceData.serviceType, ServiceTypes.thermostat)
    }

    func testInitCreatesView() {
        let serviceData = createTestServiceData()
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Characteristic identifier tests

    func testCharacteristicIdentifiersContainsCurrentTemperatureId() {
        let tempId = UUID()
        let serviceData = createTestServiceData(currentTemperatureId: tempId)
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(tempId))
    }

    func testCharacteristicIdentifiersContainsTargetTemperatureId() {
        let tempId = UUID()
        let serviceData = createTestServiceData(targetTemperatureId: tempId)
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(tempId))
    }

    func testCharacteristicIdentifiersContainsHeatingCoolingStateId() {
        let stateId = UUID()
        let serviceData = createTestServiceData(heatingCoolingStateId: stateId)
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(stateId))
    }

    func testCharacteristicIdentifiersContainsTargetHeatingCoolingStateId() {
        let stateId = UUID()
        let serviceData = createTestServiceData(targetHeatingCoolingStateId: stateId)
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(stateId))
    }

    func testCharacteristicIdentifiersContainsCoolingThresholdId() {
        let thresholdId = UUID()
        let serviceData = createTestServiceData(coolingThresholdTemperatureId: thresholdId)
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(thresholdId))
    }

    func testCharacteristicIdentifiersContainsHeatingThresholdId() {
        let thresholdId = UUID()
        let serviceData = createTestServiceData(heatingThresholdTemperatureId: thresholdId)
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(thresholdId))
    }

    func testCharacteristicIdentifiersContainsAllWhenAllPresent() {
        let currentTempId = UUID()
        let targetTempId = UUID()
        let currentStateId = UUID()
        let targetStateId = UUID()
        let coolingId = UUID()
        let heatingId = UUID()

        let serviceData = createTestServiceData(
            currentTemperatureId: currentTempId,
            targetTemperatureId: targetTempId,
            heatingCoolingStateId: currentStateId,
            targetHeatingCoolingStateId: targetStateId,
            coolingThresholdTemperatureId: coolingId,
            heatingThresholdTemperatureId: heatingId
        )
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(currentTempId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(targetTempId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(currentStateId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(targetStateId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(coolingId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(heatingId))
    }

    // MARK: - Value update tests

    func testUpdateCurrentTemperatureValue() {
        let tempId = UUID()
        let serviceData = createTestServiceData(currentTemperatureId: tempId)
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: tempId, value: 21.5)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateTargetTemperatureValue() {
        let tempId = UUID()
        let serviceData = createTestServiceData(targetTemperatureId: tempId)
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: tempId, value: 22.0)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateHeatingCoolingStateValue() {
        let stateId = UUID()
        let serviceData = createTestServiceData(heatingCoolingStateId: stateId)
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        // 0=off, 1=heating, 2=cooling
        menuItem.updateValue(for: stateId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateTargetHeatingCoolingStateValue() {
        let stateId = UUID()
        let serviceData = createTestServiceData(targetHeatingCoolingStateId: stateId)
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        // 0=off, 1=heat, 2=cool, 3=auto
        menuItem.updateValue(for: stateId, value: 3)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateCoolingThresholdValue() {
        let thresholdId = UUID()
        let serviceData = createTestServiceData(coolingThresholdTemperatureId: thresholdId)
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: thresholdId, value: 24.0)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateHeatingThresholdValue() {
        let thresholdId = UUID()
        let serviceData = createTestServiceData(heatingThresholdTemperatureId: thresholdId)
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: thresholdId, value: 18.0)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateValueIgnoresUnknownCharacteristicId() {
        let tempId = UUID()
        let unknownId = UUID()
        let serviceData = createTestServiceData(currentTemperatureId: tempId)
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: unknownId, value: 50)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Protocol conformance tests

    func testConformsToCharacteristicUpdatable() {
        let serviceData = createTestServiceData()
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicUpdatable)
    }

    func testConformsToCharacteristicRefreshable() {
        let serviceData = createTestServiceData()
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicRefreshable)
    }

    func testConformsToLocalChangeNotifiable() {
        let serviceData = createTestServiceData()
        let menuItem = ThermostatMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is LocalChangeNotifiable)
    }
}
