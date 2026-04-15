import AppKit
import Foundation
import ImageIO
import LiteViewerCore
import UniformTypeIdentifiers

/// 界面状态中心：负责打开图片、切换图片、记录当前缩放模式。
/// 这样界面只负责展示，文件扫描和图片加载都集中在这里。
final class ImageViewerState: ObservableObject {
    @Published private(set) var navigator = ImageFileNavigator()
    @Published private(set) var image: NSImage?
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?
    @Published var resetToken = UUID()
    @Published var scaleText = "适合窗口"

    private var imageCache: [URL: NSImage] = [:]
    private var cacheGeneration = 0
    private let prefetchQueue = DispatchQueue(label: "LiteViewer.ImagePrefetch", qos: .utility)

    var currentFileName: String {
        navigator.currentURL?.lastPathComponent ?? "未打开图片"
    }

    var statusText: String {
        guard let image else {
            return errorMessage ?? "点击“打开”选择一张图片"
        }

        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        return "\(navigator.displayPosition) · \(currentFileName) · \(width) × \(height)"
    }

    var canPasteImageFromPasteboard: Bool {
        NSPasteboard.general.canReadObject(forClasses: [NSImage.self], options: nil)
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
        bumpCacheGeneration()
        loadCurrentImageAndResetView()
    }

    func selectImage(_ url: URL) {
        guard let index = navigator.files.firstIndex(where: { $0.standardizedFileURL == url.standardizedFileURL }) else {
            return
        }

        navigator = ImageFileNavigator(files: navigator.files, currentIndex: index)
        bumpCacheGeneration()
        loadCurrentImageAndResetView()
    }

    func previousImage() {
        navigator = navigator.previous()
        bumpCacheGeneration()
        loadCurrentImageAndResetView()
    }

    func nextImage() {
        navigator = navigator.next()
        bumpCacheGeneration()
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

        let pasteboard = NSPasteboard.general
        let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage] ?? []

        guard let pastedImage = images.first else {
            showActionMessage("剪贴板里没有可粘贴的图片文件")
            return
        }

        let destinationURL = uniqueDestinationURL(
            for: pastedImageFileName(),
            in: folderURL
        )

        do {
            try pastedImage.writePNG(to: destinationURL)
            navigator = ImageFileNavigator.navigator(opening: destinationURL)
            bumpCacheGeneration()
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
            bumpCacheGeneration()

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

    func flipHorizontal() {
        transformCurrentImage(actionName: "水平翻转") { image in
            image.flipped(horizontal: true)
        }
    }

    func flipVertical() {
        transformCurrentImage(actionName: "垂直翻转") { image in
            image.flipped(horizontal: false)
        }
    }

    func cropCenterSquare() {
        transformCurrentImage(actionName: "中心裁剪") { image in
            image.croppedToCenterSquare()
        }
    }

    private func loadCurrentImageAndResetView() {
        guard let url = navigator.currentURL else {
            image = nil
            errorMessage = "还没有可显示的图片"
            return
        }

        guard let loadedImage = image(for: url) else {
            image = nil
            errorMessage = "无法打开这张图片：\(url.lastPathComponent)"
            return
        }

        image = loadedImage
        errorMessage = nil
        fitToWindow()
        keepOnlyAdjacentImagesInCache()
        prefetchAdjacentImages(for: url, generation: cacheGeneration)
    }

    private var currentFolderURL: URL? {
        navigator.currentURL?.deletingLastPathComponent()
    }

    private func uniqueDestinationURL(for fileName: String, in folderURL: URL) -> URL {
        let originalURL = folderURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: originalURL.path) else {
            return originalURL
        }

        let baseName = originalURL.deletingPathExtension().lastPathComponent
        let pathExtension = originalURL.pathExtension
        var counter = 1

        while true {
            let candidateName = pathExtension.isEmpty
                ? "\(baseName) copy \(counter)"
                : "\(baseName) copy \(counter).\(pathExtension)"
            let candidateURL = folderURL.appendingPathComponent(candidateName)
            if !FileManager.default.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }

    private func pastedImageFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "贴图_\(formatter.string(from: Date())).png"
    }

    private func showActionMessage(_ message: String) {
        actionMessage = message
    }

    private func image(for url: URL) -> NSImage? {
        if let cached = imageCache[url.standardizedFileURL] {
            return cached
        }

        guard let loadedImage = NSImage(contentsOf: url) else {
            return nil
        }

        imageCache[url.standardizedFileURL] = loadedImage
        return loadedImage
    }

    private func prefetchAdjacentImages(for url: URL, generation: Int) {
        let urls = Array(Set([navigator.previousURL, navigator.nextURL]
            .compactMap { $0 }
            .map { $0.standardizedFileURL }
            .filter { $0 != url.standardizedFileURL }))

        guard !urls.isEmpty else {
            return
        }

        for nextURL in urls where imageCache[nextURL] == nil {
            prefetchQueue.async { [weak self] in
                guard let self, generation == self.cacheGeneration else { return }
                guard let image = NSImage(contentsOf: nextURL) else { return }

                DispatchQueue.main.async { [weak self] in
                    guard let self, generation == self.cacheGeneration else { return }
                    self.imageCache[nextURL] = image
                    self.keepOnlyAdjacentImagesInCache()
                }
            }
        }
    }

    private func keepOnlyAdjacentImagesInCache() {
        guard let currentURL = navigator.currentURL?.standardizedFileURL else {
            imageCache.removeAll()
            return
        }

        var keep = Set<URL>()
        keep.insert(currentURL)

        if let previousURL = navigator.previousURL?.standardizedFileURL {
            keep.insert(previousURL)
        }

        if let nextURL = navigator.nextURL?.standardizedFileURL {
            keep.insert(nextURL)
        }

        imageCache = imageCache.filter { keep.contains($0.key) }
    }

    private func bumpCacheGeneration() {
        cacheGeneration &+= 1
    }

    private func overwriteCurrentImage(actionName: String, transform: (NSImage) -> NSImage?) {
        guard let sourceURL = navigator.currentURL, let image else {
            showActionMessage("还没有可编辑的图片")
            return
        }

        guard let editedImage = transform(image) else {
            showActionMessage("\(actionName)失败：无法处理图片")
            return
        }

        let tempURL = sourceURL
            .deletingLastPathComponent()
            .appendingPathComponent(".liteviewer-\(UUID().uuidString)")
            .appendingPathExtension(sourceURL.pathExtension)

        do {
            try editedImage.writePreservingOriginalFormat(to: tempURL, originalURL: sourceURL)
            _ = try FileManager.default.replaceItemAt(sourceURL, withItemAt: tempURL)
            imageCache.removeValue(forKey: sourceURL.standardizedFileURL)
            bumpCacheGeneration()
            loadCurrentImageAndResetView()
            showActionMessage("已\(actionName)")
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            showActionMessage("\(actionName)失败：\(error.localizedDescription)")
        }
    }

    private func transformCurrentImage(actionName: String, transform: (NSImage) -> NSImage?) {
        guard let sourceURL = navigator.currentURL, let image else {
            showActionMessage("还没有可编辑的图片")
            return
        }

        guard let editedImage = transform(image) else {
            showActionMessage("\(actionName)失败：无法处理图片")
            return
        }

        let destinationURL = editedImageURL(for: sourceURL, actionName: actionName)
        do {
            try editedImage.writePNG(to: destinationURL)
            navigator = ImageFileNavigator.navigator(opening: destinationURL)
            bumpCacheGeneration()
            loadCurrentImageAndResetView()
            showActionMessage("已生成\(actionName)图片")
        } catch {
            showActionMessage("\(actionName)失败：\(error.localizedDescription)")
        }
    }

    private func editedImageURL(for sourceURL: URL, actionName: String) -> URL {
        let folderURL = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let safeAction = actionName.replacingOccurrences(of: " ", with: "-")
        return uniqueDestinationURL(for: "\(baseName)-\(safeAction).png", in: folderURL)
    }
}

extension Notification.Name {
    static let imageViewerActualSize = Notification.Name("imageViewerActualSize")
}

private extension NSImage {
    func rotated(degrees: CGFloat) -> NSImage? {
        let radians = degrees * .pi / 180
        let originalSize = size
        let rotatedSize = CGSize(width: originalSize.height, height: originalSize.width)
        let output = NSImage(size: rotatedSize)

        output.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            output.unlockFocus()
            return nil
        }

        context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        context.rotate(by: radians)
        draw(in: CGRect(
            x: -originalSize.width / 2,
            y: -originalSize.height / 2,
            width: originalSize.width,
            height: originalSize.height
        ))
        output.unlockFocus()
        return output
    }

    func flipped(horizontal: Bool) -> NSImage? {
        let output = NSImage(size: size)
        output.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            output.unlockFocus()
            return nil
        }

        if horizontal {
            context.translateBy(x: size.width, y: 0)
            context.scaleBy(x: -1, y: 1)
        } else {
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1, y: -1)
        }

        draw(in: CGRect(origin: .zero, size: size))
        output.unlockFocus()
        return output
    }

    func croppedToCenterSquare() -> NSImage? {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let side = min(cgImage.width, cgImage.height)
        let cropRect = CGRect(
            x: (cgImage.width - side) / 2,
            y: (cgImage.height - side) / 2,
            width: side,
            height: side
        )

        guard let cropped = cgImage.cropping(to: cropRect) else {
            return nil
        }

        return NSImage(cgImage: cropped, size: CGSize(width: side, height: side))
    }

    func writePNG(to url: URL) throws {
        guard
            let tiffData = tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            throw CocoaError(.fileWriteUnknown)
        }

        try pngData.write(to: url, options: .atomic)
    }

    func writePreservingOriginalFormat(to tempURL: URL, originalURL: URL) throws {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw CocoaError(.fileWriteUnknown)
        }

        let fileType = UTType(filenameExtension: originalURL.pathExtension) ?? .png
        guard let destination = CGImageDestinationCreateWithURL(
            tempURL as CFURL,
            fileType.identifier as CFString,
            1,
            nil
        ) else {
            throw CocoaError(.fileWriteUnknown)
        }

        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw CocoaError(.fileWriteUnknown)
        }
    }
}
