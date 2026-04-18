// Purpose: Allows user to configure nutrient tracking preferences and persist settings.
// HLFR: The system shall allow users to modify application settings and personal goals.

import SwiftUI

/// Settings screen
struct SettingsView: View {
    @ObservedObject var vm: MealPlannerViewModel
<<<<<<< HEAD
    @State private var showCalculator = false

=======
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showGoalCalculator = false
    
>>>>>>> 480e894 (feat: add localization support and fix ViewModel/type mismatches)
    var body: some View {
        Form {
            LanguagePickerView()
                .padding(.vertical, 8)
            Toggle("Track Calories", isOn: $vm.trackCalories)
            Toggle("Track Protein", isOn: $vm.trackProtein)
            Toggle("Track Fat", isOn: $vm.trackFat)
            Toggle("Track Carbs", isOn: $vm.trackCarbs)
<<<<<<< HEAD
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
=======
            Section(header: Text("Goals")) {
                Button {
                    showGoalCalculator = true
                } label: {
                    HStack {
                        Image(systemName: "bolt.heart")
                        Text("Calculate Goals (TDEE)")
                    }
                }
            }
        }
        .onDisappear { vm.savePreferences() }
        .navigationTitle(languageManager.text(for: "settings", default: "Settings"))
        .sheet(isPresented: $showGoalCalculator) {
>>>>>>> 480e894 (feat: add localization support and fix ViewModel/type mismatches)
            TDEECalculatorView(vm: vm)
        }
    }
}

