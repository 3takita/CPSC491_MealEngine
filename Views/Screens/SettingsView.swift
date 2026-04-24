// Purpose: Allows user to configure nutrient tracking preferences and persist settings.
// HLFR: The system shall allow users to modify application settings and personal goals.
// NOTE: Multi-language support removed; reverting to static English strings.

import SwiftUI

/// Settings screen
struct SettingsView: View {
    @ObservedObject var vm: MealPlannerViewModel
    @State private var showGoalCalculator = false

    var body: some View {
        Form {
            Section(header: Text("Tracking")) {
                Toggle("Track Calories", isOn: $vm.trackCalories)
                Toggle("Track Protein", isOn: $vm.trackProtein)
                Toggle("Track Fat", isOn: $vm.trackFat)
                Toggle("Track Carbs", isOn: $vm.trackCarbs)
            }

            Section(header: Text("Goals")) {
                Button {
                    showGoalCalculator = true
                } label: {
                    HStack {
                        Image(systemName: "bolt.heart")
                        Text("Calculate Goals (TDEE)")
                    }
                }
                .foregroundColor(Theme.primary)
            }
        }
        .onDisappear {
            vm.savePreferences()
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showGoalCalculator) {
            TDEECalculatorView(vm: vm)
        }

        // NOTE: Avoid using objectWillChange -> state writes inside the same
        // view hierarchy; it can trigger continuous updates in Form.
    }
}
