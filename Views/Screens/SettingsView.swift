// Purpose: Allows user to configure nutrient tracking preferences and persist settings.
// HLFR: The system shall allow users to modify application settings and personal goals.
// NOTE: Multi-language support removed; reverting to static English strings.

import SwiftUI

/// Settings screen
struct SettingsView: View {
    @ObservedObject var vm: MealPlannerViewModel
    @State private var showGoalCalculator = false
    @State private var showDietaryPicker = false

    var body: some View {
        Form {
            Section(header: Text("Tracking")) {
                Toggle("Track Calories", isOn: $vm.trackCalories)
                Toggle("Track Protein", isOn: $vm.trackProtein)
                Toggle("Track Fat", isOn: $vm.trackFat)
                Toggle("Track Carbs", isOn: $vm.trackCarbs)
            }
            
            Section(header: Text("Dietary Preferences")) {
                if vm.dietaryProfile.restrictions.isEmpty {
                    Text("None selected")
                        .foregroundColor(Theme.textSecondary)
                }
                else {
                    ForEach(Array(vm.dietaryProfile.restrictions), id: \.self) {
                        r in HStack {
                            Image(systemName: r.icon).foregroundColor(Theme.primary)
                                Text(r.rawValue)
                        }
                    }
                }
                Button {
                    showDietaryPicker = true
                }
                label: {
                    HStack {
                        Image(systemName: "leaf")
                        Text("Edit Preferences")
                    }
                }
                .foregroundColor(Theme.primary)
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
        .sheet(isPresented: $showDietaryPicker) {       // ← add
            DietaryPickerSheet(vm: vm)
        }
        // NOTE: Avoid using objectWillChange -> state writes inside the same
        // view hierarchy; it can trigger continuous updates in Form.
    }
}
private struct DietaryPickerSheet: View {
    @ObservedObject var vm: MealPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(DietaryRestriction.allCases) { restriction in
                        let isOn = vm.dietaryProfile.restrictions.contains(restriction)
                        Button {
                            if isOn { vm.dietaryProfile.restrictions.remove(restriction) }
                            else    { vm.dietaryProfile.restrictions.insert(restriction) }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: restriction.icon)
                                    .font(.caption)
                                    .foregroundColor(isOn ? Theme.primary : Theme.textSecondary)
                                Text(restriction.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(isOn ? Theme.primary : Theme.textPrimary)
                                Spacer()
                                if isOn {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundColor(Theme.primary)
                                }
                            }
                            .padding(12)
                            .background(isOn ? Theme.primary.opacity(0.07) : Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isOn ? Theme.primary.opacity(0.4) : Color(.systemGray4), lineWidth: isOn ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: isOn)
                    }
                }
                .padding()
            }
            .navigationTitle("Dietary Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        vm.saveDietaryProfile()
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(Theme.primary)
                }
            }
        }
    }
}
