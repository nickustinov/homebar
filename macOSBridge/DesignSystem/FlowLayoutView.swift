//
//  FlowLayoutView.swift
//  macOSBridge
//
//  A simple flow layout view that wraps subviews to the next line when they don't fit.
//

import AppKit

class FlowLayoutView: NSView {
    var spacing: CGFloat = 4
    var lineSpacing: CGFloat = 4

    private var arrangedSubviews: [NSView] = []

    func addArrangedSubview(_ view: NSView) {
        arrangedSubviews.append(view)
        addSubview(view)
        needsLayout = true
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: NSSize {
        let width = superview?.bounds.width ?? bounds.width
        guard width > 0 else { return NSSize(width: NSView.noIntrinsicMetric, height: 24) }
        let height = computeHeight(forWidth: width)
        return NSSize(width: NSView.noIntrinsicMetric, height: height)
    }

    func computeHeight(forWidth availableWidth: CGFloat) -> CGFloat {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for view in arrangedSubviews {
            let size = view.fittingSize
            if x > 0 && x + size.width > availableWidth {
                y += lineHeight + lineSpacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return y + lineHeight
    }

    override func layout() {
        super.layout()
        let availableWidth = bounds.width
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for view in arrangedSubviews {
            let size = view.fittingSize
            if x > 0 && x + size.width > availableWidth {
                y += lineHeight + lineSpacing
                x = 0
                lineHeight = 0
            }
            view.frame = NSRect(x: x, y: y, width: size.width, height: size.height)
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
