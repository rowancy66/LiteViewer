import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 28) {
            artwork

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(ViewerTheme.detailText)

                    Text(message)
                        .font(.system(size: 14))
                        .foregroundStyle(ViewerTheme.detailTextMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    Button(actionTitle) {
                        action()
                    }
                    .buttonStyle(ViewerCapsuleButtonStyle(highlighted: true))

                    Label("左右切换", systemImage: "arrow.left.arrow.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ViewerTheme.detailTextMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(ViewerTheme.detailPanelStrong)
                        .clipShape(Capsule(style: .continuous))
                }

                VStack(alignment: .leading, spacing: 10) {
                    featureRow(symbol: "sidebar.left", title: "侧边浏览", detail: "缩略图和文件名一起看，定位更快。")
                    featureRow(symbol: "viewfinder", title: "沉浸看图", detail: "大图区域单独成面，视觉更聚焦。")
                    featureRow(symbol: "rotate.right", title: "轻操作", detail: "保留常用旋转和缩放，不把界面做重。")
                }
            }
        }
        .padding(26)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.78),
                    Color.white.opacity(0.54)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(ViewerTheme.detailBorder, lineWidth: 1)
        )
        .frame(maxWidth: 760)
    }

    private var artwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.72, blue: 0.38),
                            Color(red: 0.48, green: 0.63, blue: 0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 150, height: 100)
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color(red: 0.99, green: 0.83, blue: 0.56),
                                Color(red: 0.31, green: 0.45, blue: 0.59)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .padding(9)
                    )
                    .rotationEffect(.degrees(-8))
                    .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 8)

                HStack(spacing: 8) {
                    Capsule().fill(Color.white.opacity(0.72)).frame(width: 38, height: 6)
                    Capsule().fill(Color.white.opacity(0.50)).frame(width: 62, height: 6)
                }
            }
        }
        .frame(width: 220, height: 260)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private func featureRow(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ViewerTheme.detailText)
                .frame(width: 28, height: 28)
                .background(ViewerTheme.detailPanelStrong)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ViewerTheme.detailText)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(ViewerTheme.detailTextSoft)
            }
        }
    }
}
