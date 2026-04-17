import AppKit
import SwiftUI

enum ViewerTheme {
    static let shellTop = Color(red: 0.95, green: 0.92, blue: 0.88)
    static let shellMiddle = Color(red: 0.87, green: 0.83, blue: 0.79)
    static let shellBottom = Color(red: 0.74, green: 0.70, blue: 0.66)

    static let sidebarBase = Color(red: 0.97, green: 0.95, blue: 0.92)
    static let sidebarCard = Color.white.opacity(0.76)
    static let sidebarAccent = Color(red: 0.80, green: 0.44, blue: 0.20)
    static let sidebarBorder = Color.black.opacity(0.08)
    static let sidebarSelection = Color(red: 0.16, green: 0.16, blue: 0.18)
    static let sidebarSelectionGlow = Color(red: 0.92, green: 0.56, blue: 0.24)
    static let sidebarHover = Color.white.opacity(0.88)
    static let sidebarRow = Color.white.opacity(0.60)
    static let sidebarRowText = Color.black.opacity(0.80)
    static let sidebarRowSecondary = Color.black.opacity(0.48)

    static let detailBase = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let detailPanel = Color.white.opacity(0.06)
    static let detailPanelStrong = Color.white.opacity(0.10)
    static let detailBorder = Color.white.opacity(0.08)
    static let detailTextMuted = Color.white.opacity(0.66)
    static let detailTextSoft = Color.white.opacity(0.52)

    static let actionPrimary = Color(red: 0.95, green: 0.57, blue: 0.24)
    static let actionPrimaryPressed = Color(red: 0.87, green: 0.48, blue: 0.18)
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
