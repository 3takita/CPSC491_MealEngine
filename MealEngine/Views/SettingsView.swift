// Purpose: Allows user to configure nutrient tracking preferences and persist settings.
// HLFR: The system shall allow users to modify application settings and personal goals.

import SwiftUI

/// Settings screen
struct SettingsView: View {
    @ObservedObject var vm: MealPlannerViewModel
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        Form {
            Toggle(languageManager.text(for: "track_calories"), isOn: $vm.trackCalories)
            Toggle(languageManager.text(for: "track_protein"), isOn: $vm.trackProtein)
            Toggle(languageManager.text(for: "track_fat"), isOn: $vm.trackFat)
            Toggle(languageManager.text(for: "track_carbs"), isOn: $vm.trackCarbs)
        }
        .onDisappear { vm.savePreferences() }
        .navigationTitle(languageManager.text(for: "settings"))
    }
}
