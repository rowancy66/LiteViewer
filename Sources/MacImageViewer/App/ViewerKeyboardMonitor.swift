import AppKit

final class ViewerKeyboardMonitor {
    private weak var state: ImageViewerState?
    private var monitor: Any?

    init(state: ImageViewerState) {
        self.state = state
    }

    func start() {
        guard monitor == nil else { return }

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event) ?? event
        }
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        guard
            let state,
            NSApp.modalWindow == nil,
            event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty
        else {
            return event
        }

        switch event.keyCode {
        case 123:
            state.previousImage()
            return nil
        case 124:
            state.nextImage()
            return nil
        case 53:
            state.fitToWindow()
            return nil
        default:
            return event
        }
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
