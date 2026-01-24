//
//  CamerasSection.swift
//  macOSBridge
//
//  Cameras settings section
//

import AppKit
import Combine

class CamerasSection: SettingsCard {

    private let cameraSwitch = NSSwitch()
    private var cancellables = Set<AnyCancellable>()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupContent()
        loadPreferences()
        setupBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContent() {
        // Pro banner (only shown for non-Pro users)
        if !ProStatusCache.shared.isPro {
            let banner = SettingsCard.createProBanner()
            stackView.addArrangedSubview(banner)
            banner.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
            stackView.addArrangedSubview(createSpacer(height: 12))
        }

        // Camera toggle box
        let box = CardBoxView()
        box.translatesAutoresizingMaskIntoConstraints = false

        cameraSwitch.controlSize = .mini
        cameraSwitch.target = self
        cameraSwitch.action = #selector(cameraSwitchChanged)
        cameraSwitch.isEnabled = ProStatusCache.shared.isPro

        let row = createSettingRow(
            label: "Show cameras in menu bar",
            subtitle: "Display a camera icon in the menu bar to quickly view live camera feeds.",
            control: cameraSwitch
        )
        row.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: box.topAnchor, constant: 4),
            row.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -12),
            row.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -4)
        ])

        stackView.addArrangedSubview(box)
        box.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
    }

    private func createSettingRow(label: String, subtitle: String? = nil, control: NSView) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let labelStack = NSStackView()
        labelStack.orientation = .vertical
        labelStack.spacing = 2
        labelStack.alignment = .leading
        labelStack.translatesAutoresizingMaskIntoConstraints = false

        let labelField = createLabel(label, style: .body)
        labelStack.addArrangedSubview(labelField)

        if let subtitle = subtitle {
            let subtitleField = createLabel(subtitle, style: .caption)
            subtitleField.lineBreakMode = .byWordWrapping
            subtitleField.maximumNumberOfLines = 2
            labelStack.addArrangedSubview(subtitleField)
        }

        control.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(labelStack)
        container.addSubview(control)

        let rowHeight: CGFloat = subtitle != nil ? 56 : 36

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: rowHeight),
            labelStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            labelStack.trailingAnchor.constraint(lessThanOrEqualTo: control.leadingAnchor, constant: -16),
            control.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            control.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func createSpacer(height: CGFloat) -> NSView {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        return spacer
    }

    private func loadPreferences() {
        cameraSwitch.state = PreferencesManager.shared.camerasEnabled ? .on : .off
    }

    private func setupBindings() {
        ProManager.shared.$isPro
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPro in
                self?.cameraSwitch.isEnabled = isPro
            }
            .store(in: &cancellables)
    }

    @objc private func cameraSwitchChanged(_ sender: NSSwitch) {
        PreferencesManager.shared.camerasEnabled = sender.state == .on
    }
}
