//
//  AirPurifierMenuItemTests.swift
//  macOSBridgeTests
//
//  Tests for AirPurifierMenuItem including swing mode
//

import XCTest
import AppKit
@testable import macOSBridge

final class AirPurifierMenuItemTests: XCTestCase {

    // MARK: - Test helpers

    private func createTestServiceData(
        activeId: UUID? = UUID(),
        currentAirPurifierStateId: UUID? = nil,
        targetAirPurifierStateId: UUID? = nil,
        rotationSpeedId: UUID? = nil,
        swingModeId: UUID? = nil
    ) -> ServiceData {
        ServiceData(
            uniqueIdentifier: UUID(),
            name: "Test Air Purifier",
            serviceType: ServiceTypes.airPurifier,
            accessoryName: "Test Accessory",
            roomIdentifier: nil,
            activeId: activeId,
            rotationSpeedId: rotationSpeedId,
            swingModeId: swingModeId,
            currentAirPurifierStateId: currentAirPurifierStateId,
            targetAirPurifierStateId: targetAirPurifierStateId
        )
    }

    // MARK: - Initialisation tests

    func testInitSetsServiceData() {
        let serviceData = createTestServiceData()
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertEqual(menuItem.serviceData.name, "Test Air Purifier")
        XCTAssertEqual(menuItem.serviceData.serviceType, ServiceTypes.airPurifier)
    }

    func testInitCreatesView() {
        let serviceData = createTestServiceData()
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Characteristic identifier tests

    func testCharacteristicIdentifiersContainsActiveId() {
        let activeId = UUID()
        let serviceData = createTestServiceData(activeId: activeId)
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(activeId))
    }

    func testCharacteristicIdentifiersContainsCurrentStateId() {
        let stateId = UUID()
        let serviceData = createTestServiceData(currentAirPurifierStateId: stateId)
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(stateId))
    }

    func testCharacteristicIdentifiersContainsTargetStateId() {
        let stateId = UUID()
        let serviceData = createTestServiceData(targetAirPurifierStateId: stateId)
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(stateId))
    }

    func testCharacteristicIdentifiersContainsRotationSpeedId() {
        let speedId = UUID()
        let serviceData = createTestServiceData(rotationSpeedId: speedId)
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(speedId))
    }

    func testCharacteristicIdentifiersContainsSwingModeId() {
        let swingId = UUID()
        let serviceData = createTestServiceData(swingModeId: swingId)
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(swingId))
    }

    func testCharacteristicIdentifiersContainsAllWhenAllPresent() {
        let activeId = UUID()
        let currentStateId = UUID()
        let targetStateId = UUID()
        let speedId = UUID()
        let swingId = UUID()

        let serviceData = createTestServiceData(
            activeId: activeId,
            currentAirPurifierStateId: currentStateId,
            targetAirPurifierStateId: targetStateId,
            rotationSpeedId: speedId,
            swingModeId: swingId
        )
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(activeId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(currentStateId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(targetStateId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(speedId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(swingId))
    }

    // MARK: - Value update tests

    func testUpdateActiveValue() {
        let activeId = UUID()
        let serviceData = createTestServiceData(activeId: activeId)
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: activeId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateCurrentStateValue() {
        let stateId = UUID()
        let serviceData = createTestServiceData(currentAirPurifierStateId: stateId)
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        // 0=inactive, 1=idle, 2=purifying
        menuItem.updateValue(for: stateId, value: 2)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateTargetStateValue() {
        let stateId = UUID()
        let serviceData = createTestServiceData(targetAirPurifierStateId: stateId)
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        // 0=manual, 1=auto
        menuItem.updateValue(for: stateId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateRotationSpeedValue() {
        let speedId = UUID()
        let serviceData = createTestServiceData(rotationSpeedId: speedId)
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: speedId, value: 50.0)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateSwingModeValue() {
        let swingId = UUID()
        let serviceData = createTestServiceData(swingModeId: swingId)
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        // 0=DISABLED, 1=ENABLED
        menuItem.updateValue(for: swingId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateValueIgnoresUnknownCharacteristicId() {
        let activeId = UUID()
        let unknownId = UUID()
        let serviceData = createTestServiceData(activeId: activeId)
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: unknownId, value: 50)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Protocol conformance tests

    func testConformsToCharacteristicUpdatable() {
        let serviceData = createTestServiceData()
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicUpdatable)
    }

    func testConformsToCharacteristicRefreshable() {
        let serviceData = createTestServiceData()
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicRefreshable)
    }

    func testConformsToLocalChangeNotifiable() {
        let serviceData = createTestServiceData()
        let menuItem = AirPurifierMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is LocalChangeNotifiable)
    }
}
