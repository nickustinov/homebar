//
//  ProSettingsView.swift
//  macOSBridge
//
//  Settings view for Itsyhome Pro features with sidebar navigation
//

import AppKit
import StoreKit
import Combine

class ProSettingsView: NSView {

    enum Section: String, CaseIterable {
        case pro = "Pro"
        case deeplinks = "Deeplinks"
        case groups = "Device Groups"
        case streamDeck = "Stream Deck"
        case icloud = "iCloud Sync"
        case webhooks = "Webhooks"
        case cli = "CLI"

        var icon: String {
            switch self {
            case .pro: return "star.fill"
            case .deeplinks: return "link"
            case .groups: return "square.stack.3d.up"
            case .streamDeck: return "keyboard"
            case .icloud: return "icloud"
            case .webhooks: return "network"
            case .cli: return "terminal"
            }
        }
    }

    private var cancellables = Set<AnyCancellable>()
    private var selectedSection: Section = .pro
    private var sidebarButtons: [Section: NSButton] = [:]

    // Layout
    private let sidebarWidth: CGFloat = 140
    private let sidebar = NSView()
    private let contentArea = NSView()
    private let divider = NSBox()

    // Content views (lazily created)
    private var proContentView: ProContentView?
    private var deeplinksContentView: DeeplinksContentView?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupSidebar()
        setupContentArea()
        selectSection(.pro)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSidebar() {
        sidebar.wantsLayer = true
        addSubview(sidebar)

        divider.boxType = .separator
        addSubview(divider)

        var yOffset: CGFloat = 8

        for section in Section.allCases {
            let button = createSidebarButton(for: section)
            sidebar.addSubview(button)
            sidebarButtons[section] = button
            yOffset += 28
        }
    }

    private func createSidebarButton(for section: Section) -> NSButton {
        let button = NSButton()
        button.title = section.rawValue
        button.image = NSImage(systemSymbolName: section.icon, accessibilityDescription: section.rawValue)
        button.imagePosition = .imageLeading
        button.alignment = .left
        button.bezelStyle = .recessed
        button.setButtonType(.pushOnPushOff)
        button.isBordered = false
        button.font = .systemFont(ofSize: 12)
        button.contentTintColor = .labelColor
        button.target = self
        button.action = #selector(sidebarButtonClicked(_:))
        button.tag = Section.allCases.firstIndex(of: section) ?? 0
        return button
    }

    private func setupContentArea() {
        contentArea.wantsLayer = true
        addSubview(contentArea)
    }

    override func layout() {
        super.layout()

        // Sidebar
        sidebar.frame = NSRect(x: 0, y: 0, width: sidebarWidth, height: bounds.height)

        // Divider
        divider.frame = NSRect(x: sidebarWidth, y: 0, width: 1, height: bounds.height)

        // Sidebar buttons
        var y = bounds.height - 12
        for section in Section.allCases {
            if let button = sidebarButtons[section] {
                y -= 26
                button.frame = NSRect(x: 8, y: y, width: sidebarWidth - 16, height: 24)
            }
        }

        // Content area
        let contentX = sidebarWidth + 1
        contentArea.frame = NSRect(x: contentX, y: 0, width: bounds.width - contentX, height: bounds.height)

        // Layout current content view
        for subview in contentArea.subviews {
            subview.frame = contentArea.bounds
        }
    }

    @objc private func sidebarButtonClicked(_ sender: NSButton) {
        let section = Section.allCases[sender.tag]
        selectSection(section)
    }

    private func selectSection(_ section: Section) {
        selectedSection = section

        // Update button states
        for (sec, button) in sidebarButtons {
            button.state = sec == section ? .on : .off
            if sec == section {
                button.contentTintColor = .controlAccentColor
            } else {
                button.contentTintColor = .labelColor
            }
        }

        // Show content
        contentArea.subviews.forEach { $0.removeFromSuperview() }

        let contentView: NSView
        switch section {
        case .pro:
            if proContentView == nil {
                proContentView = ProContentView()
            }
            contentView = proContentView!
        case .deeplinks:
            if deeplinksContentView == nil {
                deeplinksContentView = DeeplinksContentView()
            }
            contentView = deeplinksContentView!
        default:
            contentView = createComingSoonView(for: section)
        }

        contentArea.addSubview(contentView)
        contentView.frame = contentArea.bounds
        needsLayout = true
    }

    private func createComingSoonView(for section: Section) -> NSView {
        let view = NSView()

        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: section.icon, accessibilityDescription: nil)
        icon.contentTintColor = .tertiaryLabelColor
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 32, weight: .light)
        view.addSubview(icon)

        let title = NSTextField(labelWithString: section.rawValue)
        title.font = .systemFont(ofSize: 16, weight: .semibold)
        title.textColor = .labelColor
        title.alignment = .center
        view.addSubview(title)

        let subtitle = NSTextField(labelWithString: "Coming soon")
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .tertiaryLabelColor
        subtitle.alignment = .center
        view.addSubview(subtitle)

        // Layout in viewDidLayout
        icon.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            icon.widthAnchor.constraint(equalToConstant: 40),
            icon.heightAnchor.constraint(equalToConstant: 40),

            title.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 12),

            subtitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
        ])

        return view
    }
}

// MARK: - Pro Content View (Purchase/Status)

private class ProContentView: NSView {

    private var cancellables = Set<AnyCancellable>()

    private let proBadge = NSTextField(labelWithString: "PRO UNLOCKED")
    private let thankYouLabel = NSTextField(labelWithString: "Thank you for supporting Itsyhome!")

    private let titleLabel = NSTextField(labelWithString: "Itsyhome Pro")
    private let subtitleLabel = NSTextField(labelWithString: "Unlock powerful automation features")
    private let yearlyButton = NSButton(title: "Loading...", target: nil, action: nil)
    private let lifetimeButton = NSButton(title: "Loading...", target: nil, action: nil)
    private let restoreButton = NSButton(title: "Restore Purchases", target: nil, action: nil)

    private let featuresHeader = NSTextField(labelWithString: "PRO FEATURES")
    private var featureLabels: [NSTextField] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
        setupBindings()
        updateVisibility()
        updateButtonTitles()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Pro badge
        proBadge.font = .systemFont(ofSize: 11, weight: .bold)
        proBadge.textColor = .white
        proBadge.backgroundColor = .systemGreen
        proBadge.drawsBackground = true
        proBadge.alignment = .center
        proBadge.wantsLayer = true
        proBadge.layer?.cornerRadius = 4
        addSubview(proBadge)

        thankYouLabel.font = .systemFont(ofSize: 13)
        thankYouLabel.textColor = .secondaryLabelColor
        thankYouLabel.alignment = .center
        addSubview(thankYouLabel)

        // Purchase section
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.alignment = .center
        addSubview(titleLabel)

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.alignment = .center
        addSubview(subtitleLabel)

        yearlyButton.bezelStyle = .rounded
        yearlyButton.target = self
        yearlyButton.action = #selector(yearlyTapped)
        addSubview(yearlyButton)

        lifetimeButton.bezelStyle = .rounded
        lifetimeButton.target = self
        lifetimeButton.action = #selector(lifetimeTapped)
        addSubview(lifetimeButton)

        restoreButton.bezelStyle = .inline
        restoreButton.font = .systemFont(ofSize: 11)
        restoreButton.target = self
        restoreButton.action = #selector(restoreTapped)
        addSubview(restoreButton)

        // Features list
        featuresHeader.font = .systemFont(ofSize: 11, weight: .semibold)
        featuresHeader.textColor = .secondaryLabelColor
        addSubview(featuresHeader)

        let features = [
            ("link", "Deeplinks – Control devices via URL schemes"),
            ("square.stack.3d.up", "Device Groups – Control multiple devices at once"),
            ("keyboard", "Stream Deck – Elgato Stream Deck integration"),
            ("icloud", "iCloud Sync – Sync settings across Macs"),
            ("network", "Webhooks – HTTP endpoints for IFTTT, Zapier"),
            ("terminal", "CLI – Command-line tool for terminal users"),
        ]

        for (icon, text) in features {
            let label = NSTextField(labelWithString: text)
            label.font = .systemFont(ofSize: 12)
            label.textColor = .labelColor

            let attachment = NSTextAttachment()
            attachment.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)?
                .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 11, weight: .regular))

            let attrString = NSMutableAttributedString(attachment: attachment)
            attrString.append(NSAttributedString(string: "  " + text))
            label.attributedStringValue = attrString

            addSubview(label)
            featureLabels.append(label)
        }
    }

    override func layout() {
        super.layout()

        let padding: CGFloat = 20
        let contentWidth = bounds.width - padding * 2
        var y = bounds.height - padding

        let isPro = ProStatusCache.shared.isPro

        if isPro {
            // Pro badge centered
            let badgeWidth: CGFloat = 120
            y -= 22
            proBadge.frame = NSRect(x: (bounds.width - badgeWidth) / 2, y: y, width: badgeWidth, height: 22)

            thankYouLabel.sizeToFit()
            y -= 8 + thankYouLabel.frame.height
            thankYouLabel.frame = NSRect(x: padding, y: y, width: contentWidth, height: thankYouLabel.frame.height)

            y -= 24
        } else {
            // Title
            titleLabel.sizeToFit()
            y -= titleLabel.frame.height
            titleLabel.frame = NSRect(x: padding, y: y, width: contentWidth, height: titleLabel.frame.height)

            // Subtitle
            subtitleLabel.sizeToFit()
            y -= 4 + subtitleLabel.frame.height
            subtitleLabel.frame = NSRect(x: padding, y: y, width: contentWidth, height: subtitleLabel.frame.height)

            // Buttons
            let buttonWidth: CGFloat = 120
            let buttonHeight: CGFloat = 32
            let buttonSpacing: CGFloat = 12
            let buttonsX = (bounds.width - buttonWidth * 2 - buttonSpacing) / 2

            y -= 16 + buttonHeight
            yearlyButton.frame = NSRect(x: buttonsX, y: y, width: buttonWidth, height: buttonHeight)
            lifetimeButton.frame = NSRect(x: buttonsX + buttonWidth + buttonSpacing, y: y, width: buttonWidth, height: buttonHeight)

            // Restore
            restoreButton.sizeToFit()
            y -= 8 + restoreButton.frame.height
            restoreButton.frame = NSRect(x: (bounds.width - restoreButton.frame.width) / 2, y: y, width: restoreButton.frame.width, height: restoreButton.frame.height)

            y -= 24
        }

        // Features header
        featuresHeader.sizeToFit()
        y -= featuresHeader.frame.height
        featuresHeader.frame = NSRect(x: padding, y: y, width: contentWidth, height: featuresHeader.frame.height)

        y -= 8

        // Feature labels
        for label in featureLabels {
            label.sizeToFit()
            y -= label.frame.height + 6
            label.frame = NSRect(x: padding, y: y, width: contentWidth, height: label.frame.height)
        }
    }

    private func updateVisibility() {
        let isPro = ProStatusCache.shared.isPro

        proBadge.isHidden = !isPro
        thankYouLabel.isHidden = !isPro

        titleLabel.isHidden = isPro
        subtitleLabel.isHidden = isPro
        yearlyButton.isHidden = isPro
        lifetimeButton.isHidden = isPro
        restoreButton.isHidden = isPro
    }

    private func updateButtonTitles() {
        if let yearly = ProManager.shared.yearlyProduct {
            yearlyButton.title = "\(yearly.displayPrice)/year"
        }
        if let lifetime = ProManager.shared.lifetimeProduct {
            lifetimeButton.title = "\(lifetime.displayPrice) lifetime"
        }
    }

    private func setupBindings() {
        ProManager.shared.$isPro
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateVisibility()
                self?.needsLayout = true
            }
            .store(in: &cancellables)

        ProManager.shared.$products
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateButtonTitles()
            }
            .store(in: &cancellables)
    }

    @objc private func yearlyTapped() {
        guard let product = ProManager.shared.yearlyProduct else { return }
        Task {
            do { _ = try await ProManager.shared.purchase(product) }
            catch { showError(error) }
        }
    }

    @objc private func lifetimeTapped() {
        guard let product = ProManager.shared.lifetimeProduct else { return }
        Task {
            do { _ = try await ProManager.shared.purchase(product) }
            catch { showError(error) }
        }
    }

    @objc private func restoreTapped() {
        Task { await ProManager.shared.restore() }
    }

    private func showError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Purchase failed"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}

// MARK: - Deeplinks Content View

private class DeeplinksContentView: NSView {

    private let descriptionLabel: NSTextField
    private let formatHeader: NSTextField
    private let formatCode: NSTextField
    private let actionsHeader: NSTextField
    private let actionsLabel: NSTextField
    private let tipLabel: NSTextField
    private var exampleRows: [(label: NSTextField, url: NSTextField, button: NSButton)] = []

    override init(frame frameRect: NSRect) {
        descriptionLabel = NSTextField(wrappingLabelWithString: "Control your HomeKit devices from Shortcuts, Alfred, Raycast, Stream Deck, and other automation tools using URL schemes.")
        descriptionLabel.font = .systemFont(ofSize: 12)
        descriptionLabel.textColor = .labelColor

        formatHeader = NSTextField(labelWithString: "URL format")
        formatHeader.font = .systemFont(ofSize: 12, weight: .semibold)

        formatCode = NSTextField(labelWithString: "itsyhome://<action>/<Room>/<Device>")
        formatCode.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        formatCode.textColor = .secondaryLabelColor
        formatCode.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.3)
        formatCode.drawsBackground = true
        formatCode.alignment = .center
        formatCode.wantsLayer = true
        formatCode.layer?.cornerRadius = 4

        actionsHeader = NSTextField(labelWithString: "Supported actions")
        actionsHeader.font = .systemFont(ofSize: 12, weight: .semibold)

        actionsLabel = NSTextField(wrappingLabelWithString: "toggle, on, off, brightness, position, temp, color, scene, lock, unlock, open, close")
        actionsLabel.font = .systemFont(ofSize: 11)
        actionsLabel.textColor = .secondaryLabelColor

        tipLabel = NSTextField(labelWithString: "Tip: Use %20 for spaces in room or device names.")
        tipLabel.font = .systemFont(ofSize: 11)
        tipLabel.textColor = .tertiaryLabelColor

        super.init(frame: frameRect)

        addSubview(descriptionLabel)
        addSubview(formatHeader)
        addSubview(formatCode)
        addSubview(actionsHeader)
        addSubview(actionsLabel)
        addSubview(tipLabel)

        // Example rows
        let examples = [
            ("Toggle device", "itsyhome://toggle/Office/Lamp"),
            ("Turn on", "itsyhome://on/Kitchen/Light"),
            ("Set brightness", "itsyhome://brightness/50/Bedroom/Lamp"),
            ("Run scene", "itsyhome://scene/Goodnight"),
        ]

        for (label, url) in examples {
            let labelField = NSTextField(labelWithString: label)
            labelField.font = .systemFont(ofSize: 11)
            labelField.textColor = .secondaryLabelColor

            let urlField = NSTextField(labelWithString: url)
            urlField.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
            urlField.textColor = .labelColor
            urlField.isSelectable = true

            let copyButton = NSButton(title: "Copy", target: self, action: #selector(copyURL(_:)))
            copyButton.bezelStyle = .inline
            copyButton.font = .systemFont(ofSize: 10)
            copyButton.toolTip = url

            addSubview(labelField)
            addSubview(urlField)
            addSubview(copyButton)

            exampleRows.append((labelField, urlField, copyButton))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()

        let padding: CGFloat = 16
        let contentWidth = bounds.width - padding * 2
        var y = bounds.height - padding

        // Description
        let descHeight: CGFloat = 36
        y -= descHeight
        descriptionLabel.frame = NSRect(x: padding, y: y, width: contentWidth, height: descHeight)

        // Format header
        y -= 16
        formatHeader.sizeToFit()
        y -= formatHeader.frame.height
        formatHeader.frame = NSRect(x: padding, y: y, width: contentWidth, height: formatHeader.frame.height)

        // Format code
        y -= 6
        let codeHeight: CGFloat = 24
        y -= codeHeight
        formatCode.frame = NSRect(x: padding, y: y, width: contentWidth, height: codeHeight)

        // Examples
        y -= 16
        let labelWidth: CGFloat = 85
        let copyWidth: CGFloat = 44
        let rowHeight: CGFloat = 20

        for row in exampleRows {
            y -= rowHeight + 4
            row.label.frame = NSRect(x: padding, y: y, width: labelWidth, height: rowHeight)
            row.url.frame = NSRect(x: padding + labelWidth, y: y, width: contentWidth - labelWidth - copyWidth - 8, height: rowHeight)
            row.button.frame = NSRect(x: bounds.width - padding - copyWidth, y: y + 1, width: copyWidth, height: 18)
        }

        // Actions header
        y -= 16
        actionsHeader.sizeToFit()
        y -= actionsHeader.frame.height
        actionsHeader.frame = NSRect(x: padding, y: y, width: contentWidth, height: actionsHeader.frame.height)

        // Actions list
        y -= 4
        let actionsHeight: CGFloat = 32
        y -= actionsHeight
        actionsLabel.frame = NSRect(x: padding, y: y, width: contentWidth, height: actionsHeight)

        // Tip
        y -= 8
        tipLabel.sizeToFit()
        y -= tipLabel.frame.height
        tipLabel.frame = NSRect(x: padding, y: y, width: contentWidth, height: tipLabel.frame.height)
    }

    @objc private func copyURL(_ sender: NSButton) {
        guard let url = sender.toolTip else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)

        let originalTitle = sender.title
        sender.title = "Copied!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            sender.title = originalTitle
        }
    }
}
