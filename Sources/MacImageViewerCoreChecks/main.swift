import Foundation
import MacImageViewerCore

enum CheckFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw CheckFailure.failed(message)
    }
}

func checkSupportedImageExtensionsAreCaseInsensitive() throws {
    try expect(ImageFileNavigator.isSupportedImage(URL(fileURLWithPath: "/tmp/a.JPG")), "JPG 应被识别为图片")
    try expect(ImageFileNavigator.isSupportedImage(URL(fileURLWithPath: "/tmp/a.webp")), "webp 应被识别为图片")
    try expect(ImageFileNavigator.isSupportedImage(URL(fileURLWithPath: "/tmp/a.HEIC")), "HEIC 应被识别为图片")
    try expect(!ImageFileNavigator.isSupportedImage(URL(fileURLWithPath: "/tmp/a.pdf")), "PDF 不应被识别为图片")
}

func checkImageFilesFiltersAndSortsByFinderLikeNameOrder() throws {
    let folder = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }

    try Data().write(to: folder.appendingPathComponent("image10.png"))
    try Data().write(to: folder.appendingPathComponent("image2.jpg"))
    try Data().write(to: folder.appendingPathComponent("notes.txt"))
    try Data().write(to: folder.appendingPathComponent("image1.webp"))

    let names = ImageFileNavigator.imageFiles(in: folder).map(\.lastPathComponent)
    try expect(names == ["image1.webp", "image2.jpg", "image10.png"], "图片列表过滤或排序不正确：\(names)")
}

func checkNextAndPreviousWrapAroundAtEdges() throws {
    let files = [
        URL(fileURLWithPath: "/tmp/1.png"),
        URL(fileURLWithPath: "/tmp/2.png"),
        URL(fileURLWithPath: "/tmp/3.png")
    ]

    let first = ImageFileNavigator(files: files, currentIndex: 0)
    try expect(first.previous().currentURL?.lastPathComponent == "3.png", "第一张的上一张应循环到最后一张")
    try expect(first.next().currentURL?.lastPathComponent == "2.png", "第一张的下一张应是第二张")

    let last = ImageFileNavigator(files: files, currentIndex: 2)
    try expect(last.next().currentURL?.lastPathComponent == "1.png", "最后一张的下一张应循环到第一张")
}

func checkIndexAfterDeletingCurrentImage() throws {
    try expect(
        ImageFileNavigator.indexAfterDeletingCurrent(count: 3, deletedIndex: 1) == 1,
        "删除中间图片后，应选择原位置的下一张"
    )
    try expect(
        ImageFileNavigator.indexAfterDeletingCurrent(count: 3, deletedIndex: 2) == 1,
        "删除最后一张后，应选择新的最后一张"
    )
    try expect(
        ImageFileNavigator.indexAfterDeletingCurrent(count: 1, deletedIndex: 0) == nil,
        "删除唯一图片后，应没有当前图片"
    )
}

func checkLaunchFileURLsIgnoreSystemArguments() throws {
    let folder = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }

    let imageURL = folder.appendingPathComponent("open-me.png")
    let textURL = folder.appendingPathComponent("skip-me.txt")
    try Data().write(to: imageURL)
    try Data().write(to: textURL)

    let urls = ImageFileNavigator.launchFileURLs(from: [
        "MacImageViewer",
        "-psn_0_12345",
        "--debug",
        textURL.path,
        imageURL.path
    ])

    try expect(urls == [imageURL], "启动参数应忽略系统参数，只保留真实文件路径：\(urls)")
}

let checks: [(String, () throws -> Void)] = [
    ("支持的图片扩展名不区分大小写", checkSupportedImageExtensionsAreCaseInsensitive),
    ("扫描文件夹时只保留图片并按 Finder 风格排序", checkImageFilesFiltersAndSortsByFinderLikeNameOrder),
    ("上一张和下一张在边界处循环", checkNextAndPreviousWrapAroundAtEdges),
    ("删除当前图片后选择合理的新索引", checkIndexAfterDeletingCurrentImage),
    ("启动时忽略系统参数并打开真实图片路径", checkLaunchFileURLsIgnoreSystemArguments)
]

do {
    for (name, check) in checks {
        try check()
        print("PASS: \(name)")
    }
    print("全部核心逻辑自检通过")
} catch {
    fputs("FAIL: \(error)\n", stderr)
    exit(1)
}
