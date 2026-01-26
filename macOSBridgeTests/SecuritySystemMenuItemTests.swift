//
//  SecuritySystemMenuItemTests.swift
//  macOSBridgeTests
//
//  Tests for SecuritySystemMenuItem
//

import XCTest
import AppKit
@testable import macOSBridge

final class SecuritySystemMenuItemTests: XCTestCase {

    // MARK: - Test helpers

    private func createTestServiceData(
        securitySystemCurrentStateId: UUID? = UUID(),
        securitySystemTargetStateId: UUID? = nil
    ) -> ServiceData {
        ServiceData(
            uniqueIdentifier: UUID(),
            name: "Test Security System",
            serviceType: ServiceTypes.securitySystem,
            accessoryName: "Test Accessory",
            roomIdentifier: nil,
            securitySystemCurrentStateId: securitySystemCurrentStateId,
            securitySystemTargetStateId: securitySystemTargetStateId
        )
    }

    // MARK: - Initialisation tests

    func testInitSetsServiceData() {
        let serviceData = createTestServiceData()
        let menuItem = SecuritySystemMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertEqual(menuItem.serviceData.name, "Test Security System")
        XCTAssertEqual(menuItem.serviceData.serviceType, ServiceTypes.securitySystem)
    }

    func testInitCreatesView() {
        let serviceData = createTestServiceData()
        let menuItem = SecuritySystemMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Characteristic identifier tests

    func testCharacteristicIdentifiersContainsCurrentStateId() {
        let stateId = UUID()
        let serviceData = createTestServiceData(securitySystemCurrentStateId: stateId)
        let menuItem = SecuritySystemMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(stateId))
    }

    func testCharacteristicIdentifiersContainsTargetStateId() {
        let stateId = UUID()
        let serviceData = createTestServiceData(securitySystemTargetStateId: stateId)
        let menuItem = SecuritySystemMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(stateId))
    }

    func testCharacteristicIdentifiersContainsAllWhenAllPresent() {
        let currentId = UUID()
        let targetId = UUID()

        let serviceData = createTestServiceData(
            securitySystemCurrentStateId: currentId,
            securitySystemTargetStateId: targetId
        )
        let menuItem = SecuritySystemMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(currentId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(targetId))
    }

    // MARK: - Value update tests

    func testUpdateCurrentStateValue() {
        let stateId = UUID()
        let serviceData = createTestServiceData(securitySystemCurrentStateId: stateId)
        let menuItem = SecuritySystemMenuItem(serviceData: serviceData, bridge: nil)

        // 0=stayArm, 1=awayArm, 2=nightArm, 3=disarmed, 4=triggered
        menuItem.updateValue(for: stateId, value: 3)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateTargetStateValue() {
        let stateId = UUID()
        let serviceData = createTestServiceData(securitySystemTargetStateId: stateId)
        let menuItem = SecuritySystemMenuItem(serviceData: serviceData, bridge: nil)

        // 0=stayArm, 1=awayArm, 2=nightArm, 3=disarm
        menuItem.updateValue(for: stateId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateValueIgnoresUnknownCharacteristicId() {
        let stateId = UUID()
        let unknownId = UUID()
        let serviceData = createTestServiceData(securitySystemCurrentStateId: stateId)
        let menuItem = SecuritySystemMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: unknownId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Protocol conformance tests

    func testConformsToCharacteristicUpdatable() {
        let serviceData = createTestServiceData()
        let menuItem = SecuritySystemMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicUpdatable)
    }

    func testConformsToCharacteristicRefreshable() {
        let serviceData = createTestServiceData()
        let menuItem = SecuritySystemMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicRefreshable)
    }

    func testConformsToLocalChangeNotifiable() {
        let serviceData = createTestServiceData()
        let menuItem = SecuritySystemMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is LocalChangeNotifiable)
    }
}
