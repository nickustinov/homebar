//
//  FavouritesRowView.swift
//  macOSBridge
//
//  Row view for favourites dialog showing item with star/eye toggles
//

import AppKit

class FavouritesRowView: NSView {

    enum ItemType {
        case scene(SceneData)
        case service(ServiceData)
    }

    private let starButton: NSButton
    private let eyeButton: NSButton
    private let nameLabel: NSTextField
    private let typeIcon: NSImageView

    private let itemType: ItemType
    private var isFavourite: Bool
    private var isItemHidden: Bool

    var onFavouriteToggled: (() -> Void)?
    var onVisibilityToggled: (() -> Void)?

    private static let rowHeight: CGFloat = 28

    init(itemType: ItemType, isFavourite: Bool, isItemHidden: Bool = false) {
        self.itemType = itemType
        self.isFavourite = isFavourite
        self.isItemHidden = isItemHidden

        // Star button
        starButton = NSButton(frame: .zero)
        starButton.bezelStyle = .inline
        starButton.isBordered = false
        starButton.imagePosition = .imageOnly
        starButton.imageScaling = .scaleProportionallyUpOrDown

        // Eye button (only for services)
        eyeButton = NSButton(frame: .zero)
        eyeButton.bezelStyle = .inline
        eyeButton.isBordered = false
        eyeButton.imagePosition = .imageOnly
        eyeButton.imageScaling = .scaleProportionallyUpOrDown

        // Name label
        nameLabel = NSTextField(labelWithString: "")
        nameLabel.font = DS.Typography.label
        nameLabel.textColor = DS.Colors.foreground
        nameLabel.lineBreakMode = .byTruncatingTail

        // Type icon
        typeIcon = NSImageView()
        typeIcon.imageScaling = .scaleProportionallyUpOrDown

        super.init(frame: NSRect(x: 0, y: 0, width: 360, height: Self.rowHeight))

        addSubview(starButton)
        addSubview(eyeButton)
        addSubview(nameLabel)
        addSubview(typeIcon)

        starButton.target = self
        starButton.action = #selector(toggleFavourite)
        eyeButton.target = self
        eyeButton.action = #selector(toggleVisibility)

        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        switch itemType {
        case .scene(let scene):
            nameLabel.stringValue = scene.name
            typeIcon.image = inferSceneIcon(for: scene)
            typeIcon.contentTintColor = DS.Colors.mutedForeground

        case .service(let service):
            nameLabel.stringValue = service.name
            typeIcon.image = iconForServiceType(service.serviceType)
            typeIcon.contentTintColor = DS.Colors.mutedForeground
        }

        updateStarButton()
        updateEyeButton()
    }

    private func updateStarButton() {
        let symbolName = isFavourite ? "star.fill" : "star"
        starButton.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        starButton.contentTintColor = isFavourite ? DS.Colors.warning : DS.Colors.mutedForeground
    }

    private func updateEyeButton() {
        let symbolName = isItemHidden ? "eye.slash" : "eye"
        eyeButton.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        eyeButton.contentTintColor = isItemHidden ? DS.Colors.mutedForeground : DS.Colors.foreground
    }

    @objc private func toggleFavourite() {
        isFavourite.toggle()
        updateStarButton()
        onFavouriteToggled?()
    }

    @objc private func toggleVisibility() {
        isItemHidden.toggle()
        updateEyeButton()
        onVisibilityToggled?()
    }

    override func layout() {
        super.layout()

        let buttonSize: CGFloat = 20
        let iconSize: CGFloat = 16
        let spacing: CGFloat = 8
        var x: CGFloat = 0

        // Star button
        starButton.frame = NSRect(
            x: x,
            y: (bounds.height - buttonSize) / 2,
            width: buttonSize,
            height: buttonSize
        )
        x += buttonSize + spacing

        // Eye button (for both scenes and services)
        eyeButton.frame = NSRect(
            x: x,
            y: (bounds.height - buttonSize) / 2,
            width: buttonSize,
            height: buttonSize
        )
        x += buttonSize + spacing

        // Type icon (at the end)
        let iconX = bounds.width - iconSize
        typeIcon.frame = NSRect(
            x: iconX,
            y: (bounds.height - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )

        // Name label (fills remaining space)
        let labelWidth = iconX - x - spacing
        nameLabel.frame = NSRect(
            x: x,
            y: (bounds.height - 17) / 2,
            width: max(0, labelWidth),
            height: 17
        )
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: Self.rowHeight)
    }

    // MARK: - Icon helpers

    private func iconForServiceType(_ type: String) -> NSImage? {
        switch type {
        case ServiceTypes.lightbulb:
            return NSImage(systemSymbolName: "lightbulb", accessibilityDescription: nil)
        case ServiceTypes.switch, ServiceTypes.outlet:
            return NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        case ServiceTypes.thermostat:
            return NSImage(systemSymbolName: "thermometer", accessibilityDescription: nil)
        case ServiceTypes.heaterCooler:
            return NSImage(systemSymbolName: "air.conditioner.horizontal", accessibilityDescription: nil)
        case ServiceTypes.lock:
            return NSImage(systemSymbolName: "lock", accessibilityDescription: nil)
        case ServiceTypes.windowCovering:
            return NSImage(systemSymbolName: "blinds.horizontal.closed", accessibilityDescription: nil)
        case ServiceTypes.fan:
            return NSImage(systemSymbolName: "fan", accessibilityDescription: nil)
        case ServiceTypes.garageDoorOpener:
            return NSImage(systemSymbolName: "door.garage.closed", accessibilityDescription: nil)
        case ServiceTypes.contactSensor:
            return NSImage(systemSymbolName: "door.left.hand.closed", accessibilityDescription: nil)
        default:
            return NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: nil)
        }
    }

    private func inferSceneIcon(for scene: SceneData) -> NSImage? {
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
        if name.contains("away") || name.contains("leave") || name.contains("depart") || name.contains("goodbye") {
            return NSImage(systemSymbolName: "figure.walk", accessibilityDescription: nil)
        }
        if name.contains("home") || name.contains("arrive") || name.contains("welcome") {
            return NSImage(systemSymbolName: "house.fill", accessibilityDescription: nil)
        }
        if name.contains("off") || name.contains("all off") {
            return NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        }
        if name.contains("on") || name.contains("all on") {
            return NSImage(systemSymbolName: "lightbulb.fill", accessibilityDescription: nil)
        }

        return NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
    }
}
