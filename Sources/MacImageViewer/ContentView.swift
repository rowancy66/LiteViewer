import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var state: ImageViewerState

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            HStack(spacing: 0) {
                thumbnailSidebar
                Divider()
                imageArea
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()
            statusBar
        }
        .frame(minWidth: 720, minHeight: 480)
    }

    private var thumbnailSidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("缩略图 · \(state.navigator.files.count) 张")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.top, 10)

            if state.navigator.files.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 22))
                    Text("没有可显示的缩略图")
                        .font(.system(size: 12, weight: .medium))
                    Text("打开一张图片后，这里会列出同文件夹里的图片。")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(state.navigator.files, id: \.self) { url in
                            ThumbnailRow(
                                url: url,
                                isSelected: state.navigator.currentURL?.standardizedFileURL == url.standardizedFileURL
                            ) {
                                state.selectImage(url)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 10)
                }
            }
        }
        .frame(width: 150)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var imageArea: some View {
        ZStack {
            if let image = state.image {
                ImageCanvasView(
                    image: image,
                    resetToken: state.resetToken,
                    onPrevious: state.previousImage,
                    onNext: state.nextImage,
                    onScaleChanged: state.updateScale
                )
                .contextMenu {
                    imageContextMenu
                }
            } else {
                emptyView
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button("打开") {
                state.openImage()
            }
            .keyboardShortcut("o", modifiers: .command)

            Divider()
                .frame(height: 22)

            Button("上一张") {
                state.previousImage()
            }
            .disabled(state.navigator.files.isEmpty)

            Button("下一张") {
                state.nextImage()
            }
            .disabled(state.navigator.files.isEmpty)

            Divider()
                .frame(height: 22)

            Button("适合窗口") {
                state.fitToWindow()
            }
            .disabled(state.image == nil)

            Button("实际大小") {
                state.actualSize()
            }
            .disabled(state.image == nil)

            Text(state.scaleText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(minWidth: 72, alignment: .leading)

            if let actionMessage = state.actionMessage {
                Text(actionMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var emptyView: some View {
        VStack(spacing: 14) {
            Text("MacImageViewer")
                .font(.system(size: 34, weight: .semibold))
            Text(state.errorMessage ?? "打开一张图片后，可以双指缩放、左右滑动切换。")
                .foregroundStyle(.secondary)
            Button("打开图片") {
                state.openImage()
            }
            .controlSize(.large)
        }
        .padding()
    }

    private var statusBar: some View {
        HStack {
            Text(state.statusText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Text("双指缩放 · 左右滑动切换 · 方向键切换")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var imageContextMenu: some View {
        Button("复制图片文件") {
            state.copyCurrentImageFile()
        }

        Button("粘贴图片到当前文件夹") {
            state.pasteImageFileIntoCurrentFolder()
        }

        Divider()

        Button("向左旋转并另存") {
            state.rotateLeft()
        }

        Button("向右旋转并另存") {
            state.rotateRight()
        }

        Button("水平翻转并另存") {
            state.flipHorizontal()
        }

        Button("垂直翻转并另存") {
            state.flipVertical()
        }

        Button("中心裁剪为正方形并另存") {
            state.cropCenterSquare()
        }

        Divider()

        Button("复制文件路径") {
            state.copyCurrentImagePath()
        }

        Button("在 Finder 中显示") {
            state.revealCurrentImageInFinder()
        }

        Divider()

        Button("移到废纸篓") {
            state.deleteCurrentImageToTrash()
        }
    }
}

private struct ThumbnailRow: View {
    let url: URL
    let isSelected: Bool
    let onSelect: () -> Void
    @StateObject private var loader: ThumbnailLoader

    init(url: URL, isSelected: Bool, onSelect: @escaping () -> Void) {
        self.url = url
        self.isSelected = isSelected
        self.onSelect = onSelect
        _loader = StateObject(wrappedValue: ThumbnailLoader(url: url))
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 5) {
                ThumbnailPreviewImage(image: loader.thumbnail, isFallback: loader.isFallback)
                    .frame(width: 112, height: 82)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(alignment: .bottomTrailing) {
                        if loader.isFallback {
                            Text("图标")
                                .font(.system(size: 8, weight: .semibold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(4)
                        }
                    }

                Text(url.lastPathComponent)
                    .font(.system(size: 11))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .padding(7)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentColor : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

private struct ThumbnailPreviewImage: View {
    let image: NSImage?
    let isFallback: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(nsColor: .windowBackgroundColor))

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(4)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.system(size: 18))
                    Text("无预览")
                        .font(.system(size: 10))
                }
                .foregroundStyle(.secondary)
            }
        }
        .overlay(alignment: .topLeading) {
            if isFallback {
                Image(systemName: "doc")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(5)
            }
        }
    }
}

final class ThumbnailLoader: ObservableObject {
    private static let cache = NSCache<NSURL, NSImage>()
    private static let fallbackCache = NSCache<NSURL, NSNumber>()

    @Published var thumbnail: NSImage?
    @Published var isFallback: Bool = false

    private let url: URL

    init(url: URL) {
        self.url = url
        load()
    }

    private func load() {
        let cacheKey = url.standardizedFileURL as NSURL
        if let cached = Self.cache.object(forKey: cacheKey) {
            thumbnail = cached
            isFallback = Self.fallbackCache.object(forKey: cacheKey)?.boolValue ?? false
            return
        }

        let loadedImage = NSImage(contentsOf: url)
        let validLoadedImage = loadedImage.flatMap { image -> NSImage? in
            guard image.size.width > 0, image.size.height > 0 else { return nil }
            return image
        }

        if let validLoadedImage {
            thumbnail = validLoadedImage
            isFallback = false
            Self.cache.setObject(validLoadedImage, forKey: cacheKey)
            Self.fallbackCache.setObject(NSNumber(value: false), forKey: cacheKey)
            return
        }

        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 96, height: 96)
        thumbnail = icon
        isFallback = true
        Self.cache.setObject(icon, forKey: cacheKey)
        Self.fallbackCache.setObject(NSNumber(value: true), forKey: cacheKey)
    }
}
