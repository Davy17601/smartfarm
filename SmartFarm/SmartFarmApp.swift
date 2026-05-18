//
//  SmartFarmApp.swift
//  SmartFarm
//
//  Created by Davy on 7/5/26.
//

import SwiftUI

@main
struct SmartFarmApp: App {
    @StateObject private var farmViewModel = FarmManager.createViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(farmViewModel)
        }
    }
}
