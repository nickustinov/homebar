//
//  GarageDoorMenuItem.swift
//  macOSBridge
//
//  Menu item for controlling garage doors with confirmation
//

import AppKit

class GarageDoorMenuItem: NSMenuItem, CharacteristicUpdatable, CharacteristicRefreshable {

    let serviceData: ServiceData
    weak var bridge: Mac2iOS?

    private var currentDoorStateId: UUID?
    private var targetDoorStateId: UUID?
    private var obstructionDetectedId: UUID?

    // Door states: 0=open, 1=closed, 2=opening, 3=closing, 4=stopped
    private var currentState: Int = 1  // Default closed
    private var isObstructed: Bool = false

    private let containerView: NSView
    private let iconView: NSImageView
    private let nameLabel: NSTextField
    private let stateLabel: NSTextField
    private let actionButton: NSButton

    var characteristicIdentifiers: [UUID] {
        var ids: [UUID] = []
        if let id = currentDoorStateId { ids.append(id) }
        if let id = targetDoorStateId { ids.append(id) }
        if let id = obstructionDetectedId { ids.append(id) }
        return ids
    }

    init(serviceData: ServiceData, bridge: Mac2iOS?) {
        self.serviceData = serviceData
        self.bridge = bridge

        // Extract characteristic UUIDs from ServiceData
        self.currentDoorStateId = serviceData.currentDoorStateId.flatMap { UUID(uuidString: $0) }
        self.targetDoorStateId = serviceData.targetDoorStateId.flatMap { UUID(uuidString: $0) }
        self.obstructionDetectedId = serviceData.obstructionDetectedId.flatMap { UUID(uuidString: $0) }

        // Create the custom view
        containerView = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 40))

        // Icon
        iconView = NSImageView(frame: NSRect(x: 10, y: 10, width: 20, height: 20))
        iconView.image = NSImage(systemSymbolName: "door.garage.closed", accessibilityDescription: nil)
        iconView.contentTintColor = .secondaryLabelColor
        containerView.addSubview(iconView)

        // Name label
        nameLabel = NSTextField(labelWithString: serviceData.name)
        nameLabel.frame = NSRect(x: 38, y: 20, width: 130, height: 17)
        nameLabel.font = NSFont.systemFont(ofSize: 13)
        containerView.addSubview(nameLabel)

        // State label
        stateLabel = NSTextField(labelWithString: "Closed")
        stateLabel.frame = NSRect(x: 38, y: 4, width: 130, height: 14)
        stateLabel.font = NSFont.systemFont(ofSize: 11)
        stateLabel.textColor = .secondaryLabelColor
        containerView.addSubview(stateLabel)

        // Action button
        actionButton = NSButton(frame: NSRect(x: 175, y: 7, width: 95, height: 26))
        actionButton.bezelStyle = .inline
        actionButton.title = "Open"
        actionButton.font = NSFont.systemFont(ofSize: 11)
        containerView.addSubview(actionButton)

        super.init(title: serviceData.name, action: nil, keyEquivalent: "")

        self.view = containerView

        // Set up action
        actionButton.target = self
        actionButton.action = #selector(toggleDoor(_:))
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateValue(for characteristicId: UUID, value: Any) {
        if characteristicId == currentDoorStateId, let intValue = value as? Int {
            currentState = intValue
            updateUI()
        } else if characteristicId == obstructionDetectedId {
            if let boolValue = value as? Bool {
                isObstructed = boolValue
                updateUI()
            } else if let intValue = value as? Int {
                isObstructed = intValue != 0
                updateUI()
            }
        }
    }

    private func updateUI() {
        let (symbolName, stateText, buttonTitle, tintColor): (String, String, String, NSColor) = {
            if isObstructed {
                return ("exclamationmark.triangle", "Obstructed", "—", .systemRed)
            }
            switch currentState {
            case 0:  // Open
                return ("door.garage.open", "Open", "Close", .systemGreen)
            case 1:  // Closed
                return ("door.garage.closed", "Closed", "Open", .secondaryLabelColor)
            case 2:  // Opening
                return ("door.garage.open", "Opening...", "Stop", .systemOrange)
            case 3:  // Closing
                return ("door.garage.closed", "Closing...", "Stop", .systemOrange)
            case 4:  // Stopped
                return ("door.garage.open", "Stopped", "Close", .systemYellow)
            default:
                return ("door.garage.closed", "Unknown", "—", .secondaryLabelColor)
            }
        }()

        iconView.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        iconView.contentTintColor = tintColor
        stateLabel.stringValue = stateText
        actionButton.title = buttonTitle
        actionButton.isEnabled = !isObstructed && buttonTitle != "—"
    }

    @objc private func toggleDoor(_ sender: NSButton) {
        // Determine action based on current state
        let targetState: Int
        let actionDescription: String

        switch currentState {
        case 0:  // Open -> Close
            targetState = 1
            actionDescription = "close"
        case 1:  // Closed -> Open
            targetState = 0
            actionDescription = "open"
        case 2, 3:  // Opening/Closing -> Stop (toggle)
            // When in motion, toggling usually stops or reverses
            targetState = currentState == 2 ? 1 : 0
            actionDescription = "stop"
        case 4:  // Stopped -> Close
            targetState = 1
            actionDescription = "close"
        default:
            return
        }

        // Show confirmation alert
        let alert = NSAlert()
        alert.messageText = "Garage door"
        alert.informativeText = "Are you sure you want to \(actionDescription) \(serviceData.name)?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: actionDescription.capitalized)
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            if let id = targetDoorStateId {
                bridge?.writeCharacteristic(identifier: id, value: targetState)
            }
        }
    }
}
