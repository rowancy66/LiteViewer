import AppKit
import SwiftUI
import MacImageViewerCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let appState = ImageViewerState()
    private var keyboardMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildMenu()
        installKeyboardMonitor()

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
        }
        return true
    }

    deinit {
        if let keyboardMonitor {
            NSEvent.removeMonitor(keyboardMonitor)
        }
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

        let navigateMenuItem = NSMenuItem()
        let navigateMenu = NSMenu(title: "浏览")
        let previousItem = NSMenuItem(title: "上一张", action: #selector(previousImageFromMenu), keyEquivalent: "")
        previousItem.target = self
        navigateMenu.addItem(previousItem)
        let nextItem = NSMenuItem(title: "下一张", action: #selector(nextImageFromMenu), keyEquivalent: "")
        nextItem.target = self
        navigateMenu.addItem(nextItem)
        navigateMenuItem.submenu = navigateMenu
        mainMenu.addItem(navigateMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private func installKeyboardMonitor() {
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard
                let self,
                NSApp.modalWindow == nil,
                event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty
            else {
                return event
            }

            switch event.keyCode {
            case 123:
                self.appState.previousImage()
                return nil
            case 124:
                self.appState.nextImage()
                return nil
            case 53:
                self.appState.fitToWindow()
                return nil
            default:
                return event
            }
        }
    }

    @objc private func openImageFromMenu() {
        appState.openImage()
    }

    @objc private func previousImageFromMenu() {
        appState.previousImage()
    }

    @objc private func nextImageFromMenu() {
        appState.nextImage()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
