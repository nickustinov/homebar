//
//  ColorConversion.swift
//  macOSBridge
//
//  Shared color conversion utilities
//

import AppKit

enum ColorConversion {

    /// Converts mired color temperature to an NSColor for display
    /// Uses expanded range (50-500) to properly distinguish warm bulbs
    static func miredToColor(_ mired: Double) -> NSColor {
        let clamped = max(0, min(1, (mired - 50) / 450))
        if clamped < 0.5 {
            // Cool side: bluish white to neutral white
            let t = clamped * 2
            return NSColor(red: 0.9 + 0.1 * t, green: 0.95 + 0.05 * t, blue: 1.0, alpha: 1.0)
        } else {
            // Warm side: neutral white to orange/amber
            let t = (clamped - 0.5) * 2
            return NSColor(red: 1.0, green: 1.0 - 0.35 * t, blue: 1.0 - 0.7 * t, alpha: 1.0)
        }
    }
}
