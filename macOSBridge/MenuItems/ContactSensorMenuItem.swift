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

        let height = DS.ControlSize.menuItemHeight

        // Create the custom view
        containerView = NSView(frame: NSRect(x: 0, y: 0, width: DS.ControlSize.menuItemWidth, height: height))

        // Icon
        let iconY = (height - DS.ControlSize.iconMedium) / 2
        iconView = NSImageView(frame: NSRect(x: DS.Spacing.md, y: iconY, width: DS.ControlSize.iconMedium, height: DS.ControlSize.iconMedium))
        iconView.image = NSImage(systemSymbolName: "door.left.hand.closed", accessibilityDescription: nil)
        iconView.contentTintColor = DS.Colors.success
        iconView.imageScaling = .scaleProportionallyUpOrDown
        containerView.addSubview(iconView)

        // Name label
        let labelX = DS.Spacing.md + DS.ControlSize.iconMedium + DS.Spacing.sm
        let labelY = (height - 17) / 2
        nameLabel = NSTextField(labelWithString: serviceData.name)
        nameLabel.frame = NSRect(x: labelX, y: labelY, width: 140, height: 17)
        nameLabel.font = DS.Typography.label
        nameLabel.textColor = DS.Colors.foreground
        nameLabel.lineBreakMode = .byTruncatingTail
        containerView.addSubview(nameLabel)

        // State label
        stateLabel = NSTextField(labelWithString: "Closed")
        stateLabel.frame = NSRect(x: DS.ControlSize.menuItemWidth - DS.Spacing.md - 60, y: labelY, width: 60, height: 17)
        stateLabel.font = DS.Typography.label
        stateLabel.alignment = .right
        stateLabel.textColor = DS.Colors.success
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
            iconView.contentTintColor = DS.Colors.warning
            stateLabel.stringValue = "Open"
            stateLabel.textColor = DS.Colors.warning
        } else {
            iconView.image = NSImage(systemSymbolName: "door.left.hand.closed", accessibilityDescription: nil)
            iconView.contentTintColor = DS.Colors.success
            stateLabel.stringValue = "Closed"
            stateLabel.textColor = DS.Colors.success
        }
    }
}
