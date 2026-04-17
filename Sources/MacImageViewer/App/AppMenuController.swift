import AppKit

final class AppMenuController: NSObject {
    private unowned let state: ImageViewerState

    init(state: ImageViewerState) {
        self.state = state
    }

    func installMainMenu() {
        NSApp.mainMenu = buildMainMenu()
    }

    private func buildMainMenu() -> NSMenu {
        let mainMenu = NSMenu()
        mainMenu.addItem(makeAppMenuItem())
        mainMenu.addItem(makeFileMenuItem())
        mainMenu.addItem(makeEditMenuItem())
        mainMenu.addItem(makeViewMenuItem())
        mainMenu.addItem(makeNavigateMenuItem())
        mainMenu.addItem(makeImageMenuItem())
        return mainMenu
    }

    private func makeAppMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu()
        menu.addItem(withTitle: "关于 LiteViewer", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出 LiteViewer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.submenu = menu
        return item
    }

    private func makeFileMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "文件")
        menu.addItem(makeItem(title: "打开图片...", action: #selector(openImage), keyEquivalent: "o"))
        menu.addItem(.separator())
        menu.addItem(makeItem(title: "在 Finder 中显示", action: #selector(revealInFinder), keyEquivalent: "r"))
        menu.addItem(makeItem(title: "移到废纸篓", action: #selector(deleteToTrash), keyEquivalent: "\u{8}"))
        item.submenu = menu
        return item
    }

    private func makeEditMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "编辑")
        menu.addItem(makeItem(title: "复制图片", action: #selector(copyImage), keyEquivalent: "c"))
        menu.addItem(makeItem(title: "粘贴到当前文件夹", action: #selector(pasteImage), keyEquivalent: "v"))
        menu.addItem(makeItem(title: "复制图片路径", action: #selector(copyImagePath), keyEquivalent: "l"))
        item.submenu = menu
        return item
    }

    private func makeViewMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "显示")
        menu.addItem(makeItem(title: "适合窗口", action: #selector(fitToWindow), keyEquivalent: "9"))
        menu.addItem(makeItem(title: "实际大小", action: #selector(actualSize), keyEquivalent: "0"))
        item.submenu = menu
        return item
    }

    private func makeNavigateMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "浏览")
        menu.addItem(makeItem(title: "上一张", action: #selector(previousImage), keyEquivalent: String(Character(UnicodeScalar(NSLeftArrowFunctionKey)!)), modifiers: []))
        menu.addItem(makeItem(title: "下一张", action: #selector(nextImage), keyEquivalent: String(Character(UnicodeScalar(NSRightArrowFunctionKey)!)), modifiers: []))
        item.submenu = menu
        return item
    }

    private func makeImageMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "图片")
        menu.addItem(makeItem(title: "向左旋转", action: #selector(rotateLeft), keyEquivalent: "["))
        menu.addItem(makeItem(title: "向右旋转", action: #selector(rotateRight), keyEquivalent: "]"))
        item.submenu = menu
        return item
    }

    private func makeItem(
        title: String,
        action: Selector,
        keyEquivalent: String,
        modifiers: NSEvent.ModifierFlags = .command
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        item.keyEquivalentModifierMask = modifiers
        return item
    }

    @objc private func openImage() {
        state.openImage()
    }

    @objc private func revealInFinder() {
        state.revealCurrentImageInFinder()
    }

    @objc private func deleteToTrash() {
        state.deleteCurrentImageToTrash()
    }

    @objc private func copyImage() {
        state.copyCurrentImage()
    }

    @objc private func pasteImage() {
        state.pasteImageIntoCurrentFolder()
    }

    @objc private func copyImagePath() {
        state.copyCurrentImagePath()
    }

    @objc private func fitToWindow() {
        state.fitToWindow()
    }

    @objc private func actualSize() {
        state.actualSize()
    }

    @objc private func previousImage() {
        state.previousImage()
    }

    @objc private func nextImage() {
        state.nextImage()
    }

    @objc private func rotateLeft() {
        state.rotateLeft()
    }

    @objc private func rotateRight() {
        state.rotateRight()
    }
}
