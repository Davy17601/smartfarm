import SwiftUI

/// The app's post-onboarding root: 4 tabs (ទំព័រដើម / ប្រតិទិន / ការជូនដំណឹង /
/// ការកំណត់ — no account tab, this app has no login) switched by a custom
/// floating bottom bar instead of the system `TabView` chrome.
///
/// All 4 tabs are kept mounted in the `ZStack` below (toggling only
/// opacity/hit-testing) rather than switched in an `if`/`switch`, so each
/// tab's `@StateObject` view model — and whatever state it holds — survives
/// switching away and back, the same as `TabView` would.
///
/// Laid out as a `VStack` (content, then the bar) rather than a `ZStack`
/// overlay, so the bar reserves its own real row of space at the bottom:
/// scrolled content in any tab stops above it and nothing can end up hidden
/// behind it, with no per-tab padding changes needed.
struct MainTabView: View {
    @EnvironmentObject var environment: AppEnvironment

    // FinanceCoordinator is created here (root owner) and injected into the
    // whole tab hierarchy via .environmentObject(...) — the Home screen's
    // "ហិរញ្ញវត្ថុ" tile presents `FinanceTabView` in a sheet, which reads
    // this coordinator from the environment it inherits.
    @StateObject private var financeCoordinator = FinanceCoordinator()

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                tab(DashboardTabContainerView(environment: environment, selectedTab: $environment.selectedTab),
                    target: .home)
                tab(CalendarTabContainerView(activityRepository: environment.activityRepository,
                                              reminderRepository: environment.reminderRepository),
                    target: .calendar)
                tab(NotificationsTabContainerView(activityRepository: environment.activityRepository,
                                                   reminderRepository: environment.reminderRepository),
                    target: .notifications)
                tab(SettingsView(environment: environment),
                    target: .settings)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(selectedTab: $environment.selectedTab)
        }
        .environmentObject(financeCoordinator)
        // Several grid-tile/pastel colors on the Home screen and this bar
        // are fixed hex values (not `Theme`'s dark-mode-adaptive colors), so
        // forced light mode keeps them looking right for now — see CLAUDE.md.
        .preferredColorScheme(.light)
        // A tapped local notification belongs to the Calendar module — switch to it.
        .onReceive(NotificationService.shared.$tappedItemID) { id in
            if id != nil {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    environment.selectedTab = .calendar
                }
            }
        }
    }

    /// Keeps `content` mounted at all times; only the selected tab is
    /// visible and interactive.
    private func tab<Content: View>(_ content: Content, target: AppTab) -> some View {
        content
            .opacity(environment.selectedTab == target ? 1 : 0)
            .allowsHitTesting(environment.selectedTab == target)
            .accessibilityHidden(environment.selectedTab != target)
    }
}

/// Floating rounded bottom bar: white background, 4 tabs, a green capsule
/// behind the selected one. Replaces the system `TabView` bar entirely
/// (never shown on the onboarding screen, since that's a separate branch of
/// `RootView` where `MainTabView` doesn't exist yet).
private struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    private let selectedGreen   = Color(red: 0x2E / 255, green: 0x7D / 255, blue: 0x32 / 255)
    private let unselectedColor = Color(red: 0x7A / 255, green: 0x8F / 255, blue: 0x7C / 255)

    private struct Item {
        let tab: AppTab
        let icon: String
        let labelKey: String
    }

    private let items: [Item] = [
        Item(tab: .home, icon: "house.fill", labelKey: "tab.home"),
        Item(tab: .calendar, icon: "calendar", labelKey: "tab.calendar"),
        Item(tab: .notifications, icon: "bell.fill", labelKey: "notifications.title"),
        Item(tab: .settings, icon: "gearshape.fill", labelKey: "tab.settings")
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.tab) { item in
                tabButton(item)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.14), radius: 16, x: 0, y: 6)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func tabButton(_ item: Item) -> some View {
        let isSelected = selectedTab == item.tab
        return Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = item.tab
            }
        }) {
            VStack(spacing: 3) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(L(item.labelKey))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isSelected ? .white : unselectedColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? selectedGreen : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppEnvironment(persistence: .preview))
    }
}
