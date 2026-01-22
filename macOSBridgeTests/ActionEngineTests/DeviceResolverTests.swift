//
//  DeviceResolverTests.swift
//  macOSBridgeTests
//
//  Tests for DeviceResolver
//

import XCTest
@testable import macOSBridge

final class DeviceResolverTests: XCTestCase {

    // MARK: - Test fixtures

    private var testMenuData: MenuData!
    private let bedroomRoomId = UUID()
    private let kitchenRoomId = UUID()
    private let officeRoomId = UUID()
    private let bedroomLightId = UUID()
    private let kitchenLightId = UUID()
    private let bedroomSwitchId = UUID()
    private let bedroomSpotlightsId = UUID()
    private let officeSpotlightsId = UUID()
    private let goodnightSceneId = UUID()
    private let morningSceneId = UUID()

    override func setUp() {
        super.setUp()
        testMenuData = createTestMenuData()
    }

    private func createTestMenuData() -> MenuData {
        let rooms = [
            RoomData(uniqueIdentifier: bedroomRoomId, name: "Bedroom"),
            RoomData(uniqueIdentifier: kitchenRoomId, name: "Kitchen"),
            RoomData(uniqueIdentifier: officeRoomId, name: "Office")
        ]

        let bedroomLight = ServiceData(
            uniqueIdentifier: bedroomLightId,
            name: "Bedroom Light",
            serviceType: ServiceTypes.lightbulb,
            accessoryName: "Bedroom Light",
            roomIdentifier: bedroomRoomId,
            powerStateId: UUID(),
            brightnessId: UUID()
        )

        let kitchenLight = ServiceData(
            uniqueIdentifier: kitchenLightId,
            name: "Kitchen Light",
            serviceType: ServiceTypes.lightbulb,
            accessoryName: "Kitchen Light",
            roomIdentifier: kitchenRoomId,
            powerStateId: UUID()
        )

        let bedroomSwitch = ServiceData(
            uniqueIdentifier: bedroomSwitchId,
            name: "Bedroom Switch",
            serviceType: ServiceTypes.switch,
            accessoryName: "Bedroom Switch",
            roomIdentifier: bedroomRoomId,
            powerStateId: UUID()
        )

        let bedroomSpotlights = ServiceData(
            uniqueIdentifier: bedroomSpotlightsId,
            name: "Spotlights",
            serviceType: ServiceTypes.lightbulb,
            accessoryName: "Spotlights",
            roomIdentifier: bedroomRoomId,
            powerStateId: UUID(),
            brightnessId: UUID()
        )

        let officeSpotlights = ServiceData(
            uniqueIdentifier: officeSpotlightsId,
            name: "Spotlights",
            serviceType: ServiceTypes.lightbulb,
            accessoryName: "Spotlights",
            roomIdentifier: officeRoomId,
            powerStateId: UUID(),
            brightnessId: UUID()
        )

        let accessories = [
            AccessoryData(
                uniqueIdentifier: UUID(),
                name: "Bedroom Light",
                roomIdentifier: bedroomRoomId,
                services: [bedroomLight],
                isReachable: true
            ),
            AccessoryData(
                uniqueIdentifier: UUID(),
                name: "Kitchen Light",
                roomIdentifier: kitchenRoomId,
                services: [kitchenLight],
                isReachable: true
            ),
            AccessoryData(
                uniqueIdentifier: UUID(),
                name: "Bedroom Switch",
                roomIdentifier: bedroomRoomId,
                services: [bedroomSwitch],
                isReachable: true
            ),
            AccessoryData(
                uniqueIdentifier: UUID(),
                name: "Spotlights",
                roomIdentifier: bedroomRoomId,
                services: [bedroomSpotlights],
                isReachable: true
            ),
            AccessoryData(
                uniqueIdentifier: UUID(),
                name: "Spotlights",
                roomIdentifier: officeRoomId,
                services: [officeSpotlights],
                isReachable: true
            )
        ]

        let scenes = [
            SceneData(uniqueIdentifier: goodnightSceneId, name: "Goodnight"),
            SceneData(uniqueIdentifier: morningSceneId, name: "Good Morning")
        ]

        return MenuData(
            homes: [HomeData(uniqueIdentifier: UUID(), name: "Home", isPrimary: true)],
            rooms: rooms,
            accessories: accessories,
            scenes: scenes,
            selectedHomeId: nil
        )
    }

    // MARK: - UUID resolution tests

    func testResolveByExactUUID() {
        let result = DeviceResolver.resolve(bedroomLightId.uuidString, in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].uniqueIdentifier, bedroomLightId.uuidString)
        } else {
            XCTFail("Expected services result")
        }
    }

    func testResolveByUUIDCaseInsensitive() {
        let result = DeviceResolver.resolve(bedroomLightId.uuidString.lowercased(), in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].uniqueIdentifier, bedroomLightId.uuidString)
        } else {
            XCTFail("Expected services result")
        }
    }

    func testResolveSceneByUUID() {
        let result = DeviceResolver.resolve(goodnightSceneId.uuidString, in: testMenuData)

        if case .scene(let scene) = result {
            XCTAssertEqual(scene.uniqueIdentifier, goodnightSceneId.uuidString)
        } else {
            XCTFail("Expected scene result")
        }
    }

    // MARK: - Name resolution tests

    func testResolveByExactName() {
        let result = DeviceResolver.resolve("Bedroom Light", in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].name, "Bedroom Light")
        } else {
            XCTFail("Expected services result")
        }
    }

    func testResolveByNameCaseInsensitive() {
        let result = DeviceResolver.resolve("bedroom light", in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].name, "Bedroom Light")
        } else {
            XCTFail("Expected services result")
        }
    }

    func testResolveByPartialName() {
        let result = DeviceResolver.resolve("Kitchen", in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].name, "Kitchen Light")
        } else {
            XCTFail("Expected services result, got \(result)")
        }
    }

    func testResolveAmbiguousNameReturnsAmbiguous() {
        // "Light" matches "Bedroom Light", "Kitchen Light", and both Spotlights (lightbulbs)
        let result = DeviceResolver.resolve("Light", in: testMenuData)

        if case .ambiguous(let services) = result {
            XCTAssertEqual(services.count, 4)
        } else {
            XCTFail("Expected ambiguous result, got \(result)")
        }
    }

    // MARK: - Type.room format tests

    func testResolveTypeDotRoom() {
        let result = DeviceResolver.resolve("light.bedroom", in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 2) // Bedroom Light + Bedroom Spotlights
        } else {
            XCTFail("Expected services result")
        }
    }

    func testResolveTypeDotRoomCaseInsensitive() {
        let result = DeviceResolver.resolve("LIGHT.BEDROOM", in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 2) // Bedroom Light + Bedroom Spotlights
        } else {
            XCTFail("Expected services result")
        }
    }

    func testResolveTypeDotRoomWithAlias() {
        let result = DeviceResolver.resolve("lightbulb.bedroom", in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 2) // Bedroom Light + Bedroom Spotlights
        } else {
            XCTFail("Expected services result")
        }
    }

    func testResolveTypeDotRoomNotFound() {
        let result = DeviceResolver.resolve("light.bathroom", in: testMenuData)

        if case .notFound = result {
            // Expected
        } else {
            XCTFail("Expected notFound result")
        }
    }

    // MARK: - Wildcard tests

    func testResolveAllLights() {
        let result = DeviceResolver.resolve("all lights", in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 4) // Bedroom Light, Kitchen Light, Bedroom Spotlights, Office Spotlights
            XCTAssertTrue(services.allSatisfy { $0.serviceType == ServiceTypes.lightbulb })
        } else {
            XCTFail("Expected services result")
        }
    }

    func testResolveAllSwitches() {
        let result = DeviceResolver.resolve("all switches", in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].name, "Bedroom Switch")
        } else {
            XCTFail("Expected services result")
        }
    }

    func testResolveRoomWildcard() {
        let result = DeviceResolver.resolve("bedroom.*", in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 3) // Light, Switch, and Spotlights
            XCTAssertTrue(services.allSatisfy { $0.roomIdentifier == bedroomRoomId.uuidString })
        } else {
            XCTFail("Expected services result")
        }
    }

    func testResolveTypeWildcard() {
        let result = DeviceResolver.resolve("*.light", in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 4) // All 4 lightbulbs
        } else {
            XCTFail("Expected services result")
        }
    }

    // MARK: - Scene resolution tests

    func testResolveSceneByPrefix() {
        let result = DeviceResolver.resolve("scene.goodnight", in: testMenuData)

        if case .scene(let scene) = result {
            XCTAssertEqual(scene.name, "Goodnight")
        } else {
            XCTFail("Expected scene result")
        }
    }

    func testResolveSceneByExactName() {
        let result = DeviceResolver.resolve("Goodnight", in: testMenuData)

        if case .scene(let scene) = result {
            XCTAssertEqual(scene.name, "Goodnight")
        } else {
            XCTFail("Expected scene result")
        }
    }

    func testResolveSceneWithSpaces() {
        let result = DeviceResolver.resolve("scene.good morning", in: testMenuData)

        if case .scene(let scene) = result {
            XCTAssertEqual(scene.name, "Good Morning")
        } else {
            XCTFail("Expected scene result, got \(result)")
        }
    }

    // MARK: - Not found tests

    func testResolveNotFoundReturnsNotFound() {
        let result = DeviceResolver.resolve("nonexistent device", in: testMenuData)

        if case .notFound(let query) = result {
            XCTAssertEqual(query, "nonexistent device")
        } else {
            XCTFail("Expected notFound result")
        }
    }

    func testResolveEmptyStringReturnsNotFound() {
        let result = DeviceResolver.resolve("", in: testMenuData)

        if case .notFound = result {
            // Expected
        } else {
            XCTFail("Expected notFound result")
        }
    }

    func testResolveWhitespaceOnlyReturnsNotFound() {
        let result = DeviceResolver.resolve("   ", in: testMenuData)

        if case .notFound = result {
            // Expected
        } else {
            XCTFail("Expected notFound result")
        }
    }

    // MARK: - Room/device name resolution tests

    func testResolveRoomSlashDevice() {
        let result = DeviceResolver.resolve("Office/Spotlights", in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].uniqueIdentifier, officeSpotlightsId.uuidString)
        } else {
            XCTFail("Expected services result, got \(result)")
        }
    }

    func testResolveRoomSlashDeviceCaseInsensitive() {
        let result = DeviceResolver.resolve("office/spotlights", in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].uniqueIdentifier, officeSpotlightsId.uuidString)
        } else {
            XCTFail("Expected services result, got \(result)")
        }
    }

    func testResolveRoomSlashDeviceBedroomSpotlights() {
        let result = DeviceResolver.resolve("Bedroom/Spotlights", in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].uniqueIdentifier, bedroomSpotlightsId.uuidString)
        } else {
            XCTFail("Expected services result, got \(result)")
        }
    }

    func testResolveRoomSpaceDevice() {
        let result = DeviceResolver.resolve("Office Spotlights", in: testMenuData)

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].uniqueIdentifier, officeSpotlightsId.uuidString)
        } else {
            XCTFail("Expected services result, got \(result)")
        }
    }

    func testResolveAmbiguousDeviceNameReturnsAmbiguous() {
        // "Spotlights" exists in both Bedroom and Office
        let result = DeviceResolver.resolve("Spotlights", in: testMenuData)

        if case .ambiguous(let services) = result {
            XCTAssertEqual(services.count, 2)
        } else {
            XCTFail("Expected ambiguous result, got \(result)")
        }
    }

    func testResolveRoomSlashDeviceNotFoundRoom() {
        let result = DeviceResolver.resolve("Bathroom/Spotlights", in: testMenuData)

        // Should fall through to other resolution strategies
        if case .notFound = result {
            // Expected - no bathroom room exists
        } else if case .ambiguous = result {
            // Also acceptable - might match "Spotlights" partially
        } else {
            XCTFail("Expected notFound or ambiguous result, got \(result)")
        }
    }

    func testResolveRoomSlashDeviceNotFoundDevice() {
        let result = DeviceResolver.resolve("Office/Lamp", in: testMenuData)

        if case .notFound = result {
            // Expected
        } else {
            XCTFail("Expected notFound result, got \(result)")
        }
    }
}
