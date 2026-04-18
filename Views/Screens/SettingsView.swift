// Purpose: Allows user to configure nutrient tracking preferences and persist settings.
// HLFR: The system shall allow users to modify application settings and personal goals.

import SwiftUI

/// Settings screen
struct SettingsView: View {
    @ObservedObject var vm: MealPlannerViewModel
    @State private var showCalculator = false

    var body: some View {
        Form {
            Toggle("Track Calories", isOn: $vm.trackCalories)
            Toggle("Track Protein", isOn: $vm.trackProtein)
            Toggle("Track Fat", isOn: $vm.trackFat)
            Toggle("Track Carbs", isOn: $vm.trackCarbs)
            Section {
                Button("Open Goal Calculator") {
                    showCalculator = true
                }
                .foregroundColor(Theme.primary)
            }
        }
        .onDisappear { vm.savePreferences() }
        .navigationTitle("Settings")
        .sheet(isPresented: $showCalculator) {
            TDEECalculatorView(vm: vm)
        }
    }
}
