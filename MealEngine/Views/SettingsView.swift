/*
Purpose:
Allows user to configure nutrient tracking preferences and persist settings.
HLFR Tied To:
HLFR-4: Preference Management
*/

import SwiftUI

/// Settings screen
struct SettingsView: View {
    @ObservedObject var vm: MealPlannerViewModel
    
    var body: some View {
        Form {
            Toggle("Track Calories", isOn: $vm.trackCalories)
            Toggle("Track Protein", isOn: $vm.trackProtein)
            Toggle("Track Fat", isOn: $vm.trackFat)
            Toggle("Track Carbs", isOn: $vm.trackCarbs)
        }
        .onDisappear { vm.savePreferences() }
        .navigationTitle("Settings")
    }
}
