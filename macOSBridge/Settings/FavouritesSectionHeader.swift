//
//  FavouritesSectionHeader.swift
//  macOSBridge
//
//  Section header view for favourites dialog
//

import AppKit

class FavouritesSectionHeader: NSView {

    private let titleLabel: NSTextField

    private static let headerHeight: CGFloat = 32

    init(title: String, icon: NSImage?) {
        titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = DS.Typography.bodyMedium
        titleLabel.textColor = DS.Colors.foreground

        super.init(frame: NSRect(x: 0, y: 0, width: 360, height: Self.headerHeight))

        addSubview(titleLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()

        // Align with row content (after star + eye buttons: 20 + 8 + 20 + 8 = 56)
        let leftPadding: CGFloat = 56

        titleLabel.frame = NSRect(
            x: leftPadding,
            y: (bounds.height - 17) / 2,
            width: bounds.width - leftPadding - 8,
            height: 17
        )
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: Self.headerHeight)
    }
}
