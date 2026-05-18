//
//  ContentView.swift
//  SmartFarm
//
//  Created by Davy on 7/5/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(FarmViewModel())
    }
}
