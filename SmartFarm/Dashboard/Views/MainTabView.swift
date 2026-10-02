import SwiftUI

struct MainTabView: View {
    
    
    @EnvironmentObject var environment: AppEnvironment
    @State private var selectedTab = 0

    // FinanceCoordinator is created here (root owner) and injected
    // into the entire view hierarchy via .environmentObject(financeCoordinator).
    // Any view can then trigger Finance tab navigation by mutating
    // financeCoordinator.selectedTransactionID.
    @StateObject private var financeCoordinator = FinanceCoordinator()

    /// Every tab uses the app's green identity (matching the Welcome screen
    /// and Calendar tab) for its selected tab-bar icon — `TabView`'s
    /// selected-item tint isn't reliably driven by a per-tab `.accentColor()`
    /// modifier, so it's set explicitly here on appear and on every tab change.
    private static let selectedTint = UIColor(red: 0x2E / 255, green: 0x7D / 255, blue: 0x4F / 255, alpha: 1)

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardTabContainerView(environment: environment, selectedTab: $selectedTab)
                .tabItem {
                    Label(L("tab.dashboard"), systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            CalendarTabContainerView(activityRepository: environment.activityRepository,
                                      reminderRepository: environment.reminderRepository)
                .tabItem {
                    Label(L("tab.calendar"), systemImage: "calendar")
                }
                .tag(2)

            SettingsView(environment: environment)
                .tabItem {
                    Label(L("tab.settings"), systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .environmentObject(financeCoordinator)
        // A tapped local notification belongs to the Calendar module — switch to it.
        .onReceive(NotificationService.shared.$tappedItemID) { id in
            if id != nil { selectedTab = 2 }
        }
        .onAppear { updateTabBarTint() }
        .onChange(of: selectedTab) { _ in updateTabBarTint() }
    }

    private func updateTabBarTint() {
        let color = Self.selectedTint
        UITabBar.appearance().tintColor = color
        // The appearance proxy only styles newly created tab bars, so the
        // already-live one needs its `tintColor` set directly to actually
        // recolor the selected item when switching tabs.
        DispatchQueue.main.async {
            let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
            findTabBar(in: keyWindow)?.tintColor = color
        }
    }
}

private func findTabBar(in view: UIView?) -> UITabBar? {
    guard let view = view else { return nil }
    if let tabBar = view as? UITabBar { return tabBar }
    for subview in view.subviews {
        if let found = findTabBar(in: subview) { return found }
    }
    return nil
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppEnvironment(persistence: .preview))
    }
}
