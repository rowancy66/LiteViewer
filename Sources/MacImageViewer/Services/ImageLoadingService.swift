import AppKit
import Foundation

final class ImageLoadingService {
    private var imageCache: [URL: NSImage] = [:]
    private var generation = 0
    private let prefetchQueue = DispatchQueue(label: "LiteViewer.ImagePrefetch", qos: .utility)

    func reset() {
        generation &+= 1
        imageCache.removeAll()
    }

    func invalidate() {
        generation &+= 1
    }

    func image(for url: URL) -> NSImage? {
        let normalizedURL = url.standardizedFileURL

        if let cached = imageCache[normalizedURL] {
            return cached
        }

        guard let loadedImage = NSImage(contentsOf: normalizedURL) else {
            return nil
        }

        imageCache[normalizedURL] = loadedImage
        return loadedImage
    }

    func removeCachedImage(for url: URL) {
        imageCache.removeValue(forKey: url.standardizedFileURL)
    }

    func keepOnly(keeping urls: Set<URL>) {
        guard !urls.isEmpty else {
            imageCache.removeAll()
            return
        }

        imageCache = imageCache.filter { urls.contains($0.key) }
    }

    func prefetch(urls: [URL], onImageCached: @escaping () -> Void) {
        let targetURLs = Array(Set(urls.map(\.standardizedFileURL)))
        let generationSnapshot = generation

        for nextURL in targetURLs where imageCache[nextURL] == nil {
            prefetchQueue.async { [weak self] in
                guard let self else { return }
                guard let image = NSImage(contentsOf: nextURL) else { return }

                DispatchQueue.main.async { [weak self] in
                    guard let self, generationSnapshot == self.generation else { return }
                    self.imageCache[nextURL] = image
                    onImageCached()
                }
            }
        }
    }
}
