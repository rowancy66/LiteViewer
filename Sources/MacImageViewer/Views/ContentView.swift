import SwiftUI

struct ContentView: View {
    @ObservedObject var state: ImageViewerState

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ViewerTheme.shellTop,
                    ViewerTheme.shellMiddle,
                    ViewerTheme.shellBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            HSplitView {
                ImageSidebarView(
                    state: state,
                    thumbnailService: state.thumbnailService
                )
                .frame(minWidth: 260, idealWidth: 298, maxWidth: 360)

                ViewerDetailView(state: state)
                    .frame(minWidth: 620, maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.22), radius: 26, x: 0, y: 18)
            .padding(18)
        }
        .frame(minWidth: 980, minHeight: 660)
    }
}
