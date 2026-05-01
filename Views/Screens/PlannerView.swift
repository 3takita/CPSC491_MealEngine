// PURPOSE: Provides the main meal planning interface with free food search
// and a smart recommendations card driven by dietary preferences + knapsack.
// HLFR: The system shall allow users to plan and log meals

import SwiftUI

struct PlannerView: View {
    @ObservedObject var vm: MealPlannerViewModel
    @State private var showSaveConfirmation = false
    @State private var showSaveRecommendedConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                todayProgressCard
                freeSearchCard
                recommendationsCard
            }
            .padding()
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("MealEngine")
        .alert("Meal Saved!", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your meal has been added to today's log.")
        }
        .alert("Meal Saved!", isPresented: $showSaveRecommendedConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your recommended meal has been added to today's log.")
        }
        .alert(
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
                    .font(.title3).bold()
                    .foregroundColor(progressColor(progress))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.textSecondary.opacity(0.15))
                    let progress = min(vm.currentCalories / max(vm.goals.calories, 1), 1.0)
                    Capsule()
                        .fill(progressColor(progress))
                        .frame(width: geo.size.width * CGFloat(progress))
                }
            }
            .frame(height: 12)

            HStack(spacing: 12) {
                macroStat(title: "Calories", current: Int(vm.currentCalories), goal: Int(vm.goals.calories), color: Theme.primary)
                macroStat(title: "Protein",  current: Int(vm.currentProtein),  goal: Int(vm.goals.protein),  color: Theme.success)
                macroStat(title: "Carbs",    current: Int(vm.currentCarbs),    goal: Int(vm.goals.carbs),    color: Theme.accent)
                macroStat(title: "Fat",      current: Int(vm.currentFat),      goal: Int(vm.goals.fat),      color: Theme.warning)
            }
            .font(.caption)
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.textSecondary.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func macroStat(title: String, current: Int, goal: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).foregroundColor(Theme.textSecondary).font(.caption2)
            Text("\(current)").bold().foregroundColor(color).font(.subheadline)
            Text("/ \(goal)").foregroundColor(Theme.textSecondary.opacity(0.7)).font(.caption2)
        }
        .frame(maxWidth: .infinity)
    }

    private func progressColor(_ progress: Double) -> Color {
        switch progress {
        case ..<0.60: return Theme.textSecondary
        case ..<1.00: return Theme.primary
        default:      return Theme.success
        }
    }

    // MARK: - Free Search Card

    private var freeSearchCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.title3)
                    .foregroundColor(Theme.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Search Foods")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    Text("Add any food directly to your meal")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
            }

            // Optional calorie limit
            HStack {
                Image(systemName: "flame.fill").foregroundColor(Theme.primary)
                TextField("Calorie limit (optional)", text: $vm.calorieLimit)
                    .keyboardType(.decimalPad)
                    .foregroundColor(Theme.textPrimary)
            }
            .padding()
            .background(Theme.surface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.textSecondary.opacity(0.2), lineWidth: 1))

            // Query
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(Theme.primary)
                TextField("Search food (e.g. chicken, rice)", text: $vm.query)
                    .foregroundColor(Theme.textPrimary)
                    .submitLabel(.search)
                    .onSubmit { vm.fetchFood() }
                if !vm.query.isEmpty {
                    Button { vm.query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .padding()
            .background(Theme.surface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.textSecondary.opacity(0.2), lineWidth: 1))

            // Search + Save buttons
            HStack(spacing: 12) {
                Button { vm.fetchFood() } label: {
                    HStack {
                        if vm.isLoading { ProgressView().tint(.white) }
                        else { Image(systemName: "arrow.down.circle.fill") }
                        Text(vm.isLoading ? "Searching..." : "Search Foods").bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.isLoading ? Color.gray : Theme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(vm.isLoading)

                Button {
                    vm.saveSelectedFoods()
                    showSaveConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save").bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.selectedFoodIDs.isEmpty ? Theme.textSecondary.opacity(0.3) : Theme.success)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(vm.selectedFoodIDs.isEmpty)
            }

            // Results
            if !vm.searchResults.isEmpty {
                freeSearchResults
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.textSecondary.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var freeSearchResults: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Results")
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(vm.searchResults.count) items")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            // Totals for selection
            if !vm.selectedFoodIDs.isEmpty {
                HStack(spacing: 12) {
                    totalPill(title: "Cal",     value: "\(Int(vm.totalCalories()))",    color: Theme.primary)
                    totalPill(title: "Protein", value: "\(Int(vm.totalProtein()))g",    color: Theme.success)
                    totalPill(title: "Carbs",   value: "\(Int(vm.totalCarbs()))g",      color: Theme.accent)
                    totalPill(title: "Fat",     value: "\(Int(vm.totalFat()))g",        color: Theme.warning)
                }
            }

            ForEach(vm.searchResults) { food in
                foodCard(
                    food: food,
                    isSelected: vm.selectedFoodIDs.contains(food.id)
                ) {
                    if vm.selectedFoodIDs.contains(food.id) { vm.selectedFoodIDs.remove(food.id) }
                    else { vm.selectedFoodIDs.insert(food.id) }
                }
            }
        }
    }

    // MARK: - Smart Recommendations Card

    private var recommendationsCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(Theme.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Smart Recommendations")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    Text(dietSummary)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
            }

            // Optional keyword filter
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(Theme.primary)
                TextField("Filter recommendations (e.g. chicken)", text: $vm.recommendedQuery)
                    .foregroundColor(Theme.textPrimary)
                    .submitLabel(.search)
                    .onSubmit { vm.fetchRecommendations() }
                if !vm.recommendedQuery.isEmpty {
                    Button {
                        vm.recommendedQuery = ""
                        vm.fetchRecommendations()
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .padding()
            .background(Theme.surface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.primary.opacity(0.25), lineWidth: 1))

            // Fetch button
            Button { vm.fetchRecommendations() } label: {
                HStack {
                    if vm.isLoadingRecommendations { ProgressView().tint(.white) }
                    else { Image(systemName: "sparkle.magnifyingglass") }
                    Text(vm.isLoadingRecommendations ? "Finding meals..." : "Get Recommendations").bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(vm.isLoadingRecommendations ? Color.gray : Theme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(vm.isLoadingRecommendations)

            // Results
            if !vm.recommendedSearchResults.isEmpty {
                recommendedResults
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.primary.opacity(0.25), lineWidth: 1.5))
        .shadow(color: Theme.primary.opacity(0.06), radius: 8, y: 4)
    }

    private var dietSummary: String {
        let r = vm.dietaryProfile.restrictions
        if r.isEmpty { return "Personalised to your calorie & macro goals" }
        return r.map { $0.rawValue }.joined(separator: " · ")
    }

    private var recommendedResults: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Recommended for you")
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(vm.recommendedSearchResults.count) items")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            // Totals for selection
            let sel = vm.recommendedSearchResults.filter { vm.recommendedSelectedIDs.contains($0.id) }
            if !sel.isEmpty {
                HStack(spacing: 12) {
                    totalPill(title: "Cal",     value: "\(Int(sel.reduce(0) { $0 + $1.calories }))",  color: Theme.primary)
                    totalPill(title: "Protein", value: "\(Int(sel.reduce(0) { $0 + $1.protein }))g",  color: Theme.success)
                    totalPill(title: "Carbs",   value: "\(Int(sel.reduce(0) { $0 + $1.carbs }))g",    color: Theme.accent)
                    totalPill(title: "Fat",     value: "\(Int(sel.reduce(0) { $0 + $1.fat }))g",      color: Theme.warning)
                }
            }

            ForEach(vm.recommendedSearchResults) { food in
                foodCard(
                    food: food,
                    isSelected: vm.recommendedSelectedIDs.contains(food.id)
                ) {
                    if vm.recommendedSelectedIDs.contains(food.id) { vm.recommendedSelectedIDs.remove(food.id) }
                    else { vm.recommendedSelectedIDs.insert(food.id) }
                }
            }

            Button {
                vm.saveRecommendedSelection()
                showSaveRecommendedConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Selected").bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(vm.recommendedSelectedIDs.isEmpty ? Theme.textSecondary.opacity(0.3) : Theme.success)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(vm.recommendedSelectedIDs.isEmpty)
        }
    }

    // MARK: - Shared Sub-views

    private func foodCard(food: Food, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(food.name.capitalized)
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 12) {
                        nutrientLabel(icon: "flame.fill",    value: "\(Int(food.calories))", unit: "kcal", color: Theme.primary)
                        nutrientLabel(icon: "p.circle.fill", value: "\(Int(food.protein))",  unit: "g",    color: Theme.success)
                        nutrientLabel(icon: "c.circle.fill", value: "\(Int(food.carbs))",    unit: "g",    color: Theme.accent)
                        nutrientLabel(icon: "f.circle.fill", value: "\(Int(food.fat))",      unit: "g",    color: Theme.warning)
                        Spacer()
                    }
                    .font(.caption)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Theme.success : Theme.textSecondary.opacity(0.4))
                    .font(.title3)
            }
            .padding()
            .background(isSelected ? Theme.success.opacity(0.06) : Theme.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.success : Theme.textSecondary.opacity(0.2),
                            lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private func totalPill(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundColor(Theme.textSecondary)
            Text(value).font(.subheadline).bold().foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

    private func nutrientLabel(icon: String, value: String, unit: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(color)
            Text("\(value)\(unit)").foregroundColor(Theme.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        PlannerView(vm: MealPlannerViewModel())
            .preferredColorScheme(.light)
    }
}
