import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            GamesLibraryView()
                .tabItem {
                    Label("Games", systemImage: "trophy.fill")
                }
                .tag(1)

            StartRoundView()
                .tabItem {
                    Label("Play", systemImage: "figure.golf")
                }
                .tag(2)

            AnalyticsDashboardView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(.green)
    }
}
