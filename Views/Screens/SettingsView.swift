// Purpose: Allows user to configure nutrient tracking preferences and persist settings.
// HLFR: The system shall allow users to modify application settings and personal goals.
// NOTE: Multi-language support removed; reverting to static English strings.

import SwiftUI

/// Settings screen
struct SettingsView: View {
    @ObservedObject var vm: MealPlannerViewModel
<<<<<<< HEAD
<<<<<<< HEAD
    @State private var showCalculator = false

=======
    @EnvironmentObject var languageManager: LanguageManager
=======
>>>>>>> 58588a8 ((feat) Remove multi-language feature and revert to static English UI)
    @State private var showGoalCalculator = false
    
>>>>>>> 480e894 (feat: add localization support and fix ViewModel/type mismatches)
    var body: some View {
        // Settings are grouped in a Form. Language changes propagate via EnvironmentObject without manual state wiring.
        Form {
<<<<<<< HEAD
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
=======
            Section(header: Text("Tracking")) {
                Toggle("Track Calories", isOn: $vm.trackCalories)
                Toggle("Track Protein", isOn: $vm.trackProtein)
                Toggle("Track Fat", isOn: $vm.trackFat)
                Toggle("Track Carbs", isOn: $vm.trackCarbs)
            }
>>>>>>> 58588a8 ((feat) Remove multi-language feature and revert to static English UI)
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
        .navigationTitle("Settings") // Localization removed; using static title
        .sheet(isPresented: $showGoalCalculator) {
>>>>>>> 480e894 (feat: add localization support and fix ViewModel/type mismatches)
            TDEECalculatorView(vm: vm)
        }
        // NOTE: Avoid using objectWillChange -> state writes inside the same view hierarchy; it can trigger continuous updates in Form.
    }
}

