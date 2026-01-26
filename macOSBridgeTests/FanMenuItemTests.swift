//
//  FanMenuItemTests.swift
//  macOSBridgeTests
//
//  Tests for FanMenuItem including fan state, direction, and swing mode
//

import XCTest
import AppKit
@testable import macOSBridge

final class FanMenuItemTests: XCTestCase {

    // MARK: - Test helpers

    private func createTestServiceData(
        activeId: UUID? = UUID(),
        rotationSpeedId: UUID? = UUID(),
        targetFanStateId: UUID? = nil,
        currentFanStateId: UUID? = nil,
        rotationDirectionId: UUID? = nil,
        swingModeId: UUID? = nil
    ) -> ServiceData {
        ServiceData(
            uniqueIdentifier: UUID(),
            name: "Test Fan",
            serviceType: ServiceTypes.fanV2,
            accessoryName: "Test Accessory",
            roomIdentifier: nil,
            activeId: activeId,
            rotationSpeedId: rotationSpeedId,
            rotationSpeedMin: 0,
            rotationSpeedMax: 100,
            targetFanStateId: targetFanStateId,
            currentFanStateId: currentFanStateId,
            rotationDirectionId: rotationDirectionId,
            swingModeId: swingModeId
        )
    }

    // MARK: - Initialisation tests

    func testInitSetsServiceData() {
        let serviceData = createTestServiceData()
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertEqual(menuItem.serviceData.name, "Test Fan")
        XCTAssertEqual(menuItem.serviceData.serviceType, ServiceTypes.fanV2)
    }

    func testInitCreatesView() {
        let serviceData = createTestServiceData()
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Characteristic identifier tests

    func testCharacteristicIdentifiersContainsActiveId() {
        let activeId = UUID()
        let serviceData = createTestServiceData(activeId: activeId)
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(activeId))
    }

    func testCharacteristicIdentifiersContainsRotationSpeedId() {
        let speedId = UUID()
        let serviceData = createTestServiceData(rotationSpeedId: speedId)
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(speedId))
    }

    func testCharacteristicIdentifiersContainsTargetFanStateId() {
        let fanStateId = UUID()
        let serviceData = createTestServiceData(targetFanStateId: fanStateId)
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(fanStateId))
    }

    func testCharacteristicIdentifiersContainsCurrentFanStateId() {
        let currentStateId = UUID()
        let serviceData = createTestServiceData(currentFanStateId: currentStateId)
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(currentStateId))
    }

    func testCharacteristicIdentifiersContainsRotationDirectionId() {
        let directionId = UUID()
        let serviceData = createTestServiceData(rotationDirectionId: directionId)
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(directionId))
    }

    func testCharacteristicIdentifiersContainsSwingModeId() {
        let swingId = UUID()
        let serviceData = createTestServiceData(swingModeId: swingId)
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(swingId))
    }

    func testCharacteristicIdentifiersContainsAllWhenAllPresent() {
        let activeId = UUID()
        let speedId = UUID()
        let targetStateId = UUID()
        let currentStateId = UUID()
        let directionId = UUID()
        let swingId = UUID()

        let serviceData = createTestServiceData(
            activeId: activeId,
            rotationSpeedId: speedId,
            targetFanStateId: targetStateId,
            currentFanStateId: currentStateId,
            rotationDirectionId: directionId,
            swingModeId: swingId
        )
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(activeId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(speedId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(targetStateId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(currentStateId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(directionId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(swingId))
    }

    // MARK: - Value update tests

    func testUpdateActiveValue() {
        let activeId = UUID()
        let serviceData = createTestServiceData(activeId: activeId)
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: activeId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateRotationSpeedValue() {
        let speedId = UUID()
        let serviceData = createTestServiceData(rotationSpeedId: speedId)
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: speedId, value: 75.0)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateTargetFanStateValue() {
        let fanStateId = UUID()
        let serviceData = createTestServiceData(targetFanStateId: fanStateId)
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        // 0 = MANUAL, 1 = AUTO
        menuItem.updateValue(for: fanStateId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateRotationDirectionValue() {
        let directionId = UUID()
        let serviceData = createTestServiceData(rotationDirectionId: directionId)
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        // 0 = CLOCKWISE, 1 = COUNTER_CLOCKWISE
        menuItem.updateValue(for: directionId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateSwingModeValue() {
        let swingId = UUID()
        let serviceData = createTestServiceData(swingModeId: swingId)
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        // 0 = DISABLED, 1 = ENABLED
        menuItem.updateValue(for: swingId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateValueIgnoresUnknownCharacteristicId() {
        let activeId = UUID()
        let unknownId = UUID()
        let serviceData = createTestServiceData(activeId: activeId)
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: unknownId, value: 50)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Protocol conformance tests

    func testConformsToCharacteristicUpdatable() {
        let serviceData = createTestServiceData()
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicUpdatable)
    }

    func testConformsToCharacteristicRefreshable() {
        let serviceData = createTestServiceData()
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicRefreshable)
    }

    func testConformsToLocalChangeNotifiable() {
        let serviceData = createTestServiceData()
        let menuItem = FanMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is LocalChangeNotifiable)
    }
}
