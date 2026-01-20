//
//  FanMenuItem.swift
//  macOSBridge
//
//  Menu item for controlling fans with speed slider
//

import AppKit

class FanMenuItem: NSMenuItem, CharacteristicUpdatable, CharacteristicRefreshable {

    let serviceData: ServiceData
    weak var bridge: Mac2iOS?

    private var activeId: UUID?
    private var rotationSpeedId: UUID?
    private var isActive: Bool = false
    private var speed: Double = 100

    private let containerView: NSView
    private let iconView: NSImageView
    private let nameLabel: NSTextField
    private let speedSlider: NSSlider
    private let toggleButton: NSButton

    var characteristicIdentifiers: [UUID] {
        var ids: [UUID] = []
        if let id = activeId { ids.append(id) }
        if let id = rotationSpeedId { ids.append(id) }
        return ids
    }

    init(serviceData: ServiceData, bridge: Mac2iOS?) {
        self.serviceData = serviceData
        self.bridge = bridge

        // Extract characteristic UUIDs from ServiceData
        self.activeId = serviceData.activeId.flatMap { UUID(uuidString: $0) }
        self.rotationSpeedId = serviceData.rotationSpeedId.flatMap { UUID(uuidString: $0) }

        let hasSpeed = rotationSpeedId != nil

        // Create the custom view
        containerView = NSView(frame: NSRect(x: 0, y: 0, width: 250, height: hasSpeed ? 50 : 30))

        // Icon
        let iconY = hasSpeed ? 15 : 5
        iconView = NSImageView(frame: NSRect(x: 10, y: iconY, width: 20, height: 20))
        iconView.image = NSImage(systemSymbolName: "fan", accessibilityDescription: nil)
        iconView.contentTintColor = .secondaryLabelColor
        containerView.addSubview(iconView)

        // Name label
        let labelY = hasSpeed ? 28 : 6
        nameLabel = NSTextField(labelWithString: serviceData.name)
        nameLabel.frame = NSRect(x: 38, y: labelY, width: 170, height: 17)
        nameLabel.font = NSFont.systemFont(ofSize: 13)
        containerView.addSubview(nameLabel)

        // Speed slider (only if supported)
        speedSlider = NSSlider(frame: NSRect(x: 38, y: 5, width: 160, height: 20))
        speedSlider.minValue = 0
        speedSlider.maxValue = 100
        speedSlider.doubleValue = 100
        speedSlider.isContinuous = false
        speedSlider.isHidden = !hasSpeed
        if hasSpeed {
            containerView.addSubview(speedSlider)
        }

        // Toggle button
        let buttonY = hasSpeed ? 12 : 2
        toggleButton = NSButton(frame: NSRect(x: 210, y: buttonY, width: 30, height: 26))
        toggleButton.bezelStyle = .inline
        toggleButton.setButtonType(.toggle)
        toggleButton.title = ""
        toggleButton.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        containerView.addSubview(toggleButton)

        super.init(title: serviceData.name, action: nil, keyEquivalent: "")

        self.view = containerView

        // Set up actions
        speedSlider.target = self
        speedSlider.action = #selector(sliderChanged(_:))

        toggleButton.target = self
        toggleButton.action = #selector(togglePower(_:))
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateValue(for characteristicId: UUID, value: Any) {
        if characteristicId == activeId {
            if let intValue = value as? Int {
                isActive = intValue == 1
                updateUI()
            } else if let boolValue = value as? Bool {
                isActive = boolValue
                updateUI()
            }
        } else if characteristicId == rotationSpeedId {
            if let doubleValue = value as? Double {
                speed = doubleValue
                speedSlider.doubleValue = doubleValue
            } else if let intValue = value as? Int {
                speed = Double(intValue)
                speedSlider.doubleValue = speed
            } else if let floatValue = value as? Float {
                speed = Double(floatValue)
                speedSlider.doubleValue = speed
            }
        }
    }

    private func updateUI() {
        iconView.image = NSImage(systemSymbolName: isActive ? "fan.fill" : "fan", accessibilityDescription: nil)
        iconView.contentTintColor = isActive ? .systemCyan : .secondaryLabelColor
        toggleButton.state = isActive ? .on : .off
    }

    @objc private func sliderChanged(_ sender: NSSlider) {
        let value = sender.doubleValue
        if let id = rotationSpeedId {
            bridge?.writeCharacteristic(identifier: id, value: Float(value))
        }

        // Also turn on if setting speed > 0 and fan is off
        if value > 0 && !isActive, let powerId = activeId {
            bridge?.writeCharacteristic(identifier: powerId, value: 1)
            isActive = true
            updateUI()
        }
    }

    @objc private func togglePower(_ sender: NSButton) {
        isActive = sender.state == .on
        if let id = activeId {
            bridge?.writeCharacteristic(identifier: id, value: isActive ? 1 : 0)
        }
        updateUI()
    }
}
