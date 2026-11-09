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

    init() {
        // List/Form screens are backed by UITableView pre-iOS16, which paints its
        // own opaque background beneath any SwiftUI `.background()` modifier — set
        // it here so the app's soft-green background shows through consistently.
        UITableView.appearance().backgroundColor = UIColor(Theme.background)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(environment)
                .environmentObject(localization)
                .environmentObject(settings)
                .environment(\.locale, localization.language.locale)
                // Rebuild the whole tree when the language changes so every
                // L(key) re-evaluates (live switch). See LocalizationManager.
                .id(localization.language)
        }
    }
}
