import SwiftUI

/// The window's actual root content (see `SmartFarmApp`), shown in place of
/// `MainTabView` so onboarding renders truly full-screen — with no tab bar
/// underneath it. Shows `AppWelcomeView` first on every launch; tapping its
/// start button fades/slides into `MainTabView`.
struct RootView: View {
    @State private var showOnboarding = true

    var body: some View {
        ZStack {
            if showOnboarding {
                AppWelcomeView(onStart: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showOnboarding = false
                    }
                })
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AppEnvironment(persistence: .preview))
    }
}
