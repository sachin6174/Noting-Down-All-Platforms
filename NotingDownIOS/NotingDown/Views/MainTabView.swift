import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            ContentView()
                .tabItem {
                    Image(systemName: "note.text")
                    Text("Notes")
                }
                .tag(1)
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Analytics")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(Theme.primaryGreen)
    }
}
