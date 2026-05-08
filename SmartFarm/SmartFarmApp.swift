//
//  SmartFarmApp.swift
//  SmartFarm
//
//  Created by Davy on 7/5/26.
//

import SwiftUI

@main
struct SmartFarmApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
