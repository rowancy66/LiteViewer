import AppKit
import Foundation
import ImageIO

final class ImageThumbnailService {
    private let cache = NSCache<NSURL, NSImage>()
    private let queue = DispatchQueue(label: "LiteViewer.ImageThumbnail", qos: .userInitiated)

    func cachedThumbnail(for url: URL) -> NSImage? {
        cache.object(forKey: url.standardizedFileURL as NSURL)
    }

    func loadThumbnail(for url: URL, completion: @escaping (URL, NSImage?) -> Void) {
        let normalizedURL = url.standardizedFileURL

        if let cached = cachedThumbnail(for: normalizedURL) {
            completion(normalizedURL, cached)
            return
        }

        queue.async { [weak self] in
            let image = self?.makeThumbnail(for: normalizedURL)

            DispatchQueue.main.async {
                if let image {
                    self?.cache.setObject(image, forKey: normalizedURL as NSURL)
                }
                completion(normalizedURL, image)
            }
        }
    }

    private func makeThumbnail(for url: URL) -> NSImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return NSImage(contentsOf: url)
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 180
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return NSImage(contentsOf: url)
        }

        return NSImage(
            cgImage: cgImage,
            size: NSSize(width: cgImage.width, height: cgImage.height)
        )
    }
}
