//
//  ColorPickerViews.swift
//  macOSBridge
//
//  Reusable color picker views for light controls
//

import AppKit

// MARK: - Clickable color circle

final class ClickableColorCircleView: NSView {
    var onClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    override func mouseUp(with event: NSEvent) {}
}

// MARK: - Color wheel picker (RGB)

class ColorWheelPickerView: NSView {
    private var hue: Double
    private var saturation: Double
    private let onColorChanged: (Double, Double, Bool) -> Void
    private let wheelSize: CGFloat = 120
    private let padding: CGFloat = 8

    init(hue: Double, saturation: Double, onColorChanged: @escaping (Double, Double, Bool) -> Void) {
        self.hue = hue
        self.saturation = saturation
        self.onColorChanged = onColorChanged
        let size = wheelSize + padding * 2
        super.init(frame: NSRect(x: 0, y: 0, width: size, height: size))
    }

    required init?(coder: NSCoder) { fatalError() }

    func updateColor(hue: Double, saturation: Double) {
        self.hue = hue
        self.saturation = saturation
        needsDisplay = true
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: wheelSize + padding * 2, height: wheelSize + padding * 2)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let radius = wheelSize / 2

        for angle in stride(from: 0, to: 360, by: 1) {
            let hueValue = CGFloat(angle) / 360.0
            NSColor(hue: hueValue, saturation: 1.0, brightness: 1.0, alpha: 1.0).setFill()
            let path = NSBezierPath()
            path.move(to: center)
            path.appendArc(withCenter: center, radius: radius, startAngle: CGFloat(angle) - 0.5, endAngle: CGFloat(angle) + 0.5, clockwise: false)
            path.close()
            path.fill()
        }

        let innerRadius = radius * 0.3
        NSColor.white.withAlphaComponent(0.8).setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - innerRadius, y: center.y - innerRadius, width: innerRadius * 2, height: innerRadius * 2)).fill()

        let indicatorAngle = CGFloat(hue) * .pi / 180.0
        let indicatorRadius = radius * (0.3 + 0.7 * CGFloat(saturation / 100.0))
        let indicatorX = center.x + cos(indicatorAngle) * indicatorRadius
        let indicatorY = center.y + sin(indicatorAngle) * indicatorRadius
        let indicatorRect = NSRect(x: indicatorX - 6, y: indicatorY - 6, width: 12, height: 12)
        NSColor.white.setStroke()
        NSColor.black.withAlphaComponent(0.3).setFill()
        let indicator = NSBezierPath(ovalIn: indicatorRect)
        indicator.fill()
        indicator.lineWidth = 2
        indicator.stroke()
    }

    override func mouseDown(with event: NSEvent) { handleMouse(event, isFinal: false) }
    override func mouseDragged(with event: NSEvent) { handleMouse(event, isFinal: false) }
    override func mouseUp(with event: NSEvent) { handleMouse(event, isFinal: true) }

    private func handleMouse(_ event: NSEvent, isFinal: Bool) {
        let point = convert(event.locationInWindow, from: nil)
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let radius = wheelSize / 2
        let dx = point.x - center.x
        let dy = point.y - center.y
        var angle = atan2(dy, dx) * 180.0 / .pi
        if angle < 0 { angle += 360 }
        hue = Double(angle)
        saturation = Double(min(sqrt(dx * dx + dy * dy) / radius, 1.0)) * 100.0
        onColorChanged(hue, saturation, isFinal)
        needsDisplay = true
    }
}

// MARK: - Color temperature picker

class ColorTempPickerView: NSView {
    private let onTempChanged: (Double) -> Void
    private var currentMired: Double
    private var selectedIndex: Int = -1
    private let presets: [(name: String, mired: Double)]
    private let circleSize: CGFloat = 32
    private let spacing: CGFloat = 8
    private let padding: CGFloat = 8

    init(currentMired: Double, minMired: Double, maxMired: Double, onTempChanged: @escaping (Double) -> Void) {
        self.currentMired = currentMired
        self.onTempChanged = onTempChanged

        // Generate 5 presets within the device's supported range (warm to cool)
        let range = maxMired - minMired
        self.presets = [
            ("Warm", maxMired),
            ("Soft", maxMired - range * 0.25),
            ("Neutral", minMired + range * 0.5),
            ("Bright", minMired + range * 0.25),
            ("Cool", minMired)
        ]

        self.selectedIndex = -1
        let width = padding * 2 + CGFloat(presets.count) * circleSize + CGFloat(presets.count - 1) * spacing
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: padding * 2 + circleSize))

        // Find closest preset to current value
        self.selectedIndex = presets.enumerated().min(by: { abs($0.1.mired - currentMired) < abs($1.1.mired - currentMired) })?.0 ?? -1
    }

    required init?(coder: NSCoder) { fatalError() }

    func updateMired(_ mired: Double) {
        currentMired = mired
        selectedIndex = presets.firstIndex { abs(mired - $0.mired) < 25 } ?? -1
        needsDisplay = true
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: padding * 2 + CGFloat(presets.count) * circleSize + CGFloat(presets.count - 1) * spacing, height: padding * 2 + circleSize)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        for (index, preset) in presets.enumerated() {
            let x = padding + CGFloat(index) * (circleSize + spacing)
            let rect = NSRect(x: x, y: padding, width: circleSize, height: circleSize)
            ColorConversion.miredToColor(preset.mired).setFill()
            NSBezierPath(ovalIn: rect).fill()
            if index == selectedIndex {
                NSColor.white.setStroke()
                let ring = NSBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
                ring.lineWidth = 3
                ring.stroke()
            }
        }
    }

    override func mouseDown(with event: NSEvent) { handleMouse(event) }
    override func mouseUp(with event: NSEvent) { handleMouse(event) }

    private func handleMouse(_ event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        for (index, preset) in presets.enumerated() {
            let x = padding + CGFloat(index) * (circleSize + spacing)
            if NSRect(x: x, y: padding, width: circleSize, height: circleSize).contains(point) {
                selectedIndex = index
                currentMired = preset.mired
                onTempChanged(currentMired)
                needsDisplay = true
                return
            }
        }
    }
}
