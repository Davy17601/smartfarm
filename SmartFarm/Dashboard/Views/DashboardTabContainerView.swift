import SwiftUI

/// Shows `AppWelcomeView` before the real Dashboard/Today tab on every launch.
/// Tapping Continue (or a feature row) reveals the Dashboard for the current
/// session only; a fresh launch resets `showWelcome` back to true. Since
/// Dashboard is the app's default (first) tab, this is what greets the user
/// every time the app opens.
struct DashboardTabContainerView: View {
    let environment: AppEnvironment
    @Binding var selectedTab: Int

    @State private var showWelcome = true
    @State private var showingQuickAddActivity = false

    var body: some View {
        Group {
            if showWelcome {
                AppWelcomeView(
                    onContinue: { showWelcome = false },
                    onFeatureTapped: handleFeatureTapped
                )
            } else {
                DashboardView(environment: environment, selectedTab: $selectedTab)
            }
        }
        .sheet(isPresented: $showingQuickAddActivity) {
            AddEditActivityView(mode: .add(Date())) { environment.activityRepository.add($0) }
        }
    }

    private func handleFeatureTapped(_ action: AppWelcomeView.WelcomeAction) {
        showWelcome = false
        switch action {
        case .previewToday:
            // Dashboard is already tab 0 (the default), so this just confirms it.
            selectedTab = 0
        case .trackActivity:
            selectedTab = 2 // Calendar tab
        case .quickAdd:
            showingQuickAddActivity = true
        }
    }
}

struct DashboardTabContainerView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardTabContainerView(environment: AppEnvironment(persistence: .preview), selectedTab: .constant(0))
    }
}
