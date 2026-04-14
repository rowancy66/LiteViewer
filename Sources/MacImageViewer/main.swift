import AppKit
import SwiftUI
import MacImageViewerCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let appState = ImageViewerState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildMenu()

        let contentView = ContentView(state: appState)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacImageViewer"
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        self.window = window

        NSApp.activate(ignoringOtherApps: true)

        if let firstPath = CommandLine.arguments.dropFirst().first {
            appState.open(URL(fileURLWithPath: firstPath))
        }
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        guard let firstFile = filenames.first else {
            sender.reply(toOpenOrPrint: .failure)
            return
        }

        appState.open(URL(fileURLWithPath: firstFile))
        sender.reply(toOpenOrPrint: .success)
    }

    private func buildMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "退出 MacImageViewer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "文件")
        let openItem = NSMenuItem(title: "打开图片...", action: #selector(openImageFromMenu), keyEquivalent: "o")
        openItem.target = self
        fileMenu.addItem(openItem)
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func openImageFromMenu() {
        appState.openImage()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
