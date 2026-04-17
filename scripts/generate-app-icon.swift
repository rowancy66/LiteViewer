import AppKit
import Foundation

let fileManager = FileManager.default
let rootURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let packagingURL = rootURL.appendingPathComponent("packaging", isDirectory: true)
let iconsetURL = packagingURL.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let icnsURL = packagingURL.appendingPathComponent("AppIcon.icns")

let iconFiles: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

for (name, size) in iconFiles {
    let image = makeIcon(size: CGFloat(size))
    let destinationURL = iconsetURL.appendingPathComponent(name)
    try pngData(from: image)?.write(to: destinationURL)
}

if fileManager.fileExists(atPath: icnsURL.path) {
    try? fileManager.removeItem(at: icnsURL)
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]
try iconutil.run()
iconutil.waitUntilExit()

guard iconutil.terminationStatus == 0 else {
    throw NSError(domain: "LiteViewer.IconGen", code: Int(iconutil.terminationStatus))
}

print("已生成图标：\(icnsURL.path)")

func makeIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    context.setAllowsAntialiasing(true)
    let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
    let inset = size * 0.035
    let cardRect = rect.insetBy(dx: inset, dy: inset)
    let radius = size * 0.22
    let rounded = NSBezierPath(roundedRect: cardRect, xRadius: radius, yRadius: radius)

    context.saveGState()
    rounded.addClip()

    let shellGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.98, green: 0.76, blue: 0.45, alpha: 1),
        NSColor(calibratedRed: 0.64, green: 0.34, blue: 0.20, alpha: 1),
        NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.14, alpha: 1)
    ])!
    shellGradient.draw(in: cardRect, angle: -38)

    let glow = NSGradient(colors: [
        NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.82, alpha: 0.95),
        NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.82, alpha: 0)
    ])!
    glow.draw(
        in: CGRect(
            x: cardRect.minX - size * 0.08,
            y: cardRect.midY,
            width: size * 0.72,
            height: size * 0.62
        ),
        relativeCenterPosition: NSPoint(x: 0, y: 0)
    )

    drawSidebarStrips(in: cardRect, size: size)
    drawPhotoStack(in: cardRect, size: size)

    context.restoreGState()

    NSColor.white.withAlphaComponent(0.16).setStroke()
    rounded.lineWidth = max(2, size * 0.01)
    rounded.stroke()

    image.unlockFocus()
    return image
}

func drawSidebarStrips(in rect: CGRect, size: CGFloat) {
    let stripWidth = size * 0.18
    let stripX = rect.minX + size * 0.10
    let stripY = rect.minY + size * 0.16
    let stripGap = size * 0.03
    let stripHeight = size * 0.10

    for index in 0..<3 {
        let y = stripY + CGFloat(index) * (stripHeight + stripGap)
        let barRect = CGRect(x: stripX, y: y, width: stripWidth, height: stripHeight)
        let path = NSBezierPath(roundedRect: barRect, xRadius: stripHeight / 2, yRadius: stripHeight / 2)
        NSColor.white.withAlphaComponent(index == 0 ? 0.78 : 0.28).setFill()
        path.fill()
    }
}

func drawPhotoStack(in rect: CGRect, size: CGFloat) {
    let frameRect = CGRect(
        x: rect.minX + size * 0.26,
        y: rect.minY + size * 0.17,
        width: size * 0.56,
        height: size * 0.60
    )

    let backRect = frameRect.offsetBy(dx: -size * 0.06, dy: size * 0.04)
    drawPhotoCard(
        in: backRect,
        fill: NSColor.white.withAlphaComponent(0.18),
        border: NSColor.white.withAlphaComponent(0.16),
        rotation: -8
    )

    let midRect = frameRect.offsetBy(dx: size * 0.05, dy: size * 0.03)
    drawPhotoCard(
        in: midRect,
        fill: NSColor.white.withAlphaComponent(0.24),
        border: NSColor.white.withAlphaComponent(0.16),
        rotation: 7
    )

    drawPhotoCard(
        in: frameRect,
        fill: NSColor.white.withAlphaComponent(0.94),
        border: NSColor.white.withAlphaComponent(0.42),
        rotation: -6
    )

    let artInset = size * 0.028
    let artRect = frameRect.insetBy(dx: artInset, dy: artInset)
    let artPath = NSBezierPath(roundedRect: artRect, xRadius: size * 0.045, yRadius: size * 0.045)
    NSColor(calibratedRed: 0.96, green: 0.87, blue: 0.70, alpha: 1).setFill()
    artPath.fill()

    let skyGradient = NSGradient(colors: [
        NSColor(calibratedRed: 1.0, green: 0.83, blue: 0.54, alpha: 1),
        NSColor(calibratedRed: 0.84, green: 0.56, blue: 0.28, alpha: 1),
        NSColor(calibratedRed: 0.28, green: 0.39, blue: 0.52, alpha: 1)
    ])!
    skyGradient.draw(in: artRect, angle: 90)

    let mountainPath = NSBezierPath()
    mountainPath.move(to: CGPoint(x: artRect.minX, y: artRect.minY + artRect.height * 0.38))
    mountainPath.line(to: CGPoint(x: artRect.minX + artRect.width * 0.30, y: artRect.minY + artRect.height * 0.70))
    mountainPath.line(to: CGPoint(x: artRect.minX + artRect.width * 0.48, y: artRect.minY + artRect.height * 0.50))
    mountainPath.line(to: CGPoint(x: artRect.minX + artRect.width * 0.68, y: artRect.minY + artRect.height * 0.80))
    mountainPath.line(to: CGPoint(x: artRect.maxX, y: artRect.minY + artRect.height * 0.44))
    mountainPath.line(to: CGPoint(x: artRect.maxX, y: artRect.minY))
    mountainPath.line(to: CGPoint(x: artRect.minX, y: artRect.minY))
    mountainPath.close()
    NSColor(calibratedRed: 0.18, green: 0.22, blue: 0.27, alpha: 0.90).setFill()
    mountainPath.fill()

    let sunRect = CGRect(
        x: artRect.maxX - artRect.width * 0.28,
        y: artRect.maxY - artRect.height * 0.32,
        width: artRect.width * 0.18,
        height: artRect.width * 0.18
    )
    let sun = NSBezierPath(ovalIn: sunRect)
    NSColor.white.withAlphaComponent(0.55).setFill()
    sun.fill()
}

func drawPhotoCard(in rect: CGRect, fill: NSColor, border: NSColor, rotation: CGFloat) {
    var transform = AffineTransform()
    let center = CGPoint(x: rect.midX, y: rect.midY)
    transform.translate(x: center.x, y: center.y)
    transform.rotate(byDegrees: rotation)
    transform.translate(x: -center.x, y: -center.y)

    let path = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.10, yRadius: rect.width * 0.10)
    path.transform(using: transform)
    fill.setFill()
    path.fill()
    border.setStroke()
    path.lineWidth = max(1.5, rect.width * 0.018)
    path.stroke()
}

func pngData(from image: NSImage) -> Data? {
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData)
    else {
        return nil
    }

    return bitmap.representation(using: .png, properties: [:])
}
