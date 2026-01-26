//
//  LightMenuItemTests.swift
//  macOSBridgeTests
//
//  Tests for LightMenuItem including RGB and color temperature
//

import XCTest
import AppKit
@testable import macOSBridge

final class LightMenuItemTests: XCTestCase {

    // MARK: - Test helpers

    private func createTestServiceData(
        powerStateId: UUID? = UUID(),
        brightnessId: UUID? = nil,
        hueId: UUID? = nil,
        saturationId: UUID? = nil,
        colorTemperatureId: UUID? = nil,
        colorTemperatureMin: Double? = nil,
        colorTemperatureMax: Double? = nil
    ) -> ServiceData {
        ServiceData(
            uniqueIdentifier: UUID(),
            name: "Test Light",
            serviceType: ServiceTypes.lightbulb,
            accessoryName: "Test Accessory",
            roomIdentifier: nil,
            powerStateId: powerStateId,
            brightnessId: brightnessId,
            hueId: hueId,
            saturationId: saturationId,
            colorTemperatureId: colorTemperatureId,
            colorTemperatureMin: colorTemperatureMin,
            colorTemperatureMax: colorTemperatureMax
        )
    }

    // MARK: - Initialisation tests

    func testInitSetsServiceData() {
        let serviceData = createTestServiceData()
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertEqual(menuItem.serviceData.name, "Test Light")
        XCTAssertEqual(menuItem.serviceData.serviceType, ServiceTypes.lightbulb)
    }

    func testInitCreatesView() {
        let serviceData = createTestServiceData()
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Characteristic identifier tests

    func testCharacteristicIdentifiersContainsPowerStateId() {
        let powerId = UUID()
        let serviceData = createTestServiceData(powerStateId: powerId)
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(powerId))
    }

    func testCharacteristicIdentifiersContainsBrightnessId() {
        let brightnessId = UUID()
        let serviceData = createTestServiceData(brightnessId: brightnessId)
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(brightnessId))
    }

    func testCharacteristicIdentifiersContainsHueId() {
        let hueId = UUID()
        let serviceData = createTestServiceData(hueId: hueId)
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(hueId))
    }

    func testCharacteristicIdentifiersContainsSaturationId() {
        let satId = UUID()
        let serviceData = createTestServiceData(saturationId: satId)
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(satId))
    }

    func testCharacteristicIdentifiersContainsColorTemperatureId() {
        let tempId = UUID()
        let serviceData = createTestServiceData(colorTemperatureId: tempId)
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(tempId))
    }

    func testCharacteristicIdentifiersContainsAllWhenAllPresent() {
        let powerId = UUID()
        let brightnessId = UUID()
        let hueId = UUID()
        let satId = UUID()
        let tempId = UUID()

        let serviceData = createTestServiceData(
            powerStateId: powerId,
            brightnessId: brightnessId,
            hueId: hueId,
            saturationId: satId,
            colorTemperatureId: tempId
        )
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(powerId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(brightnessId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(hueId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(satId))
        XCTAssertTrue(menuItem.characteristicIdentifiers.contains(tempId))
    }

    // MARK: - Value update tests

    func testUpdatePowerValue() {
        let powerId = UUID()
        let serviceData = createTestServiceData(powerStateId: powerId)
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: powerId, value: true)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateBrightnessValue() {
        let brightnessId = UUID()
        let serviceData = createTestServiceData(brightnessId: brightnessId)
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: brightnessId, value: 75.0)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateHueValue() {
        let hueId = UUID()
        let serviceData = createTestServiceData(hueId: hueId)
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: hueId, value: 180.0)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateSaturationValue() {
        let satId = UUID()
        let serviceData = createTestServiceData(saturationId: satId)
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: satId, value: 80.0)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateColorTemperatureValue() {
        let tempId = UUID()
        let serviceData = createTestServiceData(colorTemperatureId: tempId, colorTemperatureMin: 153, colorTemperatureMax: 500)
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: tempId, value: 300.0)

        XCTAssertNotNil(menuItem.view)
    }

    func testUpdateValueIgnoresUnknownCharacteristicId() {
        let powerId = UUID()
        let unknownId = UUID()
        let serviceData = createTestServiceData(powerStateId: powerId)
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        menuItem.updateValue(for: unknownId, value: 50)

        XCTAssertNotNil(menuItem.view)
    }

    // MARK: - Protocol conformance tests

    func testConformsToCharacteristicUpdatable() {
        let serviceData = createTestServiceData()
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicUpdatable)
    }

    func testConformsToCharacteristicRefreshable() {
        let serviceData = createTestServiceData()
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is CharacteristicRefreshable)
    }

    func testConformsToLocalChangeNotifiable() {
        let serviceData = createTestServiceData()
        let menuItem = LightMenuItem(serviceData: serviceData, bridge: nil)

        XCTAssertTrue(menuItem is LocalChangeNotifiable)
    }
}
