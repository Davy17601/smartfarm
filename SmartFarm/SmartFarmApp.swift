//
//  SmartFarmApp.swift
//  SmartFarm
//
//  Created by Davy on 7/5/26.
//

import SwiftUI

@main
struct SmartFarmApp: App {
    @StateObject private var environment = AppEnvironment()
    @StateObject private var localization = LocalizationManager.shared
    @StateObject private var settings = AppSettings.shared
    @State private var showOnboarding: Bool = true

    var body: some Scene {
        WindowGroup {
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
                    .transition(.opacity)
            } else {
                MainTabView()
                    .environmentObject(environment)
                    .environmentObject(localization)
                    .environmentObject(settings)
                    .environment(\.locale, localization.language.locale)
                    // Rebuild the whole tree when the language changes so every
                    // L(key) re-evaluates (live switch). See LocalizationManager.
                    .id(localization.language)
                    .transition(.opacity)
            }
        }
    }
}
