import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("ផ្ទះ", systemImage: "house.fill")
                }

            FinanceTabview()
                .tabItem {
                    Label("ហិរញ្ញវត្ថុ", systemImage: "dollarsign.circle.fill")
                }

            Text("ប្រតិទិន")
                .tabItem {
                    Label("ប្រតិទិន", systemImage: "calendar")
                }

            Text("របាយការណ៍")
                .tabItem {
                    Label("របាយការណ៍", systemImage: "chart.bar.fill")
                }
        }
        .accentColor(Color(red: 0.2, green: 0.6, blue: 0.3))
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
