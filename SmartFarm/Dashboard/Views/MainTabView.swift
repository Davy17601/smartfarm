import SwiftUI

struct MainTabView: View {


    @EnvironmentObject var environment: AppEnvironment

    // FinanceCoordinator is created here (root owner) and injected
    // into the entire view hierarchy via .environmentObject(financeCoordinator).
    // Any view can then trigger Finance tab navigation by mutating
    // financeCoordinator.selectedTransactionID.
    // The coordinator's selectedTab property is also bound to the TabView
    // so that Finance's back button can navigate to Dashboard.
    @StateObject private var financeCoordinator = FinanceCoordinator()

    var body: some View {
        ZStack {
            // Content area using TabView (with hidden native tab bar)
            TabView(selection: $financeCoordinator.selectedTab) {
                DashboardView(environment: environment, selectedTab: $financeCoordinator.selectedTab)
                    .tag(0)

                FinanceTabView(repository: environment.transactionRepository)
                    .tag(1)

                ReportsView(repository: environment.transactionRepository)
                    .tag(2)

                SettingsView(environment: environment)
                    .tag(3)
            }
            .onAppear {
                // Hide the native tab bar
                UITabBar.appearance().isHidden = true
            }

            // Custom colorful tab bar at bottom
            VStack {
                Spacer()
                customTabBar
            }
            .ignoresSafeArea(.keyboard)
        }
        .environmentObject(financeCoordinator)
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabBarButton(
                icon: "house.fill",
                label: L("tab.dashboard"),
                color: .blue,
                index: 0
            )

            tabBarButton(
                icon: "chart.bar.fill",
                label: L("tab.finance"),
                color: .red,
                index: 1
            )

            tabBarButton(
                icon: "chart.bar.fill",
                label: "របាយការណ៍",
                color: .green,
                index: 2
            )

            tabBarButton(
                icon: "gearshape.fill",
                label: L("tab.settings"),
                color: .gray,
                index: 3
            )
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            Color(.systemBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabBarButton(icon: String, label: String, color: Color, index: Int) -> some View {
        Button {
            financeCoordinator.selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: financeCoordinator.selectedTab == index ? 24 : 22))
                    .foregroundColor(color)

                Text(label)
                    .font(.system(size: 10, weight: financeCoordinator.selectedTab == index ? .semibold : .regular))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
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
