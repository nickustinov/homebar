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

    // MARK: - Group resolution tests

    func testResolveGroupByPrefix() {
        let group = DeviceGroup(
            id: UUID().uuidString,
            name: "All Lights",
            icon: "lightbulb",
            deviceIds: [bedroomLightId.uuidString, kitchenLightId.uuidString]
        )

        let result = DeviceResolver.resolve("group.All Lights", in: testMenuData, groups: [group])

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 2)
        } else {
            XCTFail("Expected services result, got \(result)")
        }
    }

    func testResolveGroupByExactName() {
        let group = DeviceGroup(
            id: UUID().uuidString,
            name: "Office Lights",
            icon: "lightbulb",
            deviceIds: [officeSpotlightsId.uuidString]
        )

        let result = DeviceResolver.resolve("Office Lights", in: testMenuData, groups: [group])

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].uniqueIdentifier, officeSpotlightsId.uuidString)
        } else {
            XCTFail("Expected services result, got \(result)")
        }
    }

    func testResolveGroupNotFound() {
        let result = DeviceResolver.resolve("group.Nonexistent", in: testMenuData, groups: [])

        if case .notFound = result {
            // Expected
        } else {
            XCTFail("Expected notFound result, got \(result)")
        }
    }

    func testResolveGroupWithNoMatchingDevices() {
        let group = DeviceGroup(
            id: UUID().uuidString,
            name: "Empty Group",
            icon: "lightbulb",
            deviceIds: [UUID().uuidString] // Non-existent device
        )

        let result = DeviceResolver.resolve("group.Empty Group", in: testMenuData, groups: [group])

        if case .notFound = result {
            // Expected - group exists but has no resolvable devices
        } else {
            XCTFail("Expected notFound result, got \(result)")
        }
    }

    // MARK: - Room-scoped group resolution tests

    func testResolveRoomScopedGroupByPrefix() {
        // Create a room-scoped group for Office
        let officeGroup = DeviceGroup(
            id: UUID().uuidString,
            name: "All Lights",
            icon: "lightbulb",
            deviceIds: [officeSpotlightsId.uuidString],
            roomId: officeRoomId.uuidString
        )

        let result = DeviceResolver.resolve("Office/group.All Lights", in: testMenuData, groups: [officeGroup])

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].uniqueIdentifier, officeSpotlightsId.uuidString)
        } else {
            XCTFail("Expected services result, got \(result)")
        }
    }

    func testResolveRoomScopedGroupCaseInsensitive() {
        let officeGroup = DeviceGroup(
            id: UUID().uuidString,
            name: "All Lights",
            icon: "lightbulb",
            deviceIds: [officeSpotlightsId.uuidString],
            roomId: officeRoomId.uuidString
        )

        let result = DeviceResolver.resolve("office/group.all lights", in: testMenuData, groups: [officeGroup])

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].uniqueIdentifier, officeSpotlightsId.uuidString)
        } else {
            XCTFail("Expected services result, got \(result)")
        }
    }

    func testResolveRoomScopedGroupPrefersRoomScoped() {
        // Create both a room-scoped and global group with same name
        let officeGroup = DeviceGroup(
            id: UUID().uuidString,
            name: "All Lights",
            icon: "lightbulb",
            deviceIds: [officeSpotlightsId.uuidString],
            roomId: officeRoomId.uuidString
        )
        let globalGroup = DeviceGroup(
            id: UUID().uuidString,
            name: "All Lights",
            icon: "lightbulb",
            deviceIds: [bedroomLightId.uuidString, kitchenLightId.uuidString],
            roomId: nil
        )

        // When requesting Office/group.All Lights, should get the Office-scoped group
        let result = DeviceResolver.resolve("Office/group.All Lights", in: testMenuData, groups: [officeGroup, globalGroup])

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].uniqueIdentifier, officeSpotlightsId.uuidString)
        } else {
            XCTFail("Expected services result, got \(result)")
        }
    }

    func testResolveRoomScopedGroupFallsBackToGlobal() {
        // Only create a global group (no room-scoped group for Office)
        let globalGroup = DeviceGroup(
            id: UUID().uuidString,
            name: "All Lights",
            icon: "lightbulb",
            deviceIds: [bedroomLightId.uuidString, kitchenLightId.uuidString],
            roomId: nil
        )

        // When requesting Office/group.All Lights but no Office-scoped group exists,
        // should fall back to global group
        let result = DeviceResolver.resolve("Office/group.All Lights", in: testMenuData, groups: [globalGroup])

        if case .services(let services) = result {
            XCTAssertEqual(services.count, 2)
        } else {
            XCTFail("Expected services result, got \(result)")
        }
    }

    func testResolveRoomScopedGroupDifferentRooms() {
        // Create room-scoped groups for different rooms with same name
        let officeGroup = DeviceGroup(
            id: UUID().uuidString,
            name: "All Lights",
            icon: "lightbulb",
            deviceIds: [officeSpotlightsId.uuidString],
            roomId: officeRoomId.uuidString
        )
        let bedroomGroup = DeviceGroup(
            id: UUID().uuidString,
            name: "All Lights",
            icon: "lightbulb",
            deviceIds: [bedroomLightId.uuidString, bedroomSpotlightsId.uuidString],
            roomId: bedroomRoomId.uuidString
        )

        // Request Office group
        let officeResult = DeviceResolver.resolve("Office/group.All Lights", in: testMenuData, groups: [officeGroup, bedroomGroup])
        if case .services(let services) = officeResult {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].uniqueIdentifier, officeSpotlightsId.uuidString)
        } else {
            XCTFail("Expected services result for Office, got \(officeResult)")
        }

        // Request Bedroom group
        let bedroomResult = DeviceResolver.resolve("Bedroom/group.All Lights", in: testMenuData, groups: [officeGroup, bedroomGroup])
        if case .services(let services) = bedroomResult {
            XCTAssertEqual(services.count, 2)
        } else {
            XCTFail("Expected services result for Bedroom, got \(bedroomResult)")
        }
    }

    func testResolveRoomScopedGroupNotFoundRoom() {
        let group = DeviceGroup(
            id: UUID().uuidString,
            name: "All Lights",
            icon: "lightbulb",
            deviceIds: [officeSpotlightsId.uuidString],
            roomId: officeRoomId.uuidString
        )

        // Non-existent room
        let result = DeviceResolver.resolve("Bathroom/group.All Lights", in: testMenuData, groups: [group])

        if case .notFound = result {
            // Expected
        } else {
            XCTFail("Expected notFound result, got \(result)")
        }
    }

    func testResolveRoomScopedGroupNotFoundGroup() {
        // No groups defined
        let result = DeviceResolver.resolve("Office/group.All Lights", in: testMenuData, groups: [])

        if case .notFound = result {
            // Expected
        } else {
            XCTFail("Expected notFound result, got \(result)")
        }
    }

    func testResolveRoomScopedGroupWrongRoom() {
        // Group exists but for a different room
        let bedroomGroup = DeviceGroup(
            id: UUID().uuidString,
            name: "All Lights",
            icon: "lightbulb",
            deviceIds: [bedroomLightId.uuidString],
            roomId: bedroomRoomId.uuidString
        )

        // Request for Office but group is for Bedroom, and no global fallback
        let result = DeviceResolver.resolve("Office/group.All Lights", in: testMenuData, groups: [bedroomGroup])

        if case .notFound = result {
            // Expected - no Office-scoped or global group exists
        } else {
            XCTFail("Expected notFound result, got \(result)")
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

    func testResolveRoomSlashDeviceNotFoundRoom() {
        let result = DeviceResolver.resolve("Bathroom/Spotlights", in: testMenuData)

        if case .notFound = result {
            // Expected - no bathroom room exists
        } else {
            XCTFail("Expected notFound result, got \(result)")
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

    func testResolveRoomSlashDeviceAmbiguous() {
        // Multiple devices match "Light" in Bedroom
        let result = DeviceResolver.resolve("Bedroom/Light", in: testMenuData)

        // Should match "Bedroom Light" exactly or be ambiguous
        if case .services(let services) = result {
            XCTAssertEqual(services.count, 1)
            XCTAssertEqual(services[0].name, "Bedroom Light")
        } else if case .ambiguous = result {
            // Also acceptable
        } else {
            XCTFail("Expected services or ambiguous result, got \(result)")
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
}
