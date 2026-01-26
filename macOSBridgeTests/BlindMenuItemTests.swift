//
//  BlindMenuItemTests.swift
//  macOSBridgeTests
//
//  Tests for BlindMenuItem including tilt functionality
//

import XCTest
import AppKit
@testable import macOSBridge

final class BlindMenuItemTests: XCTestCase {

    // MARK: - Test helpers

    private func createTestServiceData(
        currentPositionId: UUID? = UUID(),
        targetPositionId: UUID? = UUID(),
        currentHorizontalTiltId: UUID? = nil,
        targetHorizontalTiltId: UUID? = nil,
        currentVerticalTiltId: UUID? = nil,
        targetVerticalTiltId: UUID? = nil
    ) -> ServiceData {
        ServiceData(
            uniqueIdentifier: UUID(),
            name: "Test Blind",
            serviceType: ServiceTypes.windowCovering,
            accessoryName: "Test Accessory",
            roomIdentifier: nil,
            currentPositionId: currentPositionId,
            targetPositionId: targetPositionId,
            currentHorizontalTiltId: currentHorizontalTiltId,
            targetHorizontalTiltId: targetHorizontalTiltId,
            currentVerticalTiltId: currentVerticalTiltId,
            targetVerticalTiltId: targetVerticalTiltId
        )
    }

    // MARK: - Initialisation tests

    func testInitSetsServiceData() {
        let serviceData = createTestServiceData()
        let menuItem = BlindMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertEqual(menuItem.serviceData.name, "Test Blind")
        XCTAssertEqual(menuItem.serviceData.serviceType, ServiceTypes.windowCovering)
    }

    func testInitCreatesView() {
        let serviceData = createTestServiceData()
        let menuItem = BlindMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Characteristic identifier tests

    func testCharacteristicIdentifiersContainsPositionId() {
        let positionId = UUID()
        let serviceData = createTestServiceData(currentPositionId: positionId)
        let menuItem = BlindMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(positionId))
    }

    func testCharacteristicIdentifiersContainsHorizontalTiltId() {
        let tiltId = UUID()
        let serviceData = createTestServiceData(
            currentHorizontalTiltId: tiltId,
            targetHorizontalTiltId: UUID()
        )
        let menuItem = BlindMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(tiltId))
    }

    func testCharacteristicIdentifiersContainsVerticalTiltId() {
        let tiltId = UUID()
        let serviceData = createTestServiceData(
            currentVerticalTiltId: tiltId,
            targetVerticalTiltId: UUID()
        )
        let menuItem = BlindMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(tiltId))
    }

    func testCharacteristicIdentifiersPrefersHorizontalOverVerticalTilt() {
        let horizTiltId = UUID()
        let vertTiltId = UUID()
        let serviceData = createTestServiceData(
            currentHorizontalTiltId: horizTiltId,
            targetHorizontalTiltId: UUID(),
            currentVerticalTiltId: vertTiltId,
            targetVerticalTiltId: UUID()
        )
        let menuItem = BlindMenuItem(serviceData: serviceData, bridge: nil)

        // Should contain horizontal tilt, not vertical
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(horizTiltId))
        XCTAssertFalse(menuItem.characteristicIdentifiers.contains(vertTiltId))
    }

    func testCharacteristicIdentifiersEmptyWhenNoPositionId() {
        let serviceData = createTestServiceData(currentPositionId: nil, targetPositionId: nil)
        let menuItem = BlindMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.isEmpty)
    }

    // MARK: - Value update tests

    func testUpdatePositionValue() {
        let positionId = UUID()
        let serviceData = createTestServiceData(currentPositionId: positionId)
        let menuItem = BlindMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: positionId, value: 75)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateTiltValue() {
        let tiltId = UUID()
        let serviceData = createTestServiceData(
            currentHorizontalTiltId: tiltId,
            targetHorizontalTiltId: UUID()
        )
        let menuItem = BlindMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: tiltId, value: 45)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateValueIgnoresUnknownCharacteristicId() {
        let positionId = UUID()
        let unknownId = UUID()
        let serviceData = createTestServiceData(currentPositionId: positionId)
        let menuItem = BlindMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: unknownId, value: 50)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Protocol conformance tests

    func testConformsToCharacteristicUpdatable() {
        let serviceData = createTestServiceData()
        let menuItem = BlindMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicUpdatable)
    }

    func testConformsToCharacteristicRefreshable() {
        let serviceData = createTestServiceData()
        let menuItem = BlindMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicRefreshable)
    }

    func testConformsToLocalChangeNotifiable() {
        let serviceData = createTestServiceData()
        let menuItem = BlindMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is LocalChangeNotifiable)
    }
}
