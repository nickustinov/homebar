//
//  SceneMenuItem.swift
//  macOSBridge
//
//  Menu item for controlling scenes with toggle switch (list style)
//

import AppKit

class SceneMenuItem: NSMenuItem, CharacteristicUpdatable, CharacteristicRefreshable {

    let sceneData: SceneData
    weak var bridge: Mac2iOS?

    private var currentValues: [UUID: Double] = [:]
    private var isActive: Bool = false

    private let containerView: NSView
    private let iconView: NSImageView
    private let nameLabel: NSTextField
    private let toggleSwitch: ToggleSwitch

    // Characteristic types that can be reversed
    private static let reversibleTypes: Set<String> = [
        CharacteristicTypes.powerState,
        CharacteristicTypes.brightness,
        CharacteristicTypes.targetPosition,
        CharacteristicTypes.lockTargetState,
        CharacteristicTypes.targetDoorState,
        CharacteristicTypes.active,
        CharacteristicTypes.rotationSpeed
    ]

    var characteristicIdentifiers: [UUID] {
        sceneData.actions.compactMap { UUID(uuidString: $0.characteristicId) }
    }

    init(sceneData: SceneData, bridge: Mac2iOS?) {
        self.sceneData = sceneData
        self.bridge = bridge

        let height = DS.ControlSize.menuItemHeight

        // Create the custom view
        containerView = NSView(frame: NSRect(x: 0, y: 0, width: DS.ControlSize.menuItemWidth, height: height))

        // Icon
        let iconY = (height - DS.ControlSize.iconMedium) / 2
        iconView = NSImageView(frame: NSRect(x: DS.Spacing.md, y: iconY, width: DS.ControlSize.iconMedium, height: DS.ControlSize.iconMedium))
        iconView.image = Self.inferIcon(for: sceneData)
        iconView.contentTintColor = DS.Colors.mutedForeground
        iconView.imageScaling = .scaleProportionallyUpOrDown
        containerView.addSubview(iconView)

        // Name label
        let labelX = DS.Spacing.md + DS.ControlSize.iconMedium + DS.Spacing.sm
        let labelY = (height - 17) / 2
        let labelWidth = DS.ControlSize.menuItemWidth - labelX - DS.ControlSize.switchWidth - DS.Spacing.lg - DS.Spacing.md
        nameLabel = NSTextField(labelWithString: sceneData.name)
        nameLabel.frame = NSRect(x: labelX, y: labelY, width: labelWidth, height: 17)
        nameLabel.font = DS.Typography.label
        nameLabel.textColor = DS.Colors.foreground
        nameLabel.lineBreakMode = .byTruncatingTail
        containerView.addSubview(nameLabel)

        // Toggle switch
        let switchX = DS.ControlSize.menuItemWidth - DS.ControlSize.switchWidth - DS.Spacing.md
        let switchY = (height - DS.ControlSize.switchHeight) / 2
        toggleSwitch = ToggleSwitch()
        toggleSwitch.frame = NSRect(x: switchX, y: switchY, width: DS.ControlSize.switchWidth, height: DS.ControlSize.switchHeight)
        containerView.addSubview(toggleSwitch)

        super.init(title: sceneData.name, action: nil, keyEquivalent: "")

        self.view = containerView

        // Set up action
        toggleSwitch.target = self
        toggleSwitch.action = #selector(toggleScene(_:))
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateValue(for characteristicId: UUID, value: Any) {
        // Check if this characteristic belongs to this scene
        guard sceneData.actions.contains(where: { $0.characteristicId == characteristicId.uuidString }) else {
            return
        }

        // Convert value to Double
        let doubleValue: Double
        if let boolValue = value as? Bool {
            doubleValue = boolValue ? 1.0 : 0.0
        } else if let intValue = value as? Int {
            doubleValue = Double(intValue)
        } else if let doubleVal = value as? Double {
            doubleValue = doubleVal
        } else if let floatValue = value as? Float {
            doubleValue = Double(floatValue)
        } else if let numberValue = value as? NSNumber {
            doubleValue = numberValue.doubleValue
        } else {
            return
        }

        currentValues[characteristicId] = doubleValue
        updateActiveState()
    }

    private func updateActiveState() {
        guard !sceneData.actions.isEmpty else {
            isActive = false
            updateUI()
            return
        }

        let allMatch = sceneData.actions.allSatisfy { action in
            guard let charId = UUID(uuidString: action.characteristicId),
                  let currentValue = currentValues[charId] else {
                return false
            }
            let tolerance = Self.tolerance(for: action.characteristicType)
            return abs(currentValue - action.targetValue) < tolerance
        }

        isActive = allMatch
        updateUI()
    }

    private static func tolerance(for characteristicType: String) -> Double {
        switch characteristicType {
        case CharacteristicTypes.targetPosition,
             CharacteristicTypes.currentPosition,
             CharacteristicTypes.brightness,
             CharacteristicTypes.rotationSpeed:
            return 5.0
        default:
            return 0.01
        }
    }

    private func updateUI() {
        iconView.contentTintColor = isActive ? DS.Colors.warning : DS.Colors.mutedForeground
        toggleSwitch.setOn(isActive, animated: false)
        toggleSwitch.needsDisplay = true
        iconView.needsDisplay = true
    }

    @objc private func toggleScene(_ sender: ToggleSwitch) {
        if sender.isOn {
            executeScene()
            // Optimistically update cached values
            for action in sceneData.actions {
                if let charId = UUID(uuidString: action.characteristicId) {
                    currentValues[charId] = action.targetValue
                }
            }
            isActive = true
        } else {
            reverseScene()
            // Optimistically update cached values to opposite
            for action in sceneData.actions {
                if let charId = UUID(uuidString: action.characteristicId),
                   Self.reversibleTypes.contains(action.characteristicType) {
                    let oppositeValue = calculateOppositeValue(for: action)
                    if let doubleValue = oppositeValue as? Double {
                        currentValues[charId] = doubleValue
                    } else if let intValue = oppositeValue as? Int {
                        currentValues[charId] = Double(intValue)
                    } else if let boolValue = oppositeValue as? Bool {
                        currentValues[charId] = boolValue ? 1.0 : 0.0
                    }
                }
            }
            isActive = false
        }
        updateUI()
    }

    private func executeScene() {
        guard let uuid = UUID(uuidString: sceneData.uniqueIdentifier) else { return }
        bridge?.executeScene(identifier: uuid)
    }

    private func reverseScene() {
        for action in sceneData.actions {
            guard let charId = UUID(uuidString: action.characteristicId),
                  Self.reversibleTypes.contains(action.characteristicType) else {
                continue
            }
            let oppositeValue = calculateOppositeValue(for: action)
            bridge?.writeCharacteristic(identifier: charId, value: oppositeValue)
        }
    }

    private func calculateOppositeValue(for action: SceneActionData) -> Any {
        let charType = action.characteristicType
        let targetValue = action.targetValue

        switch charType {
        case CharacteristicTypes.powerState, CharacteristicTypes.active:
            return targetValue > 0.5 ? false : true
        case CharacteristicTypes.brightness, CharacteristicTypes.rotationSpeed:
            return 0
        case CharacteristicTypes.targetPosition:
            return targetValue > 50 ? 0 : 100
        case CharacteristicTypes.lockTargetState, CharacteristicTypes.targetDoorState:
            return targetValue > 0.5 ? 0 : 1
        default:
            return targetValue > 0.5 ? 0 : 1
        }
    }

    // Infer icon from scene name
    private static func inferIcon(for scene: SceneData) -> NSImage? {
        let name = scene.name.lowercased()

        if name.contains("night") || name.contains("sleep") || name.contains("goodnight") || name.contains("bed") {
            return NSImage(systemSymbolName: "moon.fill", accessibilityDescription: nil)
        }
        if name.contains("morning") || name.contains("wake") || name.contains("sunrise") {
            return NSImage(systemSymbolName: "sun.horizon.fill", accessibilityDescription: nil)
        }
        if name.contains("evening") || name.contains("sunset") {
            return NSImage(systemSymbolName: "sun.haze.fill", accessibilityDescription: nil)
        }
        if name.contains("day") || name.contains("bright") {
            return NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: nil)
        }
        if name.contains("movie") || name.contains("cinema") || name.contains("tv") {
            return NSImage(systemSymbolName: "tv.fill", accessibilityDescription: nil)
        }
        if name.contains("party") || name.contains("disco") {
            return NSImage(systemSymbolName: "party.popper.fill", accessibilityDescription: nil)
        }
        if name.contains("relax") || name.contains("chill") || name.contains("calm") {
            return NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: nil)
        }
        if name.contains("work") || name.contains("office") || name.contains("focus") {
            return NSImage(systemSymbolName: "desktopcomputer", accessibilityDescription: nil)
        }
        if name.contains("away") || name.contains("leave") || name.contains("depart") || name.contains("goodbye") {
            return NSImage(systemSymbolName: "figure.walk", accessibilityDescription: nil)
        }
        if name.contains("home") || name.contains("arrive") || name.contains("welcome") {
            return NSImage(systemSymbolName: "house.fill", accessibilityDescription: nil)
        }
        if name.contains("lock") || name.contains("secure") {
            return NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil)
        }
        if name.contains("unlock") || name.contains("open") {
            return NSImage(systemSymbolName: "lock.open.fill", accessibilityDescription: nil)
        }
        if name.contains("gate") {
            return NSImage(systemSymbolName: "door.garage.closed", accessibilityDescription: nil)
        }
        if name.contains("outdoor") || name.contains("outside") || name.contains("garden") || name.contains("terrace") || name.contains("patio") {
            return NSImage(systemSymbolName: "tree.fill", accessibilityDescription: nil)
        }
        if name.contains("indoor") || name.contains("inside") {
            return NSImage(systemSymbolName: "sofa.fill", accessibilityDescription: nil)
        }
        if name.contains("gym") || name.contains("workout") || name.contains("exercise") {
            return NSImage(systemSymbolName: "dumbbell.fill", accessibilityDescription: nil)
        }
        if name.contains("pool") || name.contains("swim") {
            return NSImage(systemSymbolName: "figure.pool.swim", accessibilityDescription: nil)
        }
        if name.contains("dinner") || name.contains("dining") || name.contains("eat") {
            return NSImage(systemSymbolName: "fork.knife", accessibilityDescription: nil)
        }
        if name.contains("cook") || name.contains("kitchen") {
            return NSImage(systemSymbolName: "frying.pan.fill", accessibilityDescription: nil)
        }
        if name.contains("reading") || name.contains("read") || name.contains("book") {
            return NSImage(systemSymbolName: "book.fill", accessibilityDescription: nil)
        }
        if name.contains("romantic") || name.contains("date") || name.contains("love") {
            return NSImage(systemSymbolName: "heart.fill", accessibilityDescription: nil)
        }
        if name.contains("off") || name.contains("all off") {
            return NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        }
        if name.contains("on") || name.contains("all on") {
            return NSImage(systemSymbolName: "lightbulb.fill", accessibilityDescription: nil)
        }

        // Default: sparkles icon
        return NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
    }
}
