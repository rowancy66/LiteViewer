import AppKit
import SwiftUI

enum ViewerWindowFactory {
    static func makeWindow<Content: View>(rootView: Content) -> NSWindow {
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1240, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "LiteViewer"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false
        window.backgroundColor = NSColor(
            calibratedRed: 0.95,
            green: 0.94,
            blue: 0.90,
            alpha: 1
        )
        window.toolbarStyle = .unified
        window.contentMinSize = NSSize(width: 960, height: 620)
        window.center()
        window.contentViewController = hostingController
        return window
    }
}
