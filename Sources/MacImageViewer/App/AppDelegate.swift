import AppKit
import LiteViewerCore
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = ImageViewerState()
    private lazy var menuController = AppMenuController(state: appState)
    private lazy var keyboardMonitor = ViewerKeyboardMonitor(state: appState)
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        menuController.installMainMenu()
        keyboardMonitor.start()

        let contentView = ContentView(state: appState)
        let window = ViewerWindowFactory.makeWindow(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        self.window = window

        NSApp.activate(ignoringOtherApps: true)

        if let launchURL = ImageFileNavigator.launchFileURLs(from: CommandLine.arguments).first {
            appState.open(launchURL)
        }
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        guard let firstURL = ImageFileNavigator.fileURLsFromLaunchItems(filenames).first else {
            sender.reply(toOpenOrPrint: .failure)
            return
        }

        appState.open(firstURL)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        sender.reply(toOpenOrPrint: .success)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }
}
