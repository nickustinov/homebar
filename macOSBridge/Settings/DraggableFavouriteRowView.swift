//
//  DraggableFavouriteRowView.swift
//  macOSBridge
//
//  Draggable row view for favourites reordering
//

import AppKit

// MARK: - Favourite item for drag/drop

struct FavouriteItem {
    enum Kind {
        case scene(SceneData)
        case service(ServiceData)
    }
    let kind: Kind
    let id: String
    let name: String
}

// MARK: - Pasteboard type for drag/drop

extension NSPasteboard.PasteboardType {
    static let favouriteItem = NSPasteboard.PasteboardType("com.itsyhome.favouriteItem")
}

// MARK: - Draggable favourite row

class DraggableFavouriteRowView: NSView {

    private let starButton: NSButton
    private let dragHandle: NSImageView
    private let typeIcon: NSImageView
    private let nameLabel: NSTextField
    private let shortcutButton: ShortcutButton

    private let itemId: String
    var onRemove: (() -> Void)?
    var onShortcutChanged: ((PreferencesManager.ShortcutData?) -> Void)?

    init(item: FavouriteItem) {
        self.itemId = item.id

        // Star button
        starButton = NSButton(frame: .zero)
        starButton.bezelStyle = .inline
        starButton.isBordered = false
        starButton.imagePosition = .imageOnly
        starButton.imageScaling = .scaleProportionallyUpOrDown
        starButton.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)
        starButton.contentTintColor = DS.Colors.warning

        // Drag handle
        dragHandle = NSImageView()
        dragHandle.imageScaling = .scaleProportionallyUpOrDown
        dragHandle.image = NSImage(systemSymbolName: "line.3.horizontal", accessibilityDescription: nil)
        dragHandle.contentTintColor = DS.Colors.mutedForeground

        // Type icon
        typeIcon = NSImageView()
        typeIcon.imageScaling = .scaleProportionallyUpOrDown
        typeIcon.contentTintColor = DS.Colors.mutedForeground

        // Name label
        nameLabel = NSTextField(labelWithString: item.name)
        nameLabel.font = DS.Typography.label
        nameLabel.textColor = DS.Colors.foreground
        nameLabel.lineBreakMode = .byTruncatingTail

        // Shortcut button
        shortcutButton = ShortcutButton(frame: .zero)
        shortcutButton.shortcut = PreferencesManager.shared.shortcut(for: item.id)

        super.init(frame: NSRect(x: 0, y: 0, width: 360, height: FavouritesRowLayout.rowHeight))

        addSubview(starButton)
        addSubview(dragHandle)
        addSubview(typeIcon)
        addSubview(nameLabel)
        addSubview(shortcutButton)

        starButton.target = self
        starButton.action = #selector(starClicked)

        shortcutButton.onShortcutRecorded = { [weak self] shortcut in
            guard let self = self else { return }
            PreferencesManager.shared.setShortcut(shortcut, for: self.itemId)
            self.onShortcutChanged?(shortcut)
        }

        // Set type icon based on item
        switch item.kind {
        case .scene(let scene):
            typeIcon.image = SceneIconInference.icon(for: scene.name)
        case .service(let service):
            typeIcon.image = IconMapping.iconForServiceType(service.serviceType)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func starClicked() {
        onRemove?()
    }

    override func layout() {
        super.layout()

        let buttonSize = FavouritesRowLayout.buttonSize
        let iconSize = FavouritesRowLayout.iconSize
        let spacing = FavouritesRowLayout.spacing
        let rightPadding: CGFloat = 0
        var x: CGFloat = 0

        // Star button
        starButton.frame = NSRect(
            x: x,
            y: (bounds.height - buttonSize) / 2,
            width: buttonSize,
            height: buttonSize
        )
        x += buttonSize + spacing

        // Drag handle
        dragHandle.frame = NSRect(
            x: x,
            y: (bounds.height - buttonSize) / 2,
            width: buttonSize,
            height: buttonSize
        )
        x += buttonSize + spacing

        // Type icon on far right
        typeIcon.frame = NSRect(
            x: bounds.width - iconSize - rightPadding,
            y: (bounds.height - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )

        // Shortcut button to the left of type icon
        let shortcutWidth: CGFloat = 110
        let shortcutHeight: CGFloat = 20
        shortcutButton.frame = NSRect(
            x: bounds.width - iconSize - rightPadding - 16 - shortcutWidth,
            y: (bounds.height - shortcutHeight) / 2,
            width: shortcutWidth,
            height: shortcutHeight
        )

        // Name label (fills space between drag handle and shortcut button)
        nameLabel.frame = NSRect(
            x: x,
            y: (bounds.height - FavouritesRowLayout.labelHeight) / 2,
            width: max(0, bounds.width - x - shortcutWidth - iconSize - rightPadding - 24),
            height: FavouritesRowLayout.labelHeight
        )
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: FavouritesRowLayout.rowHeight)
    }
}
