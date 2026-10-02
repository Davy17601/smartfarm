import SwiftUI

/// Pushed from the Settings screen's "Version" row — a simple static
/// about/credits screen. Uses the same green identity (`deepGreen`) as
/// `SettingsView` and the same calendar+leaf badge composition as
/// `AppWelcomeView`'s icon, so it reads as part of the same app rather than
/// a bolted-on screen.
struct AboutView: View {
    private let deepGreen = Color(red: 0x2E / 255, green: 0x7D / 255, blue: 0x4F / 255)

    /// Falls back to the static "1.0" if the bundle's marketing version is
    /// ever missing (e.g. a stripped test bundle).
    private var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            Spacer(minLength: Theme.Spacing.xl)

            RoundedRectangle(cornerRadius: Theme.Radius.card * 2, style: .continuous)
                .fill(deepGreen)
                .frame(width: 92, height: 92)
                .overlay(badgeIcon)

            VStack(spacing: Theme.Spacing.xs) {
                Text("SmartFarm")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(deepGreen)
                Text(String(format: L("about.version"), versionString))
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.secondaryText)
            }

            Text(L("about.tagline"))
                .font(Theme.Fonts.body)
                .foregroundColor(Theme.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.l)

            Spacer()

            Text(L("about.credit"))
                .font(Theme.Fonts.caption)
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.l)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(L("settings.about"))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Same calendar glyph + leaf badge composition used for the app's icon
    /// badge on `AppWelcomeView` and in `CalendarTabView`'s header.
    private var badgeIcon: some View {
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
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { AboutView() }
    }
}
