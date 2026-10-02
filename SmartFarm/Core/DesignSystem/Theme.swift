import SwiftUI

/// Central design tokens — colors, spacing, radii, fonts.
/// Semantic colors adapt to light/dark mode automatically.
enum Theme {
    // Brand & semantic colors
    static let brand           = Color("AppPrimary")
    static let brandSecondary  = Color("AppSecondary")
    /// Darker, higher-contrast shade of `brand` for headline text on light
    /// backgrounds (e.g. the Calendar tab's title and month label) — lightens
    /// back toward `brand` in dark mode so it stays legible there too.
    static let brandDeep       = Color("AppPrimaryDeep")
    static let highlight       = Color("AppHighlight")
    static let income          = Color.green
    static let expense         = Color.red
    static let background      = Color("AppBackground")
    static let cardBackground  = Color("AppCardBackground")
    static let primaryText     = Color(.label)
    static let secondaryText   = Color(.secondaryLabel)

    /// Fixed accent colors for farm-activity categories — same in light & dark mode.
    enum Category {
        static let blue   = Color("CategoryBlue")
        static let orange = Color("CategoryOrange")
        static let purple = Color("CategoryPurple")
        static let amber  = Color("CategoryAmber")
        static let green  = Color("CategoryGreen")

        /// Pale background tints for category cards — adapted per-mode so they
        /// stay visible (not washed out) against the dark card background.
        static let blueTint   = Color("CategoryBlueTint")
        static let orangeTint = Color("CategoryOrangeTint")
        static let purpleTint = Color("CategoryPurpleTint")
        static let amberTint  = Color("CategoryAmberTint")
        static let greenTint  = Color("CategoryGreenTint")
    }

    /// Background tint for reminder cards (paired with `brand`), adapted per-mode.
    static let reminderTint = Color("ReminderTint")

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

/// Presentation mapping — `FarmActivityCategory` is a plain Foundation model
/// type, so its accent color lives here in the DesignSystem layer.
extension FarmActivityCategory {
    var color: Color {
        switch self {
        case .watering:    return Theme.Category.blue
        case .fertilizing: return Theme.Category.orange
        case .care:        return Theme.Category.purple
        case .harvest:     return Theme.Category.amber
        case .planting:    return Theme.Category.green
        }
    }

    /// Pale card background tint matching this category's accent color.
    var tintColor: Color {
        switch self {
        case .watering:    return Theme.Category.blueTint
        case .fertilizing: return Theme.Category.orangeTint
        case .care:        return Theme.Category.purpleTint
        case .harvest:     return Theme.Category.amberTint
        case .planting:    return Theme.Category.greenTint
        }
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
