//
//  GarageDoorMenuItemTests.swift
//  macOSBridgeTests
//
//  Tests for GarageDoorMenuItem
//

import XCTest
import AppKit
@testable import macOSBridge

final class GarageDoorMenuItemTests: XCTestCase {

    // MARK: - Test helpers

    private func createTestServiceData(
        currentDoorStateId: UUID? = UUID(),
        targetDoorStateId: UUID? = nil,
        obstructionDetectedId: UUID? = nil
    ) -> ServiceData {
        ServiceData(
            uniqueIdentifier: UUID(),
            name: "Test Garage Door",
            serviceType: ServiceTypes.garageDoorOpener,
            accessoryName: "Test Accessory",
            roomIdentifier: nil,
            currentDoorStateId: currentDoorStateId,
            targetDoorStateId: targetDoorStateId,
            obstructionDetectedId: obstructionDetectedId
        )
    }

    // MARK: - Initialisation tests

    func testInitSetsServiceData() {
        let serviceData = createTestServiceData()
        let menuItem = GarageDoorMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertEqual(menuItem.serviceData.name, "Test Garage Door")
        XCTAssertEqual(menuItem.serviceData.serviceType, ServiceTypes.garageDoorOpener)
    }

    func testInitCreatesView() {
        let serviceData = createTestServiceData()
        let menuItem = GarageDoorMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Characteristic identifier tests

    func testCharacteristicIdentifiersContainsCurrentDoorStateId() {
        let stateId = UUID()
        let serviceData = createTestServiceData(currentDoorStateId: stateId)
        let menuItem = GarageDoorMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(stateId))
    }

    func testCharacteristicIdentifiersContainsTargetDoorStateId() {
        let stateId = UUID()
        let serviceData = createTestServiceData(targetDoorStateId: stateId)
        let menuItem = GarageDoorMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(stateId))
    }

    func testCharacteristicIdentifiersContainsObstructionDetectedId() {
        let obstructionId = UUID()
        let serviceData = createTestServiceData(obstructionDetectedId: obstructionId)
        let menuItem = GarageDoorMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(obstructionId))
    }

    func testCharacteristicIdentifiersContainsAllWhenAllPresent() {
        let currentId = UUID()
        let targetId = UUID()
        let obstructionId = UUID()

        let serviceData = createTestServiceData(
            currentDoorStateId: currentId,
            targetDoorStateId: targetId,
            obstructionDetectedId: obstructionId
        )
        let menuItem = GarageDoorMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(currentId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(targetId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(obstructionId))
    }

    // MARK: - Value update tests

    func testUpdateCurrentDoorStateValue() {
        let stateId = UUID()
        let serviceData = createTestServiceData(currentDoorStateId: stateId)
        let menuItem = GarageDoorMenuItem(serviceData: serviceData, bridge: nil)

        // 0=open, 1=closed, 2=opening, 3=closing, 4=stopped
        menuItem.updateValue(for: stateId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateTargetDoorStateValue() {
        let stateId = UUID()
        let serviceData = createTestServiceData(targetDoorStateId: stateId)
        let menuItem = GarageDoorMenuItem(serviceData: serviceData, bridge: nil)

        // 0=open, 1=closed
        menuItem.updateValue(for: stateId, value: 0)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateObstructionDetectedValue() {
        let obstructionId = UUID()
        let serviceData = createTestServiceData(obstructionDetectedId: obstructionId)
        let menuItem = GarageDoorMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: obstructionId, value: true)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateValueIgnoresUnknownCharacteristicId() {
        let stateId = UUID()
        let unknownId = UUID()
        let serviceData = createTestServiceData(currentDoorStateId: stateId)
        let menuItem = GarageDoorMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: unknownId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Protocol conformance tests

    func testConformsToCharacteristicUpdatable() {
        let serviceData = createTestServiceData()
        let menuItem = GarageDoorMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicUpdatable)
    }

    func testConformsToCharacteristicRefreshable() {
        let serviceData = createTestServiceData()
        let menuItem = GarageDoorMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicRefreshable)
    }

    func testConformsToLocalChangeNotifiable() {
        let serviceData = createTestServiceData()
        let menuItem = GarageDoorMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is LocalChangeNotifiable)
    }
}
