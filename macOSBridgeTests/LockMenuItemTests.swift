//
//  LockMenuItemTests.swift
//  macOSBridgeTests
//
//  Tests for LockMenuItem
//

import XCTest
import AppKit
@testable import macOSBridge

final class LockMenuItemTests: XCTestCase {

    // MARK: - Test helpers

    private func createTestServiceData(
        lockCurrentStateId: UUID? = UUID(),
        lockTargetStateId: UUID? = nil
    ) -> ServiceData {
        ServiceData(
            uniqueIdentifier: UUID(),
            name: "Test Lock",
            serviceType: ServiceTypes.lock,
            accessoryName: "Test Accessory",
            roomIdentifier: nil,
            lockCurrentStateId: lockCurrentStateId,
            lockTargetStateId: lockTargetStateId
        )
    }

    // MARK: - Initialisation tests

    func testInitSetsServiceData() {
        let serviceData = createTestServiceData()
        let menuItem = LockMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertEqual(menuItem.serviceData.name, "Test Lock")
        XCTAssertEqual(menuItem.serviceData.serviceType, ServiceTypes.lock)
    }

    func testInitCreatesView() {
        let serviceData = createTestServiceData()
        let menuItem = LockMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Characteristic identifier tests

    func testCharacteristicIdentifiersContainsLockCurrentStateId() {
        let stateId = UUID()
        let serviceData = createTestServiceData(lockCurrentStateId: stateId)
        let menuItem = LockMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(stateId))
    }

    func testCharacteristicIdentifiersContainsLockTargetStateId() {
        let stateId = UUID()
        let serviceData = createTestServiceData(lockTargetStateId: stateId)
        let menuItem = LockMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(stateId))
    }

    func testCharacteristicIdentifiersContainsAllWhenAllPresent() {
        let currentId = UUID()
        let targetId = UUID()

        let serviceData = createTestServiceData(
            lockCurrentStateId: currentId,
            lockTargetStateId: targetId
        )
        let menuItem = LockMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(currentId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(targetId))
    }

    // MARK: - Value update tests

    func testUpdateLockCurrentStateValue() {
        let stateId = UUID()
        let serviceData = createTestServiceData(lockCurrentStateId: stateId)
        let menuItem = LockMenuItem(serviceData: serviceData, bridge: nil)

        // 0=unsecured, 1=secured, 2=jammed, 3=unknown
        menuItem.updateValue(for: stateId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateLockTargetStateValue() {
        let stateId = UUID()
        let serviceData = createTestServiceData(lockTargetStateId: stateId)
        let menuItem = LockMenuItem(serviceData: serviceData, bridge: nil)

        // 0=unsecured, 1=secured
        menuItem.updateValue(for: stateId, value: 0)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateValueIgnoresUnknownCharacteristicId() {
        let stateId = UUID()
        let unknownId = UUID()
        let serviceData = createTestServiceData(lockCurrentStateId: stateId)
        let menuItem = LockMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: unknownId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Protocol conformance tests

    func testConformsToCharacteristicUpdatable() {
        let serviceData = createTestServiceData()
        let menuItem = LockMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicUpdatable)
    }

    func testConformsToCharacteristicRefreshable() {
        let serviceData = createTestServiceData()
        let menuItem = LockMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicRefreshable)
    }

    func testConformsToLocalChangeNotifiable() {
        let serviceData = createTestServiceData()
        let menuItem = LockMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is LocalChangeNotifiable)
    }
}
