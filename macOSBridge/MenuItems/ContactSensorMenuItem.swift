//
//  ContactSensorMenuItem.swift
//  macOSBridge
//
//  Menu item for displaying contact sensor state (door/window open/closed)
//

import AppKit

class ContactSensorMenuItem: NSMenuItem, CharacteristicUpdatable, CharacteristicRefreshable {

    let serviceData: ServiceData
    weak var bridge: Mac2iOS?

    private var contactSensorStateId: UUID?

    // Contact sensor state: 0=detected (contact/closed), 1=not detected (no contact/open)
    private var isOpen: Bool = false

    private let containerView: NSView
    private let iconView: NSImageView
    private let nameLabel: NSTextField
    private let stateLabel: NSTextField

    var characteristicIdentifiers: [UUID] {
        var ids: [UUID] = []
        if let id = contactSensorStateId { ids.append(id) }
        return ids
    }

    init(serviceData: ServiceData, bridge: Mac2iOS?) {
        self.serviceData = serviceData
        self.bridge = bridge

        // Extract characteristic UUID from ServiceData
        self.contactSensorStateId = serviceData.contactSensorStateId.flatMap { UUID(uuidString: $0) }

        // Create the custom view
        containerView = NSView(frame: NSRect(x: 0, y: 0, width: 250, height: 30))

        // Icon
        iconView = NSImageView(frame: NSRect(x: 10, y: 5, width: 20, height: 20))
        iconView.image = NSImage(systemSymbolName: "door.left.hand.closed", accessibilityDescription: nil)
        iconView.contentTintColor = .secondaryLabelColor
        containerView.addSubview(iconView)

        // Name label
        nameLabel = NSTextField(labelWithString: serviceData.name)
        nameLabel.frame = NSRect(x: 38, y: 6, width: 140, height: 17)
        nameLabel.font = NSFont.systemFont(ofSize: 13)
        containerView.addSubview(nameLabel)

        // State label
        stateLabel = NSTextField(labelWithString: "Closed")
        stateLabel.frame = NSRect(x: 180, y: 6, width: 60, height: 17)
        stateLabel.font = NSFont.systemFont(ofSize: 13)
        stateLabel.alignment = .right
        stateLabel.textColor = .secondaryLabelColor
        containerView.addSubview(stateLabel)

        super.init(title: serviceData.name, action: nil, keyEquivalent: "")

        self.view = containerView
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateValue(for characteristicId: UUID, value: Any) {
        if characteristicId == contactSensorStateId {
            // ContactSensorState: 0 = contact detected (closed), 1 = contact not detected (open)
            if let intValue = value as? Int {
                isOpen = intValue == 1
                updateUI()
            } else if let boolValue = value as? Bool {
                isOpen = boolValue
                updateUI()
            }
        }
    }

    private func updateUI() {
        if isOpen {
            iconView.image = NSImage(systemSymbolName: "door.left.hand.open", accessibilityDescription: nil)
            iconView.contentTintColor = .systemOrange
            stateLabel.stringValue = "Open"
            stateLabel.textColor = .systemOrange
        } else {
            iconView.image = NSImage(systemSymbolName: "door.left.hand.closed", accessibilityDescription: nil)
            iconView.contentTintColor = .systemGreen
            stateLabel.stringValue = "Closed"
            stateLabel.textColor = .systemGreen
        }
    }
}
