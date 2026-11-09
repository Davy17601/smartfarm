import SwiftUI

/// Owns the Dashboard tab's own "quick add" sheet state, independent of
/// which tab is selected, and passes it through to `DashboardView`.
///
/// Onboarding used to be gated here, but that nested it inside `MainTabView`
/// so the tab bar showed through behind it — it's now owned by `RootView`
/// instead, shown before `MainTabView` exists at all. See `App/RootView.swift`.
struct DashboardTabContainerView: View {
    let environment: AppEnvironment
    @Binding var selectedTab: AppTab

    @State private var addingActivity = false

    var body: some View {
        DashboardView(environment: environment, selectedTab: $selectedTab, addingActivity: $addingActivity)
    }
}

struct DashboardTabContainerView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardTabContainerView(environment: AppEnvironment(persistence: .preview), selectedTab: .constant(.home))
    }
}
