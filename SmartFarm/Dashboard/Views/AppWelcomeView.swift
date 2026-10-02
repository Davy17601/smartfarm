import SwiftUI

/// One-time onboarding screen shown before the Dashboard/Today tab's first use.
/// Since Dashboard is the app's default tab, this is effectively the app's
/// first-run welcome screen. Colors/illustration here are local to this view
/// only — scoped, like `CalendarTheme`, so no other screen's palette changes.
struct AppWelcomeView: View {
    /// A shortcut the user can jump to directly from a feature row, in
    /// addition to just dismissing the welcome screen via "បន្ត".
    enum WelcomeAction {
        case previewToday
        case trackActivity
        case quickAdd
    }

    let onContinue: () -> Void
    let onFeatureTapped: (WelcomeAction) -> Void

    private let deepGreen  = Color(red: 0x2E / 255, green: 0x7D / 255, blue: 0x4F / 255)
    private let blueAccent = Color(red: 0x3B / 255, green: 0x82 / 255, blue: 0xC4 / 255)

    private struct Feature {
        let systemImage: String
        let title: String
        let subtitle: String
        let action: WelcomeAction
        let iconColor: Color
        let badgeBackground: Color
        let cardTint: Color
    }

    private var features: [Feature] {
        [
            Feature(systemImage: "eye.fill",
                    title: L("appWelcome.feature1.title"),
                    subtitle: L("appWelcome.feature1.subtitle"),
                    action: .previewToday,
                    iconColor: deepGreen,
                    badgeBackground: deepGreen.opacity(0.15),
                    cardTint: deepGreen.opacity(0.08)),
            Feature(systemImage: "calendar",
                    title: L("appWelcome.feature2.title"),
                    subtitle: L("appWelcome.feature2.subtitle"),
                    action: .trackActivity,
                    iconColor: blueAccent,
                    badgeBackground: blueAccent.opacity(0.15),
                    cardTint: blueAccent.opacity(0.08)),
            Feature(systemImage: "plus",
                    title: L("appWelcome.feature3.title"),
                    subtitle: L("appWelcome.feature3.subtitle"),
                    action: .quickAdd,
                    iconColor: .white,
                    badgeBackground: deepGreen,
                    cardTint: Color(red: 0xFB / 255, green: 0xF3 / 255, blue: 0xDD / 255))
        ]
    }

    var body: some View {
        ZStack {
            backgroundIllustration

            VStack(spacing: Theme.Spacing.l) {
                Spacer(minLength: Theme.Spacing.xl)

                RoundedRectangle(cornerRadius: Theme.Radius.card * 2, style: .continuous)
                    .fill(deepGreen)
                    .frame(width: 92, height: 92)
                    .overlay(calendarLeafIcon)

                titleCard

                VStack(spacing: Theme.Spacing.s) {
                    ForEach(features, id: \.title) { feature in
                        featureRow(feature)
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)

                Spacer()

                continueButton
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.bottom, Theme.Spacing.l)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Badge icon

    /// A calendar glyph filling most of the badge, with a small circular
    /// leaf badge overlapping its bottom-right corner (notification-badge
    /// style) to tie the "activity calendar" idea back to the farm theme.
    private var calendarLeafIcon: some View {
        Image(systemName: "calendar")
            .font(.system(size: 52, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 92, height: 92)
            .overlay(leafBadge, alignment: .bottomTrailing)
    }

    private var leafBadge: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 30, height: 30)
            .overlay(
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(deepGreen)
            )
            .overlay(
                Circle().stroke(deepGreen, lineWidth: 2)
            )
            .offset(x: -8, y: -8)
    }

    // MARK: - Title

    private var titleCard: some View {
        VStack(spacing: 6) {
            Text(L("appWelcome.titleLine1"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(deepGreen)
            Text(L("appWelcome.titleLine2"))
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(deepGreen)
            Text(L("appWelcome.tagline"))
                .font(.system(size: 13))
                .foregroundColor(Theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card * 1.5, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .padding(.horizontal, Theme.Spacing.l)
    }

    // MARK: - Feature row

    private func featureRow(_ feature: Feature) -> some View {
        Button {
            onFeatureTapped(feature.action)
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                Circle()
                    .fill(feature.badgeBackground)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: feature.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(feature.iconColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.title)
                        .font(Theme.Fonts.heading)
                        .foregroundColor(feature.iconColor == .white ? deepGreen : feature.iconColor)
                    Text(feature.subtitle)
                        .font(Theme.Fonts.caption)
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.secondaryText.opacity(0.5))
            }
            .padding(Theme.Spacing.m)
            // The tint alone (8-15% opacity) was designed against the old
            // pastel shape background — against the photo it's nearly
            // transparent and the row disappears, so a near-opaque white
            // base goes behind it here (not over the whole image) to keep
            // the icon/text legible.
            .background(feature.cardTint)
            .background(Color.white.opacity(0.92))
            .cornerRadius(Theme.Radius.card)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Continue button

    private var continueButton: some View {
        Button(action: onContinue) {
            HStack(spacing: Theme.Spacing.s) {
                Text(L("appWelcome.continue"))
                    .font(.system(size: 17, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.m)
            .background(deepGreen)
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Background illustration

    /// Full-bleed photo background (a rice-paddy landscape under a rainbow),
    /// filling and cropping to the screen behind all the foreground content.
    private var backgroundIllustration: some View {
        GeometryReader { geo in
            Image("anime-rainbow-landscape")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct AppWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        AppWelcomeView(onContinue: {}, onFeatureTapped: { _ in })
    }
}
