// This is the root UI

import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            NavigationStack {
                PlannerView(vm: appState.plannerVM)
            }
            .tabItem {
                Label("Planner", systemImage: "fork.knife")
            }
            .tag(0)

            NavigationStack {
                HistoryView(vm: appState.plannerVM)
            }
            .tabItem {
                Label("History", systemImage: "calendar")
            }
            .tag(1)

            NavigationStack {
                DailyGoalsView(vm: appState.goalsVM)
            }
            .tabItem {
                Label("Goals", systemImage: "target")
            }
            // keep goals in sync when viewing Goals tab
            .onAppear {
                appState.goalsVM.sync(from: appState.plannerVM)
            }
            .tag(2)

            NavigationStack {
                SettingsView(vm: appState.plannerVM)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            // keep data connected without shared mutation chaos
            .onAppear {
                appState.goalsVM.sync(from: appState.plannerVM)
            }
            .tag(3)
        }
    }
}

