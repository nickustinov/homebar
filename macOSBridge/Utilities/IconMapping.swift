//
//  IconMapping.swift
//  macOSBridge
//
//  Shared icon mapping utilities for services and rooms
//  Now uses Phosphor icons via PhosphorIcon
//

import AppKit

enum IconMapping {

    static func iconForServiceType(_ type: String) -> NSImage? {
        PhosphorIcon.defaultIcon(for: type)
    }

    static func iconForServiceType(_ type: String, filled: Bool) -> NSImage? {
        let name = PhosphorIcon.defaultIconName(for: type)
        return PhosphorIcon.icon(name, filled: filled)
    }

    static func iconForRoom(_ name: String) -> NSImage? {
        PhosphorIcon.iconForRoom(name)
    }
}
