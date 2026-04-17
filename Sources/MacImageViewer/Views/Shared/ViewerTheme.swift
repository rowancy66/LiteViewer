import AppKit
import SwiftUI

enum ViewerTheme {
    static let shellTop = Color(red: 0.96, green: 0.96, blue: 0.93)
    static let shellMiddle = Color(red: 0.90, green: 0.91, blue: 0.88)
    static let shellBottom = Color(red: 0.82, green: 0.85, blue: 0.82)

    static let sidebarBase = Color(red: 0.95, green: 0.95, blue: 0.92)
    static let sidebarCard = Color.white.opacity(0.78)
    static let sidebarAccent = Color(red: 0.39, green: 0.53, blue: 0.63)
    static let sidebarBorder = Color.black.opacity(0.08)
    static let sidebarSelection = Color(red: 0.36, green: 0.47, blue: 0.57)
    static let sidebarSelectionGlow = Color(red: 0.65, green: 0.77, blue: 0.83)
    static let sidebarHover = Color.white.opacity(0.88)
    static let sidebarRow = Color.white.opacity(0.60)
    static let sidebarRowText = Color.black.opacity(0.80)
    static let sidebarRowSecondary = Color.black.opacity(0.48)

    static let detailBaseTop = Color(red: 0.94, green: 0.95, blue: 0.93)
    static let detailBaseBottom = Color(red: 0.86, green: 0.89, blue: 0.88)
    static let detailCanvasTop = Color(red: 0.92, green: 0.93, blue: 0.92)
    static let detailCanvasBottom = Color(red: 0.80, green: 0.84, blue: 0.84)
    static let detailPanel = Color.white.opacity(0.66)
    static let detailPanelStrong = Color.white.opacity(0.92)
    static let detailBorder = Color.black.opacity(0.08)
    static let detailText = Color.black.opacity(0.82)
    static let detailTextMuted = Color.black.opacity(0.64)
    static let detailTextSoft = Color.black.opacity(0.46)

    static let actionPrimary = Color(red: 0.41, green: 0.57, blue: 0.67)
    static let actionPrimaryPressed = Color(red: 0.33, green: 0.48, blue: 0.58)
}

struct ViewerCapsuleButtonStyle: ButtonStyle {
    var highlighted: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .foregroundStyle(highlighted ? Color.white : ViewerTheme.detailTextMuted)
            .clipShape(Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(highlighted ? Color.clear : ViewerTheme.detailBorder, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if highlighted {
            return isPressed ? ViewerTheme.actionPrimaryPressed : ViewerTheme.actionPrimary
        }

        return isPressed ? ViewerTheme.detailPanelStrong : ViewerTheme.detailPanel
    }
}

struct ViewerPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(ViewerTheme.detailPanel)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ViewerTheme.detailBorder, lineWidth: 1)
            )
    }
}
