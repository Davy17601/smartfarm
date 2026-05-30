import SwiftUI

struct MainTabView: View {
   
    var body: some View {
        TabView {
            Text("Dashboard")
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            
            FinanceTabview()
                .tabItem {
                    Label("Finance", systemImage: "dollarsign.circle.fill")
                }
                .tag(0)
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
           
    }
}
