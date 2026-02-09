//  ContentView.swift
//  ==================
//  Functional Requirement:- The system shall provide a container view for navigation hierarchy.
//  Non-functional Requirement:- Acts as Root routing point

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
            
            // Goals Tab
            NavigationView {
                DailyGoalsView(vm: vm)
            }
            .tabItem {
                Label("Goals", systemImage: "target")
            }
            .tag(1)
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
