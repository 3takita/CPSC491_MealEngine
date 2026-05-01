// Purpose:
// Main application ViewModel that manages business logic, state management,
// API communication, nutrient optimization (knapsack), meal tracking,
// goals, preferences, and persistence.

import Foundation
import Combine
import SwiftUI

final class MealPlannerViewModel: ObservableObject {

    // MARK: - Services

    private let network: NetworkServiceProtocol
    private let storage: StorageServiceProtocol

    // MARK: - User Inputs / State

    @Published var inputErrorMessage: String?
    @Published var isLoading = false

    @Published var calorieLimit: String = ""
    @Published var query: String = ""

    @Published var goals = Goals(
        calories: 2000,
        protein: 150,
        fat: 65,
        carbs: 250
    )

    // MARK: - Dietary Profile

    @Published var dietaryProfile = DietaryProfile()

    // MARK: - Search Results (free search — no knapsack until save)

    @Published var searchResults: [Food] = []
    @Published var selectedFoodIDs: Set<UUID> = []

    // MARK: - Smart Recommendations

    @Published var recommendedSearchResults: [Food] = []
    @Published var recommendedSelectedIDs: Set<UUID> = []
    @Published var recommendedQuery: String = ""
    @Published var isLoadingRecommendations = false

    // MARK: - Legacy (kept for history compatibility)

    @Published var chosenFoods: [Food] = []
    @Published var mealHistory: [[Food]] = []

    // MARK: - Preferences

    @Published var trackCalories: Bool = true
    @Published var trackProtein: Bool = true
    @Published var trackFat: Bool = false
    @Published var trackCarbs: Bool = false

    // MARK: - Current Progress

    @Published var currentCalories: Double = 0
    @Published var currentProtein: Double = 0
    @Published var currentFat: Double = 0
    @Published var currentCarbs: Double = 0

    // MARK: - Historical Tracking

    @Published var trackedDays: [TrackedDay] = []
    @Published var dailyMeals: [String: [Meal]] = [:]

    // MARK: - Persistence Keys

    private let historyKey        = "MealHistory"
    private let prefsKey          = "NutrientPrefs"
    private let goalsKey          = "UserGoals"
    private let trackedDaysKey    = "TrackedDays"
    private let dailyMealsKey     = "DailyMeals"
    private let dietaryProfileKey = "DietaryProfile"

    // MARK: - Init

    init(
        network: NetworkServiceProtocol = NetworkService(),
        storage: StorageServiceProtocol = StorageService()
    ) {
        self.network = network
        self.storage = storage

        loadHistory()
        loadPreferences()
        loadGoals()
        loadDietaryProfile()
        loadTrackedDays()
        loadDailyMeals()
        updateTodayProgress()
    }

    // MARK: - Free Food Search (original card — no knapsack until save)

    func fetchFood() {
        inputErrorMessage = nil

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            inputErrorMessage = "Please enter a food name."
            return
        }

        Task { [weak self] in
            guard let self else { return }

            await MainActor.run {
                self.isLoading = true
                self.searchResults = []
                self.selectedFoodIDs = []
            }

            do {
                let foods = try await self.searchOpenFoodFactsRaw(query: trimmed)
                await self.finishFreeSearch(foods)
            } catch {
                do {
                    let foods = try await self.searchUSDAraw(query: trimmed)
                    await self.finishFreeSearch(foods)
                } catch {
                    let foods = self.localFallbackFoods(query: trimmed)
                    await self.finishFreeSearch(foods)
                }
            }
        }
    }

    @MainActor
    private func finishFreeSearch(_ foods: [Food]) {
        self.searchResults = foods
        self.isLoading = false
        if foods.isEmpty {
            self.inputErrorMessage = "No foods found."
        }
    }

    // MARK: - Save Selected Foods (runs knapsack at save time)

    func saveSelectedFoods() {
        let selected = searchResults.filter { selectedFoodIDs.contains($0.id) }
        guard !selected.isEmpty else { return }

        let limit = Double(calorieLimit) ?? goals.calories
        let optimized = knapsack(
            foods: selected,
            calorieLimit: limit,
            proteinTarget: goals.protein,
            fatTarget: goals.fat,
            carbTarget: goals.carbs
        )

        mealHistory.append(optimized)
        persistHistory()

        let meal = Meal(
            date: Date(),
            items: optimized.map { MealItem(food: $0, amount: 100, unit: .gram) },
            totalCalories: optimized.reduce(0) { $0 + $1.calories },
            totalProtein:  optimized.reduce(0) { $0 + $1.protein },
            totalFat:      optimized.reduce(0) { $0 + $1.fat },
            totalCarbs:    optimized.reduce(0) { $0 + $1.carbs }
        )
        addMealToToday(meal)
        updateTodayProgress()

        searchResults = []
        selectedFoodIDs = []
    }

    // MARK: - Smart Recommendations

    func fetchRecommendations() {
        let baseQuery = recommendedQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = dietaryProfile.searchSuffix
        let fullQuery: String = {
            if baseQuery.isEmpty {
                return suffix.isEmpty ? "healthy meal" : suffix
            } else {
                return suffix.isEmpty ? baseQuery : "\(baseQuery) \(suffix)"
            }
        }()

        Task { [weak self] in
            guard let self else { return }

            await MainActor.run {
                self.isLoadingRecommendations = true
                self.recommendedSearchResults = []
                self.recommendedSelectedIDs = []
            }

            do {
                let foods = try await self.searchOpenFoodFactsRaw(query: fullQuery)
                let filtered = foods.filter { self.dietaryProfile.allows($0) }
                let optimized = self.knapsack(
                    foods: filtered,
                    calorieLimit: goals.calories,
                    proteinTarget: goals.protein,
                    fatTarget: goals.fat,
                    carbTarget: goals.carbs
                )
                await MainActor.run {
                    self.recommendedSearchResults = optimized
                    self.isLoadingRecommendations = false
                    if optimized.isEmpty {
                        self.inputErrorMessage = "No recommendations found for your dietary preferences."
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingRecommendations = false
                    self.inputErrorMessage = "Could not load recommendations."
                }
            }
        }
    }

    func saveRecommendedSelection() {
        let toSave = recommendedSearchResults.filter { recommendedSelectedIDs.contains($0.id) }
        guard !toSave.isEmpty else { return }

        mealHistory.append(toSave)
        persistHistory()

        let meal = Meal(
            date: Date(),
            items: toSave.map { MealItem(food: $0, amount: 100, unit: .gram) },
            totalCalories: toSave.reduce(0) { $0 + $1.calories },
            totalProtein:  toSave.reduce(0) { $0 + $1.protein },
            totalFat:      toSave.reduce(0) { $0 + $1.fat },
            totalCarbs:    toSave.reduce(0) { $0 + $1.carbs }
        )
        addMealToToday(meal)
        updateTodayProgress()

        recommendedSearchResults = []
        recommendedSelectedIDs = []
    }

    // MARK: - Knapsack Algorithm (whole items only, multi-macro scoring)

    func knapsack(
        foods: [Food],
        calorieLimit: Double,
        proteinTarget: Double = 0,
        fatTarget: Double = 0,
        carbTarget: Double = 0
    ) -> [Food] {
        guard calorieLimit > 0, !foods.isEmpty else { return foods }

        let eps = 0.0001
        let totalTarget = (proteinTarget * 4) + (fatTarget * 9) + (carbTarget * 4)

        func score(_ food: Food) -> Double {
            guard food.calories > eps else { return 0 }
            if totalTarget > 0 {
                let pScore = proteinTarget > 0 ? (food.protein * 4 / totalTarget) : 0
                let fScore = fatTarget > 0     ? (food.fat * 9 / totalTarget)     : 0
                let cScore = carbTarget > 0    ? (food.carbs * 4 / totalTarget)   : 0
                return (pScore + fScore + cScore) / food.calories
            }
            if trackProtein { return food.protein / food.calories }
            if trackFat     { return food.fat / food.calories }
            if trackCarbs   { return food.carbs / food.calories }
            return 1.0 / food.calories
        }

        let sorted = foods.filter { $0.calories > 0 }.sorted { score($0) > score($1) }
        var remaining = calorieLimit
        var selected: [Food] = []

        for food in sorted {
            guard food.calories > 0 else { continue }
            if food.calories <= remaining {
                selected.append(food)
                remaining -= food.calories
            }
            // No fractions — whole items only
        }

        return selected
    }

    // MARK: - Meal Management (legacy saveMeal kept for compatibility)

    func saveMeal() {
        guard !chosenFoods.isEmpty else { return }
        mealHistory.append(chosenFoods)
        persistHistory()
        let meal = createMealFromChosenFoods()
        addMealToToday(meal)
        updateTodayProgress()
        chosenFoods = []
    }

    private func createMealFromChosenFoods() -> Meal {
        let items = chosenFoods.map { MealItem(food: $0, amount: 100, unit: .gram) }
        return Meal(
            date: Date(),
            items: items,
            totalCalories: chosenFoods.reduce(0) { $0 + $1.calories },
            totalProtein:  chosenFoods.reduce(0) { $0 + $1.protein },
            totalFat:      chosenFoods.reduce(0) { $0 + $1.fat },
            totalCarbs:    chosenFoods.reduce(0) { $0 + $1.carbs }
        )
    }

    private func addMealToToday(_ meal: Meal) {
        let key = dateString(from: Date())
        var meals = dailyMeals[key] ?? []
        meals.append(meal)
        dailyMeals[key] = meals
        persistDailyMeals()
    }

    func getMeals(for date: Date) -> [Meal] {
        dailyMeals[dateString(from: date)] ?? []
    }

    // MARK: - Progress

    func updateTodayProgress() {
        let meals = getMeals(for: Date())
        currentCalories = meals.reduce(0) { $0 + $1.totalCalories }
        currentProtein  = meals.reduce(0) { $0 + $1.totalProtein }
        currentFat      = meals.reduce(0) { $0 + $1.totalFat }
        currentCarbs    = meals.reduce(0) { $0 + $1.totalCarbs }
        updateTrackedDay(for: Date())
    }

    private func updateTrackedDay(for date: Date) {
        let meals = getMeals(for: date)
        let trackedDay = TrackedDay(
            date: date,
            calories: meals.reduce(0) { $0 + $1.totalCalories },
            protein:  meals.reduce(0) { $0 + $1.totalProtein },
            carbs:    meals.reduce(0) { $0 + $1.totalCarbs },
            fat:      meals.reduce(0) { $0 + $1.totalFat },
            goalCalories: goals.calories
        )
        trackedDays.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
        trackedDays.append(trackedDay)
        persistTrackedDays()
    }

    func getTrackedDay(for date: Date) -> TrackedDay? {
        trackedDays.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Totals (for selected foods in free search)

    func totalCalories() -> Double {
        searchResults.filter { selectedFoodIDs.contains($0.id) }.reduce(0) { $0 + $1.calories }
    }

    func totalProtein() -> Double {
        searchResults.filter { selectedFoodIDs.contains($0.id) }.reduce(0) { $0 + $1.protein }
    }

    func totalFat() -> Double {
        searchResults.filter { selectedFoodIDs.contains($0.id) }.reduce(0) { $0 + $1.fat }
    }

    func totalCarbs() -> Double {
        searchResults.filter { selectedFoodIDs.contains($0.id) }.reduce(0) { $0 + $1.carbs }
    }

    // MARK: - Persistence

    func saveGoals() {
        if let data = try? JSONEncoder().encode(goals) {
            storage.set(data, forKey: goalsKey)
        }
    }

    private func loadGoals() {
        guard let data = storage.data(forKey: goalsKey),
              let decoded = try? JSONDecoder().decode(Goals.self, from: data)
        else { return }
        goals = decoded
    }

    func saveDietaryProfile() {
        if let data = try? JSONEncoder().encode(dietaryProfile) {
            storage.set(data, forKey: dietaryProfileKey)
        }
    }

    private func loadDietaryProfile() {
        guard let data = storage.data(forKey: dietaryProfileKey),
              let decoded = try? JSONDecoder().decode(DietaryProfile.self, from: data)
        else { return }
        dietaryProfile = decoded
    }

    func savePreferences() {
        let prefs: [String: Bool] = [
            "calories": trackCalories,
            "protein":  trackProtein,
            "fat":      trackFat,
            "carbs":    trackCarbs
        ]
        storage.set(prefs, forKey: prefsKey)
    }

    private func loadPreferences() {
        guard let prefs = storage.dictionary(forKey: prefsKey) as? [String: Bool] else { return }
        trackCalories = prefs["calories"] ?? true
        trackProtein  = prefs["protein"]  ?? true
        trackFat      = prefs["fat"]      ?? false
        trackCarbs    = prefs["carbs"]    ?? false
    }

    private func persistHistory() {
        if let data = try? JSONEncoder().encode(mealHistory) {
            storage.set(data, forKey: historyKey)
        }
    }

    private func loadHistory() {
        guard let data = storage.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([[Food]].self, from: data)
        else { return }
        mealHistory = decoded
    }

    private func persistTrackedDays() {
        if let data = try? JSONEncoder().encode(trackedDays) {
            storage.set(data, forKey: trackedDaysKey)
        }
    }

    private func loadTrackedDays() {
        guard let data = storage.data(forKey: trackedDaysKey),
              let decoded = try? JSONDecoder().decode([TrackedDay].self, from: data)
        else { return }
        trackedDays = decoded
    }

    private func persistDailyMeals() {
        if let data = try? JSONEncoder().encode(dailyMeals) {
            storage.set(data, forKey: dailyMealsKey)
        }
    }

    private func loadDailyMeals() {
        guard let data = storage.data(forKey: dailyMealsKey),
              let decoded = try? JSONDecoder().decode([String: [Meal]].self, from: data)
        else { return }
        dailyMeals = decoded
    }

    // MARK: - Helpers

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Raw Search Helpers (no knapsack — return full lists)

    func searchOpenFoodFactsRaw(query: String) async throws -> [Food] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string:
            "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encoded)&search_simple=1&action=process&json=1&page_size=30"
        ) else { throw URLError(.badURL) }

        let data = try await network.get(url: url, ttl: 300)
        let decoded = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)

        return decoded.products.compactMap { product in
            guard let name = product.product_name, !name.isEmpty,
                  let nutr = product.nutriments else { return nil }
            return Food(
                name: name,
                calories: nutr.energyKcal100g ?? 0,
                protein:  nutr.proteins100g ?? 0,
                fat:      nutr.fat100g ?? 0,
                carbs:    nutr.carbohydrates100g ?? 0
            )
        }
    }

    private func searchUSDAraw(query: String) async throws -> [Food] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string:
            "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(encoded)&api_key=\(Secrets.usdaKey)"
        ) else { throw URLError(.badURL) }

        let data = try await network.get(url: url, ttl: 300)
        let decoded = try JSONDecoder().decode(USDAResponse.self, from: data)

        return decoded.foods.map { item in
            Food(
                name: item.description,
                calories: item.calories,
                protein:  item.protein,
                fat:      item.fat,
                carbs:    item.carbs
            )
        }
    }

    private func localFallbackFoods(query: String) -> [Food] {
        let foods = [
            Food(name: "Cheese Quesadilla", calories: 280, protein: 12, fat: 16, carbs: 22),
            Food(name: "Milk",              calories: 103, protein: 8,  fat: 2,  carbs: 12),
            Food(name: "Spaghetti",         calories: 220, protein: 8,  fat: 1,  carbs: 43)
        ]
        return foods.filter { $0.name.lowercased().contains(query.lowercased()) }
    }
}
