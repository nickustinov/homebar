//
//  HumidifierMenuItemTests.swift
//  macOSBridgeTests
//
//  Tests for HumidifierMenuItem including swing mode and water level
//

import XCTest
import AppKit
@testable import macOSBridge

final class HumidifierMenuItemTests: XCTestCase {

    // MARK: - Test helpers

    private func createTestServiceData(
        activeId: UUID? = UUID(),
        currentHumidifierDehumidifierStateId: UUID? = nil,
        targetHumidifierDehumidifierStateId: UUID? = nil,
        humidityId: UUID? = UUID(),
        humidifierThresholdId: UUID? = nil,
        dehumidifierThresholdId: UUID? = nil,
        swingModeId: UUID? = nil,
        waterLevelId: UUID? = nil
    ) -> ServiceData {
        ServiceData(
            uniqueIdentifier: UUID(),
            name: "Test Humidifier",
            serviceType: ServiceTypes.humidifierDehumidifier,
            accessoryName: "Test Accessory",
            roomIdentifier: nil,
            humidityId: humidityId,
            activeId: activeId,
            swingModeId: swingModeId,
            currentHumidifierDehumidifierStateId: currentHumidifierDehumidifierStateId,
            targetHumidifierDehumidifierStateId: targetHumidifierDehumidifierStateId,
            humidifierThresholdId: humidifierThresholdId,
            dehumidifierThresholdId: dehumidifierThresholdId,
            waterLevelId: waterLevelId
        )
    }

    // MARK: - Initialisation tests

    func testInitSetsServiceData() {
        let serviceData = createTestServiceData()
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertEqual(menuItem.serviceData.name, "Test Humidifier")
        XCTAssertEqual(menuItem.serviceData.serviceType, ServiceTypes.humidifierDehumidifier)
    }

    func testInitCreatesView() {
        let serviceData = createTestServiceData()
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Characteristic identifier tests

    func testCharacteristicIdentifiersContainsActiveId() {
        let activeId = UUID()
        let serviceData = createTestServiceData(activeId: activeId)
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(activeId))
    }

    func testCharacteristicIdentifiersContainsHumidityId() {
        let humidityId = UUID()
        let serviceData = createTestServiceData(humidityId: humidityId)
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(humidityId))
    }

    func testCharacteristicIdentifiersContainsTargetStateId() {
        let stateId = UUID()
        let serviceData = createTestServiceData(targetHumidifierDehumidifierStateId: stateId)
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(stateId))
    }

    func testCharacteristicIdentifiersContainsHumidifierThresholdId() {
        let thresholdId = UUID()
        let serviceData = createTestServiceData(humidifierThresholdId: thresholdId)
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(thresholdId))
    }

    func testCharacteristicIdentifiersContainsSwingModeId() {
        let swingId = UUID()
        let serviceData = createTestServiceData(swingModeId: swingId)
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(swingId))
    }

    func testCharacteristicIdentifiersContainsWaterLevelId() {
        let waterLevelId = UUID()
        let serviceData = createTestServiceData(waterLevelId: waterLevelId)
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(waterLevelId))
    }

    func testCharacteristicIdentifiersContainsAllWhenAllPresent() {
        let activeId = UUID()
        let humidityId = UUID()
        let currentStateId = UUID()
        let targetStateId = UUID()
        let humidifierThresholdId = UUID()
        let dehumidifierThresholdId = UUID()
        let swingId = UUID()
        let waterLevelId = UUID()

        let serviceData = createTestServiceData(
            activeId: activeId,
            currentHumidifierDehumidifierStateId: currentStateId,
            targetHumidifierDehumidifierStateId: targetStateId,
            humidityId: humidityId,
            humidifierThresholdId: humidifierThresholdId,
            dehumidifierThresholdId: dehumidifierThresholdId,
            swingModeId: swingId,
            waterLevelId: waterLevelId
        )
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(activeId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(humidityId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(currentStateId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(targetStateId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(humidifierThresholdId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(dehumidifierThresholdId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(swingId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(waterLevelId))
    }

    // MARK: - Value update tests

    func testUpdateActiveValue() {
        let activeId = UUID()
        let serviceData = createTestServiceData(activeId: activeId)
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: activeId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateHumidityValue() {
        let humidityId = UUID()
        let serviceData = createTestServiceData(humidityId: humidityId)
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: humidityId, value: 45.0)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateTargetStateValue() {
        let stateId = UUID()
        let serviceData = createTestServiceData(targetHumidifierDehumidifierStateId: stateId)
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        // 0 = auto, 1 = humidifier, 2 = dehumidifier
        menuItem.updateValue(for: stateId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateSwingModeValue() {
        let swingId = UUID()
        let serviceData = createTestServiceData(swingModeId: swingId)
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        // 0 = DISABLED, 1 = ENABLED
        menuItem.updateValue(for: swingId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateWaterLevelValue() {
        let waterLevelId = UUID()
        let serviceData = createTestServiceData(waterLevelId: waterLevelId)
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: waterLevelId, value: 65.0)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateValueIgnoresUnknownCharacteristicId() {
        let activeId = UUID()
        let unknownId = UUID()
        let serviceData = createTestServiceData(activeId: activeId)
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: unknownId, value: 50)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Protocol conformance tests

    func testConformsToCharacteristicUpdatable() {
        let serviceData = createTestServiceData()
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicUpdatable)
    }

    func testConformsToCharacteristicRefreshable() {
        let serviceData = createTestServiceData()
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicRefreshable)
    }

    func testConformsToLocalChangeNotifiable() {
        let serviceData = createTestServiceData()
        let menuItem = HumidifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is LocalChangeNotifiable)
    }
}
