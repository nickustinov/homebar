//
//  SettingsSectionContainer.swift
//  macOSBridge
//
//  Reusable container for settings sections with updateable height
//

import AppKit

/// A container view for settings sections that supports dynamic height updates
/// and optional separator. Used to avoid recreating views on every data change.
class SettingsSectionContainer: NSView {

    private let contentView = NSView()
    private let separatorContainer = NSView()
    private let separator = NSBox()

    private var contentHeightConstraint: NSLayoutConstraint?
    private var separatorHeightConstraint: NSLayoutConstraint?

    var showsSeparator: Bool = true {
        didSet {
            separatorContainer.isHidden = !showsSeparator
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        // Separator container
        separatorContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorContainer)

        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separatorContainer.addSubview(separator)

        // Initial height constraints (will be updated)
        contentHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)
        separatorHeightConstraint = separatorContainer.heightAnchor.constraint(equalToConstant: 16)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentHeightConstraint!,

            separatorContainer.topAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorHeightConstraint!,

            separator.leadingAnchor.constraint(equalTo: separatorContainer.leadingAnchor, constant: 8),
            separator.trailingAnchor.constraint(equalTo: separatorContainer.trailingAnchor, constant: -8),
            separator.centerYAnchor.constraint(equalTo: separatorContainer.centerYAnchor)
        ])
    }

    /// Sets the content view, replacing any existing content
    func setContent(_ view: NSView) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    /// Updates the height of the content area
    func setContentHeight(_ height: CGFloat) {
        contentHeightConstraint?.constant = height
    }

    /// Access to the content view for adding subviews directly
    var content: NSView {
        contentView
    }
}

/// A simpler container without separator, just content with updateable height
class SimpleHeightContainer: NSView {

    private var heightConstraint: NSLayoutConstraint?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint?.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setHeight(_ height: CGFloat) {
        heightConstraint?.constant = height
    }
}
