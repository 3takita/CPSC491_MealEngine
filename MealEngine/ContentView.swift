//
//  ContentView.swift
//  ==================
//  Group Members: 
//  ------------------
//  1.	Stephen Anaba as Code Keeper
//

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
            /* NavigationView {
                HistoryView(vm: vm)
            } 
            .tabItem {
                Label("History", systemImage: "calendar")
            }
            .tag(1) */
            
            // Goals Tab
            NavigationView {
                DailyGoalsView(vm: vm)
            }
            .tabItem {
                Label("Goals", systemImage: "target")
            }
            .tag(1) // .tag(2)
            
            // Settings Tab
            /* NavigationView {
                SettingsView(vm: vm)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(3) */
        }
        .accentColor(Theme.primary)
        // VALIDATIOIN alert
        .alert(isPresented: Binding(
            get: { vm.inputErrorMessage != nil },
            set: { _ in vm.inputErrorMessage = nil }
        )) {
            Alert(
                title: Text("Invalid Input"),
                message: Text(vm.inputErrorMessage ?? ""),
                dismissButton: .default(Text("OK"))
        )
    }

        /*.alert(item: $vm.inputErrorMessage) { msg in
            Alert(
                title: Text("Invalid Input"),
                message: Text(msg),
                dismissButton: .default(Text("OK"))
            )
        } */ // end of VALIDATION alert
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
