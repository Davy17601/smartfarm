import SwiftUI

/// One-time onboarding screen shown before the Calendar tab's first use.
struct CalendarWelcomeView: View {
    let onContinue: () -> Void

    private struct Feature {
        let systemImage: String
        let title: String
        let subtitle: String
    }

    private var features: [Feature] {
        [
            Feature(systemImage: "calendar.badge.clock",
                    title: L("calendar.welcome.feature1.title"),
                    subtitle: L("calendar.welcome.feature1.subtitle")),
            Feature(systemImage: "bell.badge.fill",
                    title: L("calendar.welcome.feature2.title"),
                    subtitle: L("calendar.welcome.feature2.subtitle")),
            Feature(systemImage: "link.circle.fill",
                    title: L("calendar.welcome.feature3.title"),
                    subtitle: L("calendar.welcome.feature3.subtitle"))
        ]
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            RoundedRectangle(cornerRadius: Theme.Radius.card * 2, style: .continuous)
                .fill(Theme.expense)
                .frame(width: 96, height: 96)
                .overlay(
                    Image(systemName: "calendar")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(.white)
                )

            VStack(spacing: Theme.Spacing.xs) {
                Text(L("calendar.welcome.titleLine1"))
                    .font(Theme.Fonts.title)
                    .foregroundColor(Theme.primaryText)
                Text(L("calendar.welcome.titleLine2"))
                    .font(Theme.Fonts.title)
                    .foregroundColor(Theme.primaryText)
            }
            .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                ForEach(features, id: \.title) { feature in
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: feature.systemImage)
                            .font(.system(size: 22))
                            .foregroundColor(Theme.brand)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title)
                                .font(Theme.Fonts.heading)
                                .foregroundColor(Theme.primaryText)
                            Text(feature.subtitle)
                                .font(Theme.Fonts.caption)
                                .foregroundColor(Theme.secondaryText)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)

            Spacer()

            PrimaryButton(title: L("calendar.welcome.continue"), action: onContinue)
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.l)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.edgesIgnoringSafeArea(.all))
    }
}

struct CalendarWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarWelcomeView(onContinue: {})
    }
}
