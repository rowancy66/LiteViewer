import AppKit
import Foundation
import LiteViewerCore
import UniformTypeIdentifiers

final class ImageViewerState: ObservableObject {
    @Published private(set) var navigator = ImageFileNavigator()
    @Published private(set) var image: NSImage?
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?
    @Published private(set) var scaleText = "适合窗口"
    @Published var resetToken = UUID()
    @Published var selectedSidebarURL: URL?

    let thumbnailService = ImageThumbnailService()

    private let imageLoadingService = ImageLoadingService()
    private let imageEditingService = ImageEditingService()

    var sidebarItems: [ViewerSidebarItem] {
        navigator.files.map { ViewerSidebarItem(url: $0) }
    }

    var currentFileName: String {
        navigator.currentURL?.lastPathComponent ?? "未打开图片"
    }

    var currentFolderName: String {
        navigator.currentURL?.deletingLastPathComponent().lastPathComponent ?? "未选择文件夹"
    }

    var sidebarSummaryText: String {
        guard !navigator.files.isEmpty else {
            return "打开一张图片后，会自动读取同文件夹里的其他照片。"
        }
        return "\(navigator.files.count) 张图片"
    }

    var statusText: String {
        guard let image else {
            return errorMessage ?? "点击“打开”选择一张图片"
        }

        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        return "\(navigator.displayPosition) · \(currentFileName) · \(width) × \(height) · \(scaleText)"
    }

    var canPasteImageFromPasteboard: Bool {
        NSPasteboard.general.canReadObject(forClasses: [NSImage.self], options: nil)
    }

    var hasOpenedImages: Bool {
        !navigator.files.isEmpty
    }

    var hasCurrentImage: Bool {
        image != nil
    }

    func openImage() {
        let panel = NSOpenPanel()
        panel.title = "选择图片"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = ImageFileNavigator.supportedExtensions.compactMap {
            UTType(filenameExtension: $0)
        }

        if panel.runModal() == .OK, let url = panel.url {
            open(url)
        }
    }

    func open(_ url: URL) {
        navigator = ImageFileNavigator.navigator(opening: url)
        selectedSidebarURL = navigator.currentURL?.standardizedFileURL
        actionMessage = nil
        imageLoadingService.reset()
        loadCurrentImageAndResetView()
    }

    func selectImage(_ url: URL?) {
        guard let url else { return }
        let normalizedURL = url.standardizedFileURL

        guard normalizedURL != navigator.currentURL?.standardizedFileURL else {
            selectedSidebarURL = normalizedURL
            return
        }

        guard let index = navigator.files.firstIndex(where: { $0.standardizedFileURL == normalizedURL }) else {
            return
        }

        navigator = ImageFileNavigator(files: navigator.files, currentIndex: index)
        selectedSidebarURL = normalizedURL
        actionMessage = nil
        imageLoadingService.invalidate()
        loadCurrentImageAndResetView()
    }

    func previousImage() {
        guard hasOpenedImages else { return }
        navigator = navigator.previous()
        selectedSidebarURL = navigator.currentURL?.standardizedFileURL
        actionMessage = nil
        imageLoadingService.invalidate()
        loadCurrentImageAndResetView()
    }

    func nextImage() {
        guard hasOpenedImages else { return }
        navigator = navigator.next()
        selectedSidebarURL = navigator.currentURL?.standardizedFileURL
        actionMessage = nil
        imageLoadingService.invalidate()
        loadCurrentImageAndResetView()
    }

    func fitToWindow() {
        scaleText = "适合窗口"
        resetToken = UUID()
    }

    func actualSize() {
        scaleText = "100%"
        NotificationCenter.default.post(name: .imageViewerActualSize, object: nil)
    }

    func updateScale(_ scale: CGFloat) {
        if abs(scale - 1) < 0.01 {
            scaleText = "适合窗口"
        } else {
            scaleText = "\(Int((scale * 100).rounded()))%"
        }
    }

    func copyCurrentImage() {
        guard let image else {
            showActionMessage("还没有可复制的图片")
            return
        }

        NSPasteboard.general.clearContents()
        if NSPasteboard.general.writeObjects([image]) {
            showActionMessage("已复制图片")
        } else {
            showActionMessage("复制图片失败")
        }
    }

    func pasteImageIntoCurrentFolder() {
        guard let folderURL = currentFolderURL else {
            showActionMessage("请先打开一张图片，再粘贴")
            return
        }

        let images = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage] ?? []
        guard let pastedImage = images.first else {
            showActionMessage("剪贴板里没有可粘贴的图片")
            return
        }

        do {
            let destinationURL = try imageEditingService.writePastedImage(pastedImage, into: folderURL)
            navigator = ImageFileNavigator.navigator(opening: destinationURL)
            selectedSidebarURL = navigator.currentURL?.standardizedFileURL
            imageLoadingService.reset()
            loadCurrentImageAndResetView()
            showActionMessage("已粘贴图片")
        } catch {
            showActionMessage("粘贴失败：\(error.localizedDescription)")
        }
    }

    func copyCurrentImagePath() {
        guard let url = navigator.currentURL else {
            showActionMessage("还没有可复制路径的图片")
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.path, forType: .string)
        showActionMessage("已复制文件路径")
    }

    func revealCurrentImageInFinder() {
        guard let url = navigator.currentURL else {
            showActionMessage("还没有可显示的图片")
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([url])
        showActionMessage("已在 Finder 中显示")
    }

    func deleteCurrentImageToTrash() {
        guard let url = navigator.currentURL, let currentIndex = navigator.currentIndex else {
            showActionMessage("还没有可删除的图片")
            return
        }

        let oldCount = navigator.files.count
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            let remainingFiles = navigator.files.filter { $0.standardizedFileURL != url.standardizedFileURL }
            let nextIndex = ImageFileNavigator.indexAfterDeletingCurrent(
                count: oldCount,
                deletedIndex: currentIndex
            )

            navigator = ImageFileNavigator(files: remainingFiles, currentIndex: nextIndex)
            selectedSidebarURL = navigator.currentURL?.standardizedFileURL
            imageLoadingService.reset()

            if navigator.currentURL == nil {
                image = nil
                errorMessage = "当前文件夹里没有可显示的图片"
                fitToWindow()
            } else {
                loadCurrentImageAndResetView()
            }

            showActionMessage("已移到废纸篓")
        } catch {
            showActionMessage("删除失败：\(error.localizedDescription)")
        }
    }

    func rotateLeft() {
        overwriteCurrentImage(actionName: "左转") { image in
            image.rotated(degrees: -90)
        }
    }

    func rotateRight() {
        overwriteCurrentImage(actionName: "右转") { image in
            image.rotated(degrees: 90)
        }
    }

    private func loadCurrentImageAndResetView() {
        guard let url = navigator.currentURL else {
            image = nil
            errorMessage = "还没有可显示的图片"
            selectedSidebarURL = nil
            return
        }

        selectedSidebarURL = url.standardizedFileURL

        guard let loadedImage = imageLoadingService.image(for: url) else {
            image = nil
            errorMessage = "无法打开这张图片：\(url.lastPathComponent)"
            return
        }

        image = loadedImage
        errorMessage = nil
        fitToWindow()
        keepOnlyAdjacentImagesInCache()
        prefetchAdjacentImages(for: url)
    }

    private var currentFolderURL: URL? {
        navigator.currentURL?.deletingLastPathComponent()
    }

    private func showActionMessage(_ message: String) {
        actionMessage = message
    }

    private func prefetchAdjacentImages(for url: URL) {
        let adjacentURLs = [navigator.previousURL, navigator.nextURL]
            .compactMap { $0?.standardizedFileURL }
            .filter { $0 != url.standardizedFileURL }

        guard !adjacentURLs.isEmpty else {
            return
        }

        imageLoadingService.prefetch(urls: adjacentURLs) { [weak self] in
            self?.keepOnlyAdjacentImagesInCache()
        }
    }

    private func keepOnlyAdjacentImagesInCache() {
        guard let currentURL = navigator.currentURL?.standardizedFileURL else {
            imageLoadingService.keepOnly(keeping: [])
            return
        }

        var urlsToKeep: Set<URL> = [currentURL]
        if let previousURL = navigator.previousURL?.standardizedFileURL {
            urlsToKeep.insert(previousURL)
        }
        if let nextURL = navigator.nextURL?.standardizedFileURL {
            urlsToKeep.insert(nextURL)
        }

        imageLoadingService.keepOnly(keeping: urlsToKeep)
    }

    private func overwriteCurrentImage(actionName: String, transform: (NSImage) -> NSImage?) {
        guard let sourceURL = navigator.currentURL, let image else {
            showActionMessage("还没有可编辑的图片")
            return
        }

        do {
            try imageEditingService.overwriteImage(
                at: sourceURL,
                image: image,
                actionName: actionName,
                transform: transform
            )
            imageLoadingService.removeCachedImage(for: sourceURL)
            imageLoadingService.invalidate()
            loadCurrentImageAndResetView()
            showActionMessage("已\(actionName)")
        } catch {
            showActionMessage("\(actionName)失败：\(error.localizedDescription)")
        }
    }
}
