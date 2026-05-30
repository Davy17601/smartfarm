import SwiftUI

struct MainTabView: View {
    
    
    @EnvironmentObject var environment: AppEnvironment
    @State private var selectedTab = 0
    
    // FinanceCoordinator is created here (root owner) and injected
    // into the entire view hierarchy via .environmentObject(financeCoordinator).
    // Any view can then trigger Finance tab navigation by mutating
    // financeCoordinator.selectedTransactionID.
    @StateObject private var financeCoordinator = FinanceCoordinator()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(environment: environment, selectedTab: $selectedTab)
                .tabItem {
                    Label(L("tab.dashboard"), systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            FinanceTabView(repository: environment.transactionRepository)
                .tabItem {
                    Label(L("tab.finance"), systemImage: "dollarsign.circle.fill")
                }
                .tag(1)
            CalendarTabView(activityRepository: environment.activityRepository,
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
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppEnvironment(persistence: .preview))
    }
}
