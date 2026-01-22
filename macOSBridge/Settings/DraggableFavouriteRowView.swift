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

    private let cardBackground: NSView
    private let dragHandle: DragHandleView
    private let starButton: NSButton
    private let typeIcon: NSImageView
    private let nameLabel: NSTextField

    private let itemId: String
    var onRemove: (() -> Void)?

    init(item: FavouriteItem) {
        self.itemId = item.id

        // Card background
        cardBackground = NSView()
        cardBackground.wantsLayer = true
        cardBackground.layer?.backgroundColor = NSColor.quaternarySystemFill.cgColor
        cardBackground.layer?.cornerRadius = FavouritesRowLayout.cardCornerRadius

        // Drag handle (6 dots)
        dragHandle = DragHandleView()

        // Star button
        starButton = NSButton(frame: .zero)
        starButton.bezelStyle = .inline
        starButton.isBordered = false
        starButton.imagePosition = .imageOnly
        starButton.imageScaling = .scaleProportionallyUpOrDown
        starButton.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)
        starButton.contentTintColor = .systemYellow

        // Type icon
        typeIcon = NSImageView()
        typeIcon.imageScaling = .scaleProportionallyUpOrDown
        typeIcon.contentTintColor = .secondaryLabelColor

        // Name label
        nameLabel = NSTextField(labelWithString: item.name)
        nameLabel.font = .systemFont(ofSize: 13)
        nameLabel.textColor = .labelColor
        nameLabel.lineBreakMode = .byTruncatingTail

        super.init(frame: NSRect(x: 0, y: 0, width: 360, height: FavouritesRowLayout.rowHeight))

        addSubview(cardBackground)
        addSubview(dragHandle)
        addSubview(starButton)
        addSubview(typeIcon)
        addSubview(nameLabel)

        starButton.target = self
        starButton.action = #selector(starClicked)

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
        let cardPadding = FavouritesRowLayout.cardPadding
        let cardHeight = FavouritesRowLayout.cardHeight
        let dragHandleWidth: CGFloat = 12

        // Card background
        cardBackground.frame = NSRect(
            x: 0,
            y: cardPadding,
            width: bounds.width,
            height: cardHeight
        )

        let cardY = cardPadding
        var x: CGFloat = 4  // Reduced padding so star aligns with other rows

        // Drag handle
        dragHandle.frame = NSRect(
            x: x,
            y: cardY + (cardHeight - 16) / 2,
            width: dragHandleWidth,
            height: 16
        )
        x += dragHandleWidth + spacing

        // Star button
        starButton.frame = NSRect(
            x: x,
            y: cardY + (cardHeight - buttonSize) / 2,
            width: buttonSize,
            height: buttonSize
        )
        x += buttonSize + spacing

        // Type icon
        typeIcon.frame = NSRect(
            x: x,
            y: cardY + (cardHeight - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )
        x += iconSize + spacing

        // Name label (fills remaining space)
        let rightPadding: CGFloat = 12
        nameLabel.frame = NSRect(
            x: x,
            y: cardY + (cardHeight - FavouritesRowLayout.labelHeight) / 2,
            width: max(0, bounds.width - x - rightPadding),
            height: FavouritesRowLayout.labelHeight
        )
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: FavouritesRowLayout.rowHeight)
    }
}

// MARK: - Drag handle view (6 dots)

class DragHandleView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let dotSize: CGFloat = 2
        let hSpacing: CGFloat = 2
        let vSpacing: CGFloat = 2
        let totalWidth = dotSize * 2 + hSpacing
        let totalHeight = dotSize * 3 + vSpacing * 2

        let startX = (bounds.width - totalWidth) / 2
        let startY = (bounds.height - totalHeight) / 2

        NSColor.tertiaryLabelColor.setFill()

        for col in 0..<2 {
            for row in 0..<3 {
                let x = startX + CGFloat(col) * (dotSize + hSpacing)
                let y = startY + CGFloat(row) * (dotSize + vSpacing)
                let dotRect = NSRect(x: x, y: y, width: dotSize, height: dotSize)
                let path = NSBezierPath(ovalIn: dotRect)
                path.fill()
            }
        }
    }
}
