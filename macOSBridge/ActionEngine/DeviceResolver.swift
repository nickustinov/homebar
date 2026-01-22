//
//  DeviceResolver.swift
//  macOSBridge
//
//  Resolves human-readable identifiers to HomeKit services
//

import Foundation

enum DeviceResolver {

    // MARK: - Result types

    enum ResolveResult: Equatable {
        case services([ServiceData])
        case scene(SceneData)
        case notFound(String)
        case ambiguous([ServiceData])

        static func == (lhs: ResolveResult, rhs: ResolveResult) -> Bool {
            switch (lhs, rhs) {
            case (.services(let a), .services(let b)):
                return a.map(\.uniqueIdentifier) == b.map(\.uniqueIdentifier)
            case (.scene(let a), .scene(let b)):
                return a.uniqueIdentifier == b.uniqueIdentifier
            case (.notFound(let a), .notFound(let b)):
                return a == b
            case (.ambiguous(let a), .ambiguous(let b)):
                return a.map(\.uniqueIdentifier) == b.map(\.uniqueIdentifier)
            default:
                return false
            }
        }
    }

    // MARK: - Service type mappings

    private static let typeAliases: [String: String] = [
        "light": ServiceTypes.lightbulb,
        "lightbulb": ServiceTypes.lightbulb,
        "switch": ServiceTypes.switch,
        "outlet": ServiceTypes.outlet,
        "thermostat": ServiceTypes.thermostat,
        "ac": ServiceTypes.heaterCooler,
        "aircon": ServiceTypes.heaterCooler,
        "heater": ServiceTypes.heaterCooler,
        "cooler": ServiceTypes.heaterCooler,
        "lock": ServiceTypes.lock,
        "blind": ServiceTypes.windowCovering,
        "blinds": ServiceTypes.windowCovering,
        "shade": ServiceTypes.windowCovering,
        "shades": ServiceTypes.windowCovering,
        "window": ServiceTypes.windowCovering,
        "fan": ServiceTypes.fan,
        "garage": ServiceTypes.garageDoorOpener,
        "humidifier": ServiceTypes.humidifierDehumidifier,
        "dehumidifier": ServiceTypes.humidifierDehumidifier,
        "purifier": ServiceTypes.airPurifier,
        "valve": ServiceTypes.valve,
        "sprinkler": ServiceTypes.valve,
        "security": ServiceTypes.securitySystem,
        "alarm": ServiceTypes.securitySystem,
    ]

    // MARK: - Public API

    /// Resolve a target string to HomeKit entities
    /// Supported formats:
    /// - UUID: "ABC123-DEF456-..."
    /// - Type.Room: "light.bedroom", "switch.kitchen"
    /// - Name: "Bedroom Light", "Kitchen Switch"
    /// - Scene: "scene.goodnight", "Goodnight"
    /// - Room wildcard: "bedroom.*", "all bedroom"
    /// - Type wildcard: "*.light", "all lights"
    static func resolve(_ query: String, in data: MenuData) -> ResolveResult {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return .notFound(query)
        }

        // 1. Check for UUID match
        if let uuidResult = resolveByUUID(trimmed, in: data) {
            return uuidResult
        }

        // 2. Check for scene prefix
        if let sceneResult = resolveScene(trimmed, in: data) {
            return sceneResult
        }

        // 3. Check for type.room format
        if let dotResult = resolveTypeDotRoom(trimmed, in: data) {
            return dotResult
        }

        // 4. Check for wildcards
        if let wildcardResult = resolveWildcard(trimmed, in: data) {
            return wildcardResult
        }

        // 5. Exact name match (case-insensitive) - before room/device to prioritize exact matches
        if let exactMatch = resolveExactName(trimmed, in: data) {
            return exactMatch
        }

        // 6. Room + device name format: "Office/Spotlights" or "Office Spotlights"
        if let roomDeviceMatch = resolveRoomAndDeviceName(trimmed, in: data) {
            return roomDeviceMatch
        }

        // 7. Fuzzy match on service name
        if let fuzzyMatch = resolveFuzzyName(trimmed, in: data) {
            return fuzzyMatch
        }

        return .notFound(query)
    }

    // MARK: - Resolution strategies

    private static func resolveByUUID(_ query: String, in data: MenuData) -> ResolveResult? {
        // Check if it looks like a UUID (contains hyphens and hex chars)
        guard query.contains("-"),
              query.range(of: "^[A-Fa-f0-9-]+$", options: .regularExpression) != nil else {
            return nil
        }

        let upperQuery = query.uppercased()

        // Check services
        for accessory in data.accessories {
            for service in accessory.services {
                if service.uniqueIdentifier.uppercased() == upperQuery {
                    return .services([service])
                }
            }
        }

        // Check scenes
        for scene in data.scenes {
            if scene.uniqueIdentifier.uppercased() == upperQuery {
                return .scene(scene)
            }
        }

        return nil
    }

    private static func resolveScene(_ query: String, in data: MenuData) -> ResolveResult? {
        let lowered = query.lowercased()

        // Check for scene. prefix
        if lowered.hasPrefix("scene.") {
            let sceneName = String(query.dropFirst(6))
            return findSceneByName(sceneName, in: data)
        }

        // Also check direct scene name match
        for scene in data.scenes {
            if scene.name.lowercased() == lowered {
                return .scene(scene)
            }
        }

        return nil
    }

    private static func findSceneByName(_ name: String, in data: MenuData) -> ResolveResult {
        let loweredName = name.lowercased()

        // Exact match first
        for scene in data.scenes {
            if scene.name.lowercased() == loweredName {
                return .scene(scene)
            }
        }

        // Partial match
        let matches = data.scenes.filter { scene in
            scene.name.lowercased().contains(loweredName)
        }

        if matches.count == 1 {
            return .scene(matches[0])
        }

        return .notFound("scene.\(name)")
    }

    private static func resolveTypeDotRoom(_ query: String, in data: MenuData) -> ResolveResult? {
        let parts = query.split(separator: ".", maxSplits: 1)
        guard parts.count == 2 else { return nil }

        let typePart = String(parts[0]).lowercased()
        let roomPart = String(parts[1]).lowercased()

        // Handle wildcards in type.room format
        if typePart == "*" {
            return resolveByRoom(roomPart, in: data)
        }
        if roomPart == "*" {
            return resolveByType(typePart, in: data)
        }

        // Get service type UUID
        guard let serviceTypeUUID = typeAliases[typePart] else {
            return nil
        }

        // Find room
        let roomMatches = data.rooms.filter { room in
            room.name.lowercased().contains(roomPart)
        }

        guard !roomMatches.isEmpty else {
            return .notFound(query)
        }

        // Find services matching type and room
        let roomIds = Set(roomMatches.map(\.uniqueIdentifier))
        var matchingServices: [ServiceData] = []

        for accessory in data.accessories {
            for service in accessory.services {
                if service.serviceType == serviceTypeUUID,
                   let roomId = service.roomIdentifier,
                   roomIds.contains(roomId) {
                    matchingServices.append(service)
                }
            }
        }

        if matchingServices.isEmpty {
            return .notFound(query)
        }

        return .services(matchingServices)
    }

    private static func resolveWildcard(_ query: String, in data: MenuData) -> ResolveResult? {
        let lowered = query.lowercased()

        // "all lights", "all switches", etc.
        if lowered.hasPrefix("all ") {
            let typeName = String(lowered.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            return resolveByType(typeName, in: data)
        }

        // "bedroom.*" or "bedroom.all"
        if lowered.hasSuffix(".*") || lowered.hasSuffix(".all") {
            let roomName = lowered.hasSuffix(".*")
                ? String(lowered.dropLast(2))
                : String(lowered.dropLast(4))
            return resolveByRoom(roomName, in: data)
        }

        // "*.light" or "all.light"
        if lowered.hasPrefix("*.") || lowered.hasPrefix("all.") {
            let typeName = lowered.hasPrefix("*.")
                ? String(lowered.dropFirst(2))
                : String(lowered.dropFirst(4))
            return resolveByType(typeName, in: data)
        }

        return nil
    }

    private static func resolveByType(_ typeName: String, in data: MenuData) -> ResolveResult? {
        // Handle plural forms
        var normalized = typeName

        // Try exact match first
        if typeAliases[normalized] == nil {
            // Try removing "es" suffix (switches -> switch)
            if normalized.hasSuffix("es") && typeAliases[String(normalized.dropLast(2))] != nil {
                normalized = String(normalized.dropLast(2))
            }
            // Try removing "s" suffix (lights -> light)
            else if normalized.hasSuffix("s") && typeAliases[String(normalized.dropLast())] != nil {
                normalized = String(normalized.dropLast())
            }
        }

        guard let serviceTypeUUID = typeAliases[normalized] else {
            return nil
        }

        var matchingServices: [ServiceData] = []
        for accessory in data.accessories {
            for service in accessory.services {
                if service.serviceType == serviceTypeUUID {
                    matchingServices.append(service)
                }
            }
        }

        if matchingServices.isEmpty {
            return .notFound("all \(typeName)")
        }

        return .services(matchingServices)
    }

    private static func resolveByRoom(_ roomName: String, in data: MenuData) -> ResolveResult? {
        let roomMatches = data.rooms.filter { room in
            room.name.lowercased().contains(roomName.lowercased())
        }

        guard !roomMatches.isEmpty else {
            return nil
        }

        let roomIds = Set(roomMatches.map(\.uniqueIdentifier))
        var matchingServices: [ServiceData] = []

        for accessory in data.accessories {
            for service in accessory.services {
                if let roomId = service.roomIdentifier, roomIds.contains(roomId) {
                    matchingServices.append(service)
                }
            }
        }

        if matchingServices.isEmpty {
            return .notFound("\(roomName).*")
        }

        return .services(matchingServices)
    }

    private static func resolveRoomAndDeviceName(_ query: String, in data: MenuData) -> ResolveResult? {
        // Try splitting by "/" first, then by space
        let separators: [Character] = ["/", " "]

        for separator in separators {
            let parts = query.split(separator: separator, maxSplits: 1)
            guard parts.count == 2 else { continue }

            let roomPart = String(parts[0]).lowercased()
            let devicePart = String(parts[1]).lowercased()

            // Find matching room
            let roomMatches = data.rooms.filter { room in
                room.name.lowercased() == roomPart || room.name.lowercased().contains(roomPart)
            }

            guard !roomMatches.isEmpty else { continue }

            let roomIds = Set(roomMatches.map(\.uniqueIdentifier))

            // Find services in that room matching the device name
            var matchingServices: [ServiceData] = []
            for accessory in data.accessories {
                for service in accessory.services {
                    if let roomId = service.roomIdentifier,
                       roomIds.contains(roomId),
                       (service.name.lowercased() == devicePart ||
                        service.name.lowercased().contains(devicePart)) {
                        matchingServices.append(service)
                    }
                }
            }

            if matchingServices.count == 1 {
                return .services(matchingServices)
            } else if matchingServices.count > 1 {
                // Prefer exact name match
                let exactMatches = matchingServices.filter { $0.name.lowercased() == devicePart }
                if exactMatches.count == 1 {
                    return .services(exactMatches)
                }
                return .ambiguous(matchingServices)
            }
        }

        return nil
    }

    private static func resolveExactName(_ query: String, in data: MenuData) -> ResolveResult? {
        let loweredQuery = query.lowercased()

        // Check services first
        var exactMatches: [ServiceData] = []
        for accessory in data.accessories {
            for service in accessory.services {
                if service.name.lowercased() == loweredQuery {
                    exactMatches.append(service)
                }
            }
        }

        if exactMatches.count == 1 {
            return .services(exactMatches)
        } else if exactMatches.count > 1 {
            return .ambiguous(exactMatches)
        }

        return nil
    }

    private static func resolveFuzzyName(_ query: String, in data: MenuData) -> ResolveResult? {
        let loweredQuery = query.lowercased()

        // Find services with names containing the query
        var fuzzyMatches: [ServiceData] = []
        for accessory in data.accessories {
            for service in accessory.services {
                if service.name.lowercased().contains(loweredQuery) {
                    fuzzyMatches.append(service)
                }
            }
        }

        if fuzzyMatches.count == 1 {
            return .services(fuzzyMatches)
        } else if fuzzyMatches.count > 1 {
            // Try to find a more specific match
            let startsWithMatches = fuzzyMatches.filter {
                $0.name.lowercased().hasPrefix(loweredQuery)
            }
            if startsWithMatches.count == 1 {
                return .services(startsWithMatches)
            }
            return .ambiguous(fuzzyMatches)
        }

        return nil
    }
}
