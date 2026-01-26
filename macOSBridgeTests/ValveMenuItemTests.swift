//
//  ValveMenuItemTests.swift
//  macOSBridgeTests
//
//  Tests for ValveMenuItem
//

import XCTest
import AppKit
@testable import macOSBridge

final class ValveMenuItemTests: XCTestCase {

    // MARK: - Test helpers

    private func createTestServiceData(
        activeId: UUID? = UUID(),
        inUseId: UUID? = nil,
        valveTypeValue: Int? = nil
    ) -> ServiceData {
        ServiceData(
            uniqueIdentifier: UUID(),
            name: "Test Valve",
            serviceType: ServiceTypes.valve,
            accessoryName: "Test Accessory",
            roomIdentifier: nil,
            activeId: activeId,
            inUseId: inUseId,
            valveTypeValue: valveTypeValue
        )
    }

    // MARK: - Initialisation tests

    func testInitSetsServiceData() {
        let serviceData = createTestServiceData()
        let menuItem = ValveMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertEqual(menuItem.serviceData.name, "Test Valve")
        XCTAssertEqual(menuItem.serviceData.serviceType, ServiceTypes.valve)
    }

    func testInitCreatesView() {
        let serviceData = createTestServiceData()
        let menuItem = ValveMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Characteristic identifier tests

    func testCharacteristicIdentifiersContainsActiveId() {
        let activeId = UUID()
        let serviceData = createTestServiceData(activeId: activeId)
        let menuItem = ValveMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(activeId))
    }

    func testCharacteristicIdentifiersContainsInUseId() {
        let inUseId = UUID()
        let serviceData = createTestServiceData(inUseId: inUseId)
        let menuItem = ValveMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(inUseId))
    }

    func testCharacteristicIdentifiersContainsAllWhenAllPresent() {
        let activeId = UUID()
        let inUseId = UUID()

        let serviceData = createTestServiceData(
            activeId: activeId,
            inUseId: inUseId
        )
        let menuItem = ValveMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(activeId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(inUseId))
    }

    // MARK: - Value update tests

    func testUpdateActiveValue() {
        let activeId = UUID()
        let serviceData = createTestServiceData(activeId: activeId)
        let menuItem = ValveMenuItem(serviceData: serviceData, bridge: nil)

        // 0=inactive, 1=active
        menuItem.updateValue(for: activeId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateInUseValue() {
        let inUseId = UUID()
        let serviceData = createTestServiceData(inUseId: inUseId)
        let menuItem = ValveMenuItem(serviceData: serviceData, bridge: nil)

        // 0=not in use, 1=in use
        menuItem.updateValue(for: inUseId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateValueIgnoresUnknownCharacteristicId() {
        let activeId = UUID()
        let unknownId = UUID()
        let serviceData = createTestServiceData(activeId: activeId)
        let menuItem = ValveMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: unknownId, value: 1)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Protocol conformance tests

    func testConformsToCharacteristicUpdatable() {
        let serviceData = createTestServiceData()
        let menuItem = ValveMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicUpdatable)
    }

    func testConformsToCharacteristicRefreshable() {
        let serviceData = createTestServiceData()
        let menuItem = ValveMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicRefreshable)
    }

    func testConformsToLocalChangeNotifiable() {
        let serviceData = createTestServiceData()
        let menuItem = ValveMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is LocalChangeNotifiable)
    }
}
