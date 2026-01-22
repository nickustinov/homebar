//
//  BaseMenuItems.swift
//  macOSBridge
//
//  Basic menu item types
//

import AppKit

// MARK: - Local change notification

protocol LocalChangeNotifiable: NSMenuItem {}

extension LocalChangeNotifiable {
    func notifyLocalChange(characteristicId: UUID, value: Any) {
        NotificationCenter.default.post(
            name: .characteristicDidChangeLocally,
            object: self,
            userInfo: ["characteristicId": characteristicId, "value": value]
        )
    }
}

// MARK: - Reachability support

/// Protocol for menu items that can show device reachability state.
/// Provides default implementation that dims the view when unreachable.
protocol ReachabilityUpdatableMenuItem: ReachabilityUpdatable, NSMenuItem {
    var serviceData: ServiceData { get }
}

extension ReachabilityUpdatableMenuItem {
    var serviceIdentifier: UUID {
        UUID(uuidString: serviceData.uniqueIdentifier)!
    }

    func setReachable(_ isReachable: Bool) {
        view?.alphaValue = isReachable ? 1.0 : 0.4
        setControlsEnabled(isReachable, in: view)
    }

    private func setControlsEnabled(_ enabled: Bool, in view: NSView?) {
        guard let view = view else { return }
        for subview in view.subviews {
            if let control = subview as? NSControl {
                control.isEnabled = enabled
            }
            setControlsEnabled(enabled, in: subview)
        }
    }
}

// MARK: - Scene icon inference

enum SceneIconInference {
    private static let mappings: [(keywords: [String], symbol: String)] = [
        (["night", "sleep", "goodnight", "bed"], "moon.fill"),
        (["morning", "wake", "sunrise"], "sun.horizon.fill"),
        (["evening", "sunset"], "sun.haze.fill"),
        (["day", "bright"], "sun.max.fill"),
        (["movie", "cinema", "tv"], "tv.fill"),
        (["party", "disco"], "party.popper.fill"),
        (["relax", "chill", "calm"], "leaf.fill"),
        (["work", "office", "focus"], "desktopcomputer"),
        (["away", "leave", "depart", "goodbye"], "figure.walk"),
        (["home", "arrive", "welcome"], "house.fill"),
        (["lock", "secure"], "lock.fill"),
        (["unlock", "open"], "lock.open.fill"),
        (["gate"], "door.garage.closed"),
        (["outdoor", "outside", "garden", "terrace", "patio"], "tree.fill"),
        (["indoor", "inside"], "sofa.fill"),
        (["gym", "workout", "exercise"], "dumbbell.fill"),
        (["pool", "swim"], "figure.pool.swim"),
        (["dinner", "dining", "eat"], "fork.knife"),
        (["cook", "kitchen"], "frying.pan.fill"),
        (["reading", "read", "book"], "book.fill"),
        (["romantic", "date", "love"], "heart.fill"),
        (["off", "all off"], "power"),
        (["on", "all on"], "lightbulb.fill"),
    ]

    static func icon(for sceneName: String) -> NSImage? {
        let name = sceneName.lowercased()

        for (keywords, symbol) in mappings {
            if keywords.contains(where: { name.contains($0) }) {
                return NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            }
        }

        return NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
    }
}

// MARK: - Home Menu Item

class HomeMenuItem: NSMenuItem {
    let home: HomeInfo

    init(home: HomeInfo, target: AnyObject?, action: Selector?) {
        self.home = home
        super.init(title: home.name, action: action, keyEquivalent: "")
        self.target = target
        self.image = NSImage(systemSymbolName: home.isPrimary ? "house.fill" : "house", accessibilityDescription: nil)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
