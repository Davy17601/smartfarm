import SwiftUI

/// Central design tokens — colors, spacing, radii, fonts.
/// Semantic colors adapt to light/dark mode automatically.
enum Theme {
    // Brand & semantic colors
    static let brand          = Color.green
    static let income         = Color.green
    static let expense        = Color.red
    static let background      = Color(.systemGroupedBackground)
    static let cardBackground  = Color(.secondarySystemGroupedBackground)
    static let primaryText     = Color(.label)
    static let secondaryText   = Color(.secondaryLabel)

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat  = 8
        static let m: CGFloat  = 16
        static let l: CGFloat  = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat   = 12
        static let button: CGFloat = 10
    }

    enum Fonts {
        static let title   = Font.title2.weight(.bold)
        static let heading = Font.headline
        static let body    = Font.body
        static let caption = Font.caption
        static let amount  = Font.title3.weight(.semibold).monospacedDigit()
    }
}

// MARK: - Reusable modifiers

/// Card container styling: padding, rounded background, subtle shadow.
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.m)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.Radius.card)
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

/// Gentle fade + rise used for list/section appearance.
struct FadeIn: ViewModifier {
    @State private var shown = false
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 8)
            .onAppear {
                withAnimation(.easeOut(duration: 0.25)) { shown = true }
            }
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
    func fadeIn() -> some View { modifier(FadeIn()) }
}

/// Button press scale feedback (replaces default highlight).
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
