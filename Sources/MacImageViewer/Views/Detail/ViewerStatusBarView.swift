import SwiftUI

struct ViewerStatusBarView: View {
    @ObservedObject var state: ImageViewerState

    var body: some View {
        HStack(spacing: 12) {
            Text(state.statusText)
                .font(.system(size: 12))
                .foregroundStyle(ViewerTheme.detailTextMuted)
                .lineLimit(1)

            Spacer()

            Text(state.currentFolderName)
                .font(.system(size: 12))
                .foregroundStyle(ViewerTheme.detailTextSoft)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(ViewerTheme.detailPanel.opacity(0.88))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ViewerTheme.detailBorder)
                .frame(height: 1)
        }
    }
}
