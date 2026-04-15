import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var state: ImageViewerState

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            imageArea
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)

            statusBar
        }
        .background(Color.black.opacity(0.96))
        .frame(minWidth: 680, minHeight: 460)
    }

    private var imageArea: some View {
        ZStack {
            ViewerBackgroundView()
            Color.black.opacity(0.72)

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
                .foregroundStyle(.white.opacity(0.72))
                .frame(minWidth: 72, alignment: .leading)

            if let actionMessage = state.actionMessage {
                Text(actionMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.5))
    }

    private var emptyView: some View {
        VStack(spacing: 14) {
            Text("LiteViewer")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
            Text(state.errorMessage ?? "打开一张图片后，可以左右切换同文件夹里的照片。")
                .foregroundStyle(.white.opacity(0.72))
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
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
            Spacer()
            Text("像预览一样打开图片 · 左右滑动或方向键切换同文件夹照片")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.4))
    }

    @ViewBuilder
    private var imageContextMenu: some View {
        Button("复制") {
            state.copyCurrentImage()
        }

        Button("粘贴") {
            state.pasteImageIntoCurrentFolder()
        }
        .disabled(!state.canPasteImageFromPasteboard)

        Divider()

        Button("向左旋转") {
            state.rotateLeft()
        }

        Button("向右旋转") {
            state.rotateRight()
        }

        Divider()

        Button("在访达中显示") {
            state.revealCurrentImageInFinder()
        }
    }
}

private struct ViewerBackgroundView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
