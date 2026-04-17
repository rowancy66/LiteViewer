import AppKit
import SwiftUI

/// SwiftUI 负责布局，AppKit 负责更细的 macOS 输入事件和图片绘制。
struct ImageCanvasView: NSViewRepresentable {
    let image: NSImage
    let resetToken: UUID
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onScaleChanged: (CGFloat) -> Void

    func makeNSView(context: Context) -> CanvasNSView {
        let view = CanvasNSView()
        view.onPrevious = onPrevious
        view.onNext = onNext
        view.onScaleChanged = onScaleChanged
        return view
    }

    func updateNSView(_ nsView: CanvasNSView, context: Context) {
        nsView.image = image
        nsView.onPrevious = onPrevious
        nsView.onNext = onNext
        nsView.onScaleChanged = onScaleChanged

        if nsView.resetToken != resetToken {
            nsView.resetToken = resetToken
            nsView.resetToFit()
        }
    }
}

final class CanvasNSView: NSView {
    var image: NSImage? {
        didSet {
            needsDisplay = true
            resetToFit()
        }
    }

    var resetToken: UUID?
    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?
    var onScaleChanged: ((CGFloat) -> Void)?

    private var scale: CGFloat = 1
    private var offset: CGSize = .zero
    private var lastDragPoint: CGPoint?
    private var accumulatedHorizontalScroll: CGFloat = 0
    private var actualSizeObserver: NSObjectProtocol?

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }

    override func viewDidMoveToWindow() {
        window?.makeFirstResponder(self)

        if actualSizeObserver == nil {
            actualSizeObserver = NotificationCenter.default.addObserver(
                forName: .imageViewerActualSize,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.showActualSize()
            }
        }
    }

    deinit {
        if let actualSizeObserver {
            NotificationCenter.default.removeObserver(actualSizeObserver)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        dirtyRect.fill()

        guard let image else {
            return
        }

        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else {
            return
        }

        let fittedScale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let baseScale = min(max(fittedScale, 0.01), 1)
        let finalScale = baseScale * scale
        let drawSize = CGSize(width: imageSize.width * finalScale, height: imageSize.height * finalScale)
        let origin = CGPoint(
            x: (bounds.width - drawSize.width) / 2 + offset.width,
            y: (bounds.height - drawSize.height) / 2 + offset.height
        )

        image.draw(in: CGRect(origin: origin, size: drawSize))
    }

    func resetToFit() {
        scale = 1
        offset = .zero
        accumulatedHorizontalScroll = 0
        onScaleChanged?(1)
        needsDisplay = true
    }

    private func showActualSize() {
        guard let image, image.size.width > 0, image.size.height > 0 else {
            return
        }

        let fittedScale = min(bounds.width / image.size.width, bounds.height / image.size.height)
        let baseScale = min(max(fittedScale, 0.01), 1)
        scale = min(max(1 / baseScale, 0.1), 12)
        offset = .zero
        onScaleChanged?(scale)
        needsDisplay = true
    }

    override func magnify(with event: NSEvent) {
        scale = min(max(scale * (1 + event.magnification), 0.1), 12)
        onScaleChanged?(scale)
        needsDisplay = true
    }

    override func scrollWheel(with event: NSEvent) {
        let horizontal = event.scrollingDeltaX
        let vertical = event.scrollingDeltaY

        if abs(horizontal) > abs(vertical), abs(horizontal) > 0 {
            accumulatedHorizontalScroll += horizontal
            if accumulatedHorizontalScroll > 90 {
                accumulatedHorizontalScroll = 0
                onPrevious?()
            } else if accumulatedHorizontalScroll < -90 {
                accumulatedHorizontalScroll = 0
                onNext?()
            }
            return
        }

        super.scrollWheel(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        lastDragPoint = convert(event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let lastDragPoint {
            offset.width += point.x - lastDragPoint.x
            offset.height += point.y - lastDragPoint.y
            needsDisplay = true
        }
        lastDragPoint = point
    }

    override func mouseUp(with event: NSEvent) {
        lastDragPoint = nil
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123:
            onPrevious?()
        case 124:
            onNext?()
        case 53:
            resetToFit()
        default:
            super.keyDown(with: event)
        }
    }
}
