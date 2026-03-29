/*
PURPOSE: Main container view of the application. Coordinates navigation between primary screens like planner, history, settings view.
HLFR: Supports All HLFRs (Entry point UI coordination)
*/

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = MealPlannerViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Planner Tab
            NavigationView {
                PlannerView(vm: vm)
            }
            .tabItem {
                Label("Planner", systemImage: "fork.knife")
            }
            .tag(0)
            
            // History Tab
            NavigationView {
                HistoryView(vm: vm)
            }
            .tabItem {
                Label("History", systemImage: "calendar")
            }
            .tag(1)
            
            // Goals Tab
            NavigationView {
                DailyGoalsView(vm: vm)
            }
            .tabItem {
                Label("Goals", systemImage: "target")
            }
            .tag(2)
            
            // Settings Tab
            NavigationView {
                SettingsView(vm: vm)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(3)
        }
        .accentColor(Theme.primary)
        // VALIDATION alert
        .alert(
            isPresented: Binding<Bool>(
                get: { vm.inputErrorMessage != nil },
                set: { newValue in if !newValue { vm.inputErrorMessage = nil } }
            )
        ) {
            Alert(
                title: Text("Invalid Input"),
                message: Text(vm.inputErrorMessage ?? ""),
                dismissButton: .default(Text("OK"), action: { vm.inputErrorMessage = nil })
            )
        } // end of VALIDATION alert
        .onAppear {
            // Update today's progress when app appears
            vm.updateTodayProgress()
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.light)
}
