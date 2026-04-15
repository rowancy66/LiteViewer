import Foundation

/// 负责判断图片格式、扫描文件夹和维护图片列表。
/// 这里尽量只放“文件相关”的逻辑，界面层不直接关心具体格式规则。
public struct ImageFileNavigator {
    public static let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif", "tiff", "tif", "bmp", "heic", "heif", "webp"
    ]

    public let files: [URL]
    public let currentIndex: Int?

    public var currentURL: URL? {
        guard let currentIndex else { return nil }
        return files[currentIndex]
    }

    public var displayPosition: String {
        guard let currentIndex else { return "0 / 0" }
        return "\(currentIndex + 1) / \(files.count)"
    }

    public init(files: [URL] = [], currentIndex: Int? = nil) {
        self.files = files
        self.currentIndex = currentIndex
    }

    public static func isSupportedImage(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    public static func imageFiles(in folderURL: URL) -> [URL] {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isHiddenKey]
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsPackageDescendants]
        )) ?? []

        return urls
            .filter { url in
                guard isSupportedImage(url) else { return false }
                let values = try? url.resourceValues(forKeys: keys)
                return values?.isRegularFile == true && values?.isHidden != true
            }
            .sorted {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }
    }

    public static func navigator(opening selectedURL: URL) -> ImageFileNavigator {
        let folderURL = selectedURL.deletingLastPathComponent()
        let files = imageFiles(in: folderURL)
        let index = files.firstIndex { $0.standardizedFileURL == selectedURL.standardizedFileURL }

        if let index {
            return ImageFileNavigator(files: files, currentIndex: index)
        }

        return ImageFileNavigator(files: [selectedURL], currentIndex: 0)
    }

    public static func launchFileURLs(from commandLineArguments: [String]) -> [URL] {
        fileURLsFromLaunchItems(Array(commandLineArguments.dropFirst()))
    }

    public static func fileURLsFromLaunchItems(_ items: [String]) -> [URL] {
        items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { !$0.hasPrefix("-psn_") && !$0.hasPrefix("--") && !$0.hasPrefix("-") }
            .map { URL(fileURLWithPath: $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
            .filter(isSupportedImage)
    }

    public static func indexAfterDeletingCurrent(count: Int, deletedIndex: Int) -> Int? {
        let remainingCount = count - 1
        guard remainingCount > 0 else { return nil }
        return min(max(deletedIndex, 0), remainingCount - 1)
    }

    public func previous() -> ImageFileNavigator {
        guard let currentIndex, !files.isEmpty else { return self }
        let nextIndex = currentIndex == 0 ? files.count - 1 : currentIndex - 1
        return ImageFileNavigator(files: files, currentIndex: nextIndex)
    }

    public func next() -> ImageFileNavigator {
        guard let currentIndex, !files.isEmpty else { return self }
        let nextIndex = currentIndex == files.count - 1 ? 0 : currentIndex + 1
        return ImageFileNavigator(files: files, currentIndex: nextIndex)
    }
}
