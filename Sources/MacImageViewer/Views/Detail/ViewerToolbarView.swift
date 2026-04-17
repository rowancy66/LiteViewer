import SwiftUI

struct ViewerToolbarView: View {
    @ObservedObject var state: ImageViewerState

    var body: some View {
        HStack(spacing: 14) {
            ViewerPanel {
                HStack(spacing: 8) {
                    Button {
                        state.openImage()
                    } label: {
                        Label("打开图片", systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(ViewerCapsuleButtonStyle(highlighted: true))
                    .keyboardShortcut("o", modifiers: .command)
                }
                .padding(8)
            }
            .frame(maxWidth: 150)

            ViewerPanel {
                HStack(spacing: 6) {
                    compactButton(symbol: "chevron.left", title: "上一张", action: state.previousImage)
                    compactButton(symbol: "chevron.right", title: "下一张", action: state.nextImage)
                }
                .padding(8)
            }
            .frame(maxWidth: 120)

            ViewerPanel {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(state.currentFileName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(state.sidebarSummaryText)
                            .font(.system(size: 12))
                            .foregroundStyle(ViewerTheme.detailTextSoft)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 10)

                    Text(state.scaleText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ViewerTheme.detailTextMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(ViewerTheme.detailPanelStrong)
                        .clipShape(Capsule(style: .continuous))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }

            ViewerPanel {
                HStack(spacing: 6) {
                    textButton("适合", action: state.fitToWindow)
                    textButton("原图", action: state.actualSize)
                    Divider()
                        .frame(height: 18)
                        .overlay(ViewerTheme.detailBorder)
                    compactButton(symbol: "rotate.left", title: "左转", action: state.rotateLeft)
                    compactButton(symbol: "rotate.right", title: "右转", action: state.rotateRight)
                }
                .padding(8)
            }
            .frame(maxWidth: 250)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ViewerTheme.detailBorder)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func compactButton(symbol: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(ViewerCapsuleButtonStyle())
        .disabled(!state.hasCurrentImage && title != "上一张" && title != "下一张")
        .help(title)
    }

    @ViewBuilder
    private func textButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(ViewerCapsuleButtonStyle())
            .disabled(!state.hasCurrentImage)
    }
}
