import AppKit
import SwiftUI

struct ViewerDetailView: View {
    @ObservedObject var state: ImageViewerState

    var body: some View {
        VStack(spacing: 0) {
            ViewerToolbarView(state: state)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            ViewerStatusBarView(state: state)
        }
        .background(
            LinearGradient(
                colors: [
                    ViewerTheme.detailBase.opacity(0.98),
                    Color.black.opacity(0.96)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var content: some View {
        ZStack {
            ViewerBackgroundView()
            LinearGradient(
                colors: [
                    Color.black.opacity(0.30),
                    Color.black.opacity(0.62)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

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
                .padding(22)
            } else {
                EmptyStateView(
                    title: "打开一张图片开始浏览",
                    message: state.errorMessage ?? "左边浏览列表，右边沉浸看图。像一个更轻、更快的 macOS 原生看片夹。",
                    actionTitle: "打开图片",
                    action: state.openImage
                )
                .padding(32)
            }
        }
    }

    @ViewBuilder
    private var imageContextMenu: some View {
        Button("复制图片") {
            state.copyCurrentImage()
        }

        Button("粘贴到当前文件夹") {
            state.pasteImageIntoCurrentFolder()
        }
        .disabled(!state.canPasteImageFromPasteboard)

        Button("复制文件路径") {
            state.copyCurrentImagePath()
        }

        Divider()

        Button("向左旋转") {
            state.rotateLeft()
        }

        Button("向右旋转") {
            state.rotateRight()
        }

        Divider()

        Button("在 Finder 中显示") {
            state.revealCurrentImageInFinder()
        }

        Button("移到废纸篓") {
            state.deleteCurrentImageToTrash()
        }
    }
}

private struct ViewerBackgroundView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
