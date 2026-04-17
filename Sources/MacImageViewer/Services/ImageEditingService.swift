import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

final class ImageEditingService {
    func writePastedImage(_ image: NSImage, into folderURL: URL) throws -> URL {
        let destinationURL = uniqueDestinationURL(for: pastedImageFileName(), in: folderURL)
        try image.writePNG(to: destinationURL)
        return destinationURL
    }

    func overwriteImage(
        at sourceURL: URL,
        image: NSImage,
        actionName: String,
        transform: (NSImage) -> NSImage?
    ) throws {
        guard let editedImage = transform(image) else {
            throw CocoaError(.fileWriteUnknown)
        }

        let tempURL = sourceURL
            .deletingLastPathComponent()
            .appendingPathComponent(".liteviewer-\(UUID().uuidString)")
            .appendingPathExtension(sourceURL.pathExtension)

        do {
            try editedImage.writePreservingOriginalFormat(to: tempURL, originalURL: sourceURL)
            _ = try FileManager.default.replaceItemAt(sourceURL, withItemAt: tempURL)
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            throw error
        }
    }

    private func pastedImageFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "贴图_\(formatter.string(from: Date())).png"
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
}

extension NSImage {
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
