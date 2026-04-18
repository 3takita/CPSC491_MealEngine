// PURPOSE: Provides the main meal planning interface, allowing users to add, modify, or review meals for the current day.
// HLFR: The system shall allow users to plan and log meals

import SwiftUI

/// Meal Planner screen
struct PlannerView: View {
    @ObservedObject var vm: MealPlannerViewModel
    @State private var showSaveConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Today's Progress Section
                todayProgressCard
                
                // Search & Input Section
                searchSection
                
                // Action Buttons
                actionButtons
                
                // Results Section
                if !vm.chosenFoods.isEmpty {
                    resultsSection
                }
            }
            .padding()
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("MealEngine")
        .alert("Meal Saved!", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) { } // meal saved alert
        } message: {
            Text("Your meal has been added to today's log")
        }
        .alert( // input error alert
            "Input Error",
            isPresented: Binding(
                get: { vm.inputErrorMessage != nil },
                set: { _ in vm.inputErrorMessage = nil }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.inputErrorMessage ?? "")
        }
    }
    
    // MARK: - Today's Progress
    
    private var todayProgressCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .font(.title2)
                    .foregroundColor(Theme.primary)
                
                Text("Today's Progress")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                let progress = vm.currentCalories / max(vm.goals.calories, 1)
                Text("\(Int(progress * 100))%")
                    .font(.title3)
                    .bold()
                    .foregroundColor(progressColor(progress))
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.textSecondary.opacity(0.15))
                    
                    let progress = min(vm.currentCalories / max(vm.goals.calories, 1), 1.0)
                    Capsule()
                        .fill(progressColor(progress))
                        .frame(width: geo.size.width * CGFloat(progress))
                }
            }
            .frame(height: 12)
            
            // Macros summary - All 4 nutrients
            HStack(spacing: 12) {
                macroStat(
                    title: "Calories",
                    current: Int(vm.currentCalories),
                    goal: Int(vm.goals.calories),
                    color: Theme.primary
                )
                
                macroStat(
                    title: "Protein",
                    current: Int(vm.currentProtein),
                    goal: Int(vm.goals.protein),
                    color: Theme.success
                )
                
                macroStat(
                    title: "Carbs",
                    current: Int(vm.currentCarbs),
                    goal: Int(vm.goals.carbs),
                    color: Theme.accent
                )
                
                macroStat(
                    title: "Fat",
                    current: Int(vm.currentFat),
                    goal: Int(vm.goals.fat),
                    color: Theme.warning
                )
            }
            .font(.caption)
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.textSecondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    private func macroStat(title: String, current: Int, goal: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .foregroundColor(Theme.textSecondary)
                .font(.caption2)
            Text("\(current)")
                .bold()
                .foregroundColor(color)
                .font(.subheadline)
            Text("/ \(goal)")
                .foregroundColor(Theme.textSecondary.opacity(0.7))
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func progressColor(_ progress: Double) -> Color {
        switch progress {
        case ..<0.60: return Theme.textSecondary
        case ..<1.00: return Theme.primary
        default: return Theme.success
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View { // spinner version
        VStack(spacing: 12) {
            Text("Plan Your Meal")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Theme.primary)
                    TextField("Calorie limit (optional)", text: $vm.calorieLimit)
                        .keyboardType(.decimalPad)
                        .foregroundColor(Theme.textPrimary)
                }
                .padding()
                .background(Theme.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.textSecondary.opacity(0.2), lineWidth: 1)
                )
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.primary)
                    TextField("Search food (e.g., chicken, rice)", text: $vm.query)
                        .foregroundColor(Theme.textPrimary)
                        .submitLabel(.search)
                        .onSubmit {
                            vm.fetchFood()
                        }
                }
                .padding()
                .background(Theme.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.textSecondary.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {

            // SEARCH BUTTON
            Button(action: {
                vm.fetchFood()
            }) {

                HStack {

                    if vm.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                    }

                    Text(vm.isLoading ? "Searching..." : "Search Foods")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(vm.isLoading ? Color.gray : Theme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(vm.isLoading)

            // SAVE BUTTON
            Button(action: {
                vm.saveMeal()
                showSaveConfirmation = true
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Meal")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    vm.chosenFoods.isEmpty
                    ? Theme.textSecondary.opacity(0.3)
                    : Theme.success
                ) // 19495021300
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(vm.chosenFoods.isEmpty)
        }
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Suggested Foods")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Text("\(vm.chosenFoods.count) items")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            
            // Total nutrients - Show ALL macros if tracked
            HStack(spacing: 12) {
                if vm.trackCalories {
                    totalPill(
                        title: "Cal",
                        value: "\(Int(vm.totalCalories()))",
                        color: Theme.primary
                    )
                }
                if vm.trackProtein {
                    totalPill(
                        title: "Protein",
                        value: "\(Int(vm.totalProtein()))g",
                        color: Theme.success
                    )
                }
                if vm.trackCarbs {
                    totalPill(
                        title: "Carbs",
                        value: "\(Int(vm.totalCarbs()))g",
                        color: Theme.accent
                    )
                }
                if vm.trackFat {
                    totalPill(
                        title: "Fat",
                        value: "\(Int(vm.totalFat()))g",
                        color: Theme.warning
                    )
                }
            }
            
            // Food list
            VStack(spacing: 8) {
                ForEach(vm.chosenFoods) { food in
                    foodCard(food)
                }
            }
        }
    }
    
    private func totalPill(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
            Text(value)
                .font(.subheadline)
                .bold()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func foodCard(_ food: Food) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(food.name.capitalized)
                .font(.subheadline)
                .bold()
                .foregroundColor(Theme.textPrimary)
            
            // Show ALL tracked nutrients with theme colors
            HStack(spacing: 12) {
                if vm.trackCalories {
                    nutrientLabel(
                        icon: "flame.fill",
                        value: "\(Int(food.calories))",
                        unit: "kcal",
                        color: Theme.primary
                    )
                }
                if vm.trackProtein {
                    nutrientLabel(
                        icon: "p.circle.fill",
                        value: "\(Int(food.protein))",
                        unit: "g",
                        color: Theme.success
                    )
                }
                if vm.trackCarbs {
                    nutrientLabel(
                        icon: "c.circle.fill",
                        value: "\(Int(food.carbs))",
                        unit: "g",
                        color: Theme.accent
                    )
                }
                if vm.trackFat {
                    nutrientLabel(
                        icon: "f.circle.fill",
                        value: "\(Int(food.fat))",
                        unit: "g",
                        color: Theme.warning
                    )
                }
                Spacer()
            }
            .font(.caption)
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.textSecondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func nutrientLabel(icon: String, value: String, unit: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text("\(value)\(unit)")
                .foregroundColor(Theme.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        PlannerView(vm: MealPlannerViewModel())
            .preferredColorScheme(.light)
    }
}
