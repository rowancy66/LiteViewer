import AppKit
import SwiftUI

struct SidebarThumbnailView: View {
    let url: URL
    let thumbnailService: ImageThumbnailService
    let isSelected: Bool

    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.92),
                                    Color(red: 0.92, green: 0.88, blue: 0.84)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Image(systemName: "photo")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Color.black.opacity(0.28))
                }
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    isSelected ? Color.white.opacity(0.48) : Color.black.opacity(0.10),
                    lineWidth: isSelected ? 1.2 : 1
                )
        )
        .shadow(color: isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.15), radius: 3, x: 0, y: 1)
        .onAppear(perform: loadThumbnail)
        .onChange(of: url) { _ in
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        if let cached = thumbnailService.cachedThumbnail(for: url) {
            image = cached
            return
        }

        image = nil
        let currentURL = url.standardizedFileURL
        thumbnailService.loadThumbnail(for: currentURL) { loadedURL, thumbnail in
            guard loadedURL == currentURL else { return }
            image = thumbnail
        }
    }
}
