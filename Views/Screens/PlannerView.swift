// PURPOSE: Main meal planning interface.
// Search card: search freely, tap to select, "Add to Meal" puts items in the
// basket. Search again for more. Smart Picks toggle runs knapsack on results.
// Basket shows everything queued so far; "Save Meal" logs it all at once.

import SwiftUI

struct PlannerView: View {
    @ObservedObject var vm: MealPlannerViewModel
    @State private var showSaveConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                todayProgressCard
                searchCard
                if !vm.pendingMealFoods.isEmpty {
                    pendingMealCard
                }
            }
            .padding()
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("MealEngine")
        .alert("Meal Saved!", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Added to today's log.")
        }
        .alert("Error",
               isPresented: Binding(get: { vm.inputErrorMessage != nil },
                                    set: { _ in vm.inputErrorMessage = nil })) {
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
                    .font(.title2).foregroundColor(Theme.primary)
                Text("Today's Progress")
                    .font(.headline).foregroundColor(Theme.textPrimary)
                Spacer()
                let pct = vm.currentCalories / max(vm.goals.calories, 1)
                Text("\(Int(min(pct, 1) * 100))%")
                    .font(.title3).bold().foregroundColor(progressColor(pct))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.textSecondary.opacity(0.15))
                    let w = min(vm.currentCalories / max(vm.goals.calories, 1), 1.0)
                    Capsule().fill(progressColor(w)).frame(width: geo.size.width * CGFloat(w))
                }
            }
            .frame(height: 10)

            HStack(spacing: 12) {
                macroStat("Calories", cur: Int(vm.currentCalories), goal: Int(vm.goals.calories), color: Theme.primary,  unit: "kcal")
                macroStat("Protein",  cur: Int(vm.currentProtein),  goal: Int(vm.goals.protein),  color: Theme.success, unit: "g")
                macroStat("Carbs",    cur: Int(vm.currentCarbs),    goal: Int(vm.goals.carbs),    color: Theme.accent,  unit: "g")
                macroStat("Fat",      cur: Int(vm.currentFat),      goal: Int(vm.goals.fat),      color: Theme.warning, unit: "g")
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.textSecondary.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func macroStat(_ title: String, cur: Int, goal: Int, color: Color, unit: String) -> some View {
        VStack(spacing: 3) {
            Text(title).font(.caption2).foregroundColor(Theme.textSecondary)
            Text("\(cur)").bold().foregroundColor(color).font(.subheadline)
            Text("/ \(goal)\(unit)").font(.caption2).foregroundColor(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    private func progressColor(_ p: Double) -> Color {
        p < 0.6 ? Theme.textSecondary : p < 1.0 ? Theme.primary : Theme.success
    }

    // MARK: - Search Card

    private var searchCard: some View {
        VStack(spacing: 14) {

            // Header + Smart Picks toggle
            HStack(spacing: 10) {
                Image(systemName: vm.showSmartPicks ? "sparkles" : "magnifyingglass.circle.fill")
                    .font(.title3).foregroundColor(Theme.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.showSmartPicks ? "Smart Picks" : "Search Foods")
                        .font(.headline).foregroundColor(Theme.textPrimary)
                    Text(vm.showSmartPicks ? dietSummary : "Search and add foods to your meal")
                        .font(.caption).foregroundColor(Theme.textSecondary).lineLimit(1)
                }
                Spacer()

                VStack(spacing: 2) {
                    Toggle("", isOn: $vm.showSmartPicks)
                        .labelsHidden()
                        // iOS 17+ zero-parameter form — fixes deprecation warning
                        .onChange(of: vm.showSmartPicks) {
                            vm.refreshSmartPicks()
                        }
                    Text("Smart\nPicks")
                        .font(.caption2).foregroundColor(Theme.textSecondary).multilineTextAlignment(.center)
                }
            }

            // Diet badge strip
            if vm.showSmartPicks && !vm.dietaryProfile.restrictions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(vm.dietaryProfile.restrictions)) { r in
                            HStack(spacing: 4) {
                                Image(systemName: r.icon).font(.caption2)
                                Text(r.rawValue).font(.caption2)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Theme.primary.opacity(0.1))
                            .foregroundColor(Theme.primary).cornerRadius(8)
                        }
                    }
                }
            }

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(Theme.primary)
                TextField(vm.showSmartPicks ? "Search for recommendations..." : "Search food (e.g. chicken)",
                          text: $vm.query)
                    .foregroundColor(Theme.textPrimary)
                    .submitLabel(.search)
                    .onSubmit { vm.fetchFood() }

                if !vm.query.isEmpty {
                    Button {
                        vm.query = ""
                        vm.searchResults = []
                        vm.smartPickResults = []
                        vm.selectedFoodIDs = []
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .padding()
            .background(Theme.surface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(vm.showSmartPicks ? Theme.primary.opacity(0.4) : Theme.textSecondary.opacity(0.2), lineWidth: 1))

            // Search + Add to Meal buttons
            HStack(spacing: 12) {
                Button { vm.fetchFood() } label: {
                    HStack {
                        if vm.isLoading { ProgressView().tint(.white) }
                        else { Image(systemName: vm.showSmartPicks ? "sparkle.magnifyingglass" : "magnifyingglass") }
                        Text(vm.isLoading ? "Searching..." : "Search").bold()
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(vm.isLoading ? Color.gray : Theme.primary)
                    .foregroundColor(.white).cornerRadius(12)
                }
                .disabled(vm.isLoading)

                Button {
                    vm.addSelectionToMeal()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to Meal\(vm.selectedFoodIDs.isEmpty ? "" : " (\(vm.selectedFoodIDs.count))")").bold()
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(vm.selectedFoodIDs.isEmpty ? Theme.textSecondary.opacity(0.3) : Theme.primary.opacity(0.85))
                    .foregroundColor(.white).cornerRadius(12)
                }
                .disabled(vm.selectedFoodIDs.isEmpty)
            }

            // Results
            if !vm.visibleResults.isEmpty {
                resultsSection
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(vm.showSmartPicks ? Theme.primary.opacity(0.3) : Theme.textSecondary.opacity(0.2),
                    lineWidth: vm.showSmartPicks ? 1.5 : 1))
        .shadow(color: vm.showSmartPicks ? Theme.primary.opacity(0.07) : .black.opacity(0.05), radius: 8, y: 4)
    }

    private var dietSummary: String {
        let r = vm.dietaryProfile.restrictions
        return r.isEmpty ? "Optimised to your calorie & macro goals" : r.map { $0.rawValue }.joined(separator: " · ")
    }

    // MARK: - Search Results

    private var resultsSection: some View {
        VStack(spacing: 10) {
            HStack {
                if vm.showSmartPicks {
                    Label("Recommended for you", systemImage: "sparkles")
                        .font(.subheadline.bold()).foregroundColor(Theme.textPrimary)
                } else {
                    Text("Results").font(.subheadline.bold()).foregroundColor(Theme.textPrimary)
                }
                Spacer()
                Text("\(vm.visibleResults.count) items").font(.caption).foregroundColor(Theme.textSecondary)
            }

            // Selection totals
            if !vm.selectedFoodIDs.isEmpty {
                HStack(spacing: 10) {
                    totalPill("Cal",     "\(Int(vm.totalCalories()))",  Theme.primary)
                    totalPill("Protein", "\(Int(vm.totalProtein()))g",  Theme.success)
                    totalPill("Carbs",   "\(Int(vm.totalCarbs()))g",    Theme.accent)
                    totalPill("Fat",     "\(Int(vm.totalFat()))g",      Theme.warning)
                }
            }

            if vm.selectedFoodIDs.isEmpty {
                Text("Tap to select · search again to add more foods")
                    .font(.caption).foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(vm.visibleResults) { food in
                foodCard(food, isInBasket: vm.pendingMealFoods.contains(where: { $0.id == food.id }))
            }
        }
    }

    // MARK: - Pending Meal Basket Card

    private var pendingMealCard: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Meal in Progress", systemImage: "cart.fill")
                    .font(.headline).foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(vm.pendingMealFoods.count) item\(vm.pendingMealFoods.count == 1 ? "" : "s")")
                    .font(.caption).foregroundColor(Theme.textSecondary)
            }

            // Basket totals
            HStack(spacing: 10) {
                totalPill("Cal",     "\(Int(vm.pendingCalories))",  Theme.primary)
                totalPill("Protein", "\(Int(vm.pendingProtein))g",  Theme.success)
                totalPill("Carbs",   "\(Int(vm.pendingCarbs))g",    Theme.accent)
                totalPill("Fat",     "\(Int(vm.pendingFat))g",      Theme.warning)
            }

            // Basket items
            ForEach(vm.pendingMealFoods) { food in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(food.name.capitalized).font(.subheadline.bold()).foregroundColor(Theme.textPrimary)
                        HStack(spacing: 8) {
                            nutriLabel("flame.fill",    "\(Int(food.calories))kcal", Theme.primary)
                            nutriLabel("p.circle.fill", "\(Int(food.protein))g P",  Theme.success)
                            nutriLabel("c.circle.fill", "\(Int(food.carbs))g C",    Theme.accent)
                            nutriLabel("f.circle.fill", "\(Int(food.fat))g F",      Theme.warning)
                        }
                        .font(.caption)
                    }
                    Spacer()
                    Button { vm.removeFromPendingMeal(food) } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(Theme.warning).font(.title3)
                    }
                }
                .padding(12)
                .background(Theme.surface)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.textSecondary.opacity(0.15), lineWidth: 0.5))
            }

            // Save + Clear
            HStack(spacing: 12) {
                Button {
                    vm.savePendingMeal()
                    showSaveConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Meal").bold()
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(Theme.success).foregroundColor(.white).cornerRadius(12)
                }

                Button { vm.clearPendingMeal() } label: {
                    Text("Clear").bold()
                        .frame(maxWidth: .infinity).padding()
                        .foregroundColor(Theme.warning)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.warning.opacity(0.5), lineWidth: 1))
                }
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.success.opacity(0.3), lineWidth: 1.5))
        .shadow(color: Theme.success.opacity(0.07), radius: 8, y: 4)
    }

    // MARK: - Food Card

    private func foodCard(_ food: Food, isInBasket: Bool) -> some View {
        let isSelected = vm.selectedFoodIDs.contains(food.id)
        return Button {
            if isSelected { vm.selectedFoodIDs.remove(food.id) }
            else          { vm.selectedFoodIDs.insert(food.id) }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(food.name.capitalized)
                            .font(.subheadline.bold()).foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        if isInBasket {
                            Image(systemName: "cart.badge.plus")
                                .font(.caption2).foregroundColor(Theme.success)
                        }
                    }
                    HStack(spacing: 10) {
                        nutriLabel("flame.fill",    "\(Int(food.calories))kcal", Theme.primary)
                        nutriLabel("p.circle.fill", "\(Int(food.protein))g P",  Theme.success)
                        nutriLabel("c.circle.fill", "\(Int(food.carbs))g C",    Theme.accent)
                        nutriLabel("f.circle.fill", "\(Int(food.fat))g F",      Theme.warning)
                    }
                    .font(.caption)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Theme.success : Theme.textSecondary.opacity(0.35))
                    .font(.title3)
            }
            .padding(14)
            .background(isSelected ? Theme.success.opacity(0.06) : isInBasket ? Theme.success.opacity(0.03) : Theme.surface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Theme.success : Theme.textSecondary.opacity(0.18),
                        lineWidth: isSelected ? 1.5 : 0.5))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // MARK: - Shared Helpers

    private func totalPill(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundColor(Theme.textSecondary)
            Text(value).font(.subheadline).bold().foregroundColor(color)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
        .background(color.opacity(0.1)).cornerRadius(8)
    }

    private func nutriLabel(_ icon: String, _ text: String, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).foregroundColor(color)
            Text(text).foregroundColor(Theme.textSecondary)
        }
    }
}

#Preview {
    NavigationStack { PlannerView(vm: MealPlannerViewModel()) }
}
