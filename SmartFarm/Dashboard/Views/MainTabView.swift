import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var farmViewModel: FarmViewModel

    var body: some View {
        TabView {
            Text("Dashboard")
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            
            Text("Finance")
                .tabItem {
                    Label("Finance", systemImage: "dollarsign.circle.fill")
                }
            Text("Calendar")
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            Text("Setting")
                .tabItem {
                    Label("Setting", systemImage: "gearshape.fill")
                }
            
           
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(FarmViewModel())
    }
}
