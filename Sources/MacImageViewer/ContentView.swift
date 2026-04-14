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
            Text("缩略图")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.top, 10)

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

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 5) {
                ThumbnailImage(url: url)
                    .frame(width: 112, height: 82)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

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

private struct ThumbnailImage: View {
    let url: URL

    var body: some View {
        ThumbnailImageView(url: url)
            .padding(3)
    }
}

private struct ThumbnailImageView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageAlignment = .alignCenter
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = NSImage(contentsOf: url)
    }
}
