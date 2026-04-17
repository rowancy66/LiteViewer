import Foundation

struct ViewerSidebarItem: Identifiable, Hashable {
    let url: URL

    var id: URL {
        url.standardizedFileURL
    }

    var fileName: String {
        url.lastPathComponent
    }

    var secondaryText: String {
        let ext = url.pathExtension.uppercased()
        return ext.isEmpty ? "图片" : ext
    }
}
