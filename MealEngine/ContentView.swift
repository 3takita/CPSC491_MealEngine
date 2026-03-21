/*
PURPOSE: Main container view of the application. Coordinates navigation between primary screens like planner, history, settings view.
HLFR: Supports All HLFRs (Entry point UI coordination)
*/

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var vm = MealPlannerViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            LanguagePickerView()
                .padding(.top, 8)
            
            TabView(selection: $selectedTab) {
                // Planner Tab
                NavigationView {
                    PlannerView(vm: vm)
                }
                .tabItem {
                    Label(languageManager.text(for: "planner"), systemImage: "fork.knife")
                }
                .tag(0)
                
                // History Tab
                NavigationView {
                    HistoryView(vm: vm)
                }
                .tabItem {
                    Label(languageManager.text(for: "history"), systemImage: "calendar")
                }
                .tag(1)
                
                // Goals Tab
                NavigationView {
                    DailyGoalsView(vm: vm)
                }
                .tabItem {
                    Label(languageManager.text(for: "goals"), systemImage: "target")
                }
                .tag(2)
                
                // Settings Tab
                NavigationView {
                    SettingsView(vm: vm)
                }
                .tabItem {
                    Label(languageManager.text(for: "settings"), systemImage: "gearshape")
                }
                .tag(3)
            }
        }
        .accentColor(Theme.primary)
        .alert(item: $vm.inputErrorMessage) { msg in
            Alert(
                title: Text(languageManager.text(for: "invalid_input")),
                message: Text(msg),
                dismissButton: .default(Text(languageManager.text(for: "ok")))
            )
        }
        .onAppear {
            vm.updateTodayProgress()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LanguageManager())
        .preferredColorScheme(.light)
}
