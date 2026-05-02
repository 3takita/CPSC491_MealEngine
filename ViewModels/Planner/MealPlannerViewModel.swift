// Purpose:
// Main application ViewModel. Manages food search, knapsack optimisation,
// meal logging, goals, dietary profile, and persistence.
//
// Multi-search design: searchResults holds the current API page.
// pendingMealFoods is the growing basket the user is building across
// multiple searches. selectedFoodIDs tracks taps within the current page.
// "Add to meal" merges selected into the basket without clearing it.

import Foundation
import Combine
import SwiftUI

final class MealPlannerViewModel: ObservableObject {

    // MARK: - Services
    private let network: NetworkServiceProtocol
    private let storage: StorageServiceProtocol

    // MARK: - Search State
    @Published var query: String = ""
    @Published var isLoading = false
    @Published var inputErrorMessage: String?

    /// Current search page results
    @Published var searchResults: [Food] = []
    /// IDs selected in the current search page
    @Published var selectedFoodIDs: Set<UUID> = []
    /// Smart picks computed from current searchResults
    @Published var smartPickResults: [Food] = []
    /// Toggle: false = all results, true = knapsack-filtered smart picks
    @Published var showSmartPicks: Bool = false

    /// The meal being built across multiple searches
    @Published var pendingMealFoods: [Food] = []

    // MARK: - Dietary Profile
    @Published var dietaryProfile = DietaryProfile()

    // MARK: - Legacy
    @Published var chosenFoods: [Food] = []
    @Published var mealHistory: [[Food]] = []

    // MARK: - Preferences — all default ON
    @Published var trackCalories: Bool = true
    @Published var trackProtein:  Bool = true
    @Published var trackFat:      Bool = true
    @Published var trackCarbs:    Bool = true

    // MARK: - Goals
    @Published var goals = Goals(calories: 2000, protein: 150, fat: 65, carbs: 250)

    // MARK: - Current Progress
    @Published var currentCalories: Double = 0
    @Published var currentProtein:  Double = 0
    @Published var currentFat:      Double = 0
    @Published var currentCarbs:    Double = 0

    // MARK: - Historical Tracking
    @Published var trackedDays:  [TrackedDay]     = []
    @Published var dailyMeals:   [String: [Meal]] = [:]

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

    // MARK: - Search

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
                // Only clear the search page — do NOT touch pendingMealFoods or selectedFoodIDs for basket items
                self.searchResults = []
                self.smartPickResults = []
                self.selectedFoodIDs = []
            }
            do {
                let foods = try await self.searchOpenFoodFactsRaw(query: trimmed)
                await self.finishSearch(foods)
            } catch {
                do {
                    let foods = try await self.searchUSDAraw(query: trimmed)
                    await self.finishSearch(foods)
                } catch {
                    await self.finishSearch(self.localFallbackFoods(query: trimmed))
                }
            }
        }
    }

    @MainActor
    private func finishSearch(_ foods: [Food]) {
        searchResults    = foods
        smartPickResults = computeSmartPicks(from: foods)
        isLoading        = false
        if foods.isEmpty { inputErrorMessage = "No foods found." }
    }

    func refreshSmartPicks() {
        smartPickResults = computeSmartPicks(from: searchResults)
        selectedFoodIDs  = []
    }

    private func computeSmartPicks(from foods: [Food]) -> [Food] {
        let filtered = foods.filter { dietaryProfile.allows($0) }
        return knapsack(foods: filtered, calorieLimit: goals.calories,
                        proteinTarget: goals.protein, fatTarget: goals.fat, carbTarget: goals.carbs)
    }

    var visibleResults: [Food] { showSmartPicks ? smartPickResults : searchResults }

    // MARK: - Basket Management (multi-search meal building)

    /// Add selected foods from the current page into the pending meal basket
    func addSelectionToMeal() {
        let toAdd = visibleResults.filter { selectedFoodIDs.contains($0.id) }
        guard !toAdd.isEmpty else { return }
        // Avoid duplicates if user searches same food twice
        let existingIDs = Set(pendingMealFoods.map { $0.id })
        pendingMealFoods.append(contentsOf: toAdd.filter { !existingIDs.contains($0.id) })
        selectedFoodIDs = []
    }

    func removeFromPendingMeal(_ food: Food) {
        pendingMealFoods.removeAll { $0.id == food.id }
    }

    func clearPendingMeal() {
        pendingMealFoods = []
        selectedFoodIDs  = []
        searchResults    = []
        smartPickResults = []
        showSmartPicks   = false
    }

    /// Save everything in the pending basket as one meal
    func savePendingMeal() {
        guard !pendingMealFoods.isEmpty else { return }

        mealHistory.append(pendingMealFoods)
        persistHistory()

        let meal = Meal(
            date: Date(),
            items: pendingMealFoods.map { MealItem(food: $0, amount: 100, unit: .gram) },
            totalCalories: pendingMealFoods.reduce(0) { $0 + $1.calories },
            totalProtein:  pendingMealFoods.reduce(0) { $0 + $1.protein },
            totalFat:      pendingMealFoods.reduce(0) { $0 + $1.fat },
            totalCarbs:    pendingMealFoods.reduce(0) { $0 + $1.carbs }
        )
        addMealToToday(meal)
        updateTodayProgress()
        clearPendingMeal()
    }

    // MARK: - Basket Totals

    var pendingCalories: Double { pendingMealFoods.reduce(0) { $0 + $1.calories } }
    var pendingProtein:  Double { pendingMealFoods.reduce(0) { $0 + $1.protein } }
    var pendingFat:      Double { pendingMealFoods.reduce(0) { $0 + $1.fat } }
    var pendingCarbs:    Double { pendingMealFoods.reduce(0) { $0 + $1.carbs } }

    // Selection totals (current page only)
    func totalCalories() -> Double { visibleResults.filter { selectedFoodIDs.contains($0.id) }.reduce(0) { $0 + $1.calories } }
    func totalProtein()  -> Double { visibleResults.filter { selectedFoodIDs.contains($0.id) }.reduce(0) { $0 + $1.protein } }
    func totalFat()      -> Double { visibleResults.filter { selectedFoodIDs.contains($0.id) }.reduce(0) { $0 + $1.fat } }
    func totalCarbs()    -> Double { visibleResults.filter { selectedFoodIDs.contains($0.id) }.reduce(0) { $0 + $1.carbs } }

    // MARK: - Knapsack

    func knapsack(foods: [Food], calorieLimit: Double,
                  proteinTarget: Double = 0, fatTarget: Double = 0, carbTarget: Double = 0) -> [Food] {
        guard calorieLimit > 0, !foods.isEmpty else { return foods }
        let eps = 0.0001
        let totalTarget = (proteinTarget * 4) + (fatTarget * 9) + (carbTarget * 4)

        func score(_ food: Food) -> Double {
            guard food.calories > eps else { return 0 }
            if totalTarget > 0 {
                let p = proteinTarget > 0 ? (food.protein * 4 / totalTarget) : 0
                let f = fatTarget > 0     ? (food.fat * 9 / totalTarget)     : 0
                let c = carbTarget > 0    ? (food.carbs * 4 / totalTarget)   : 0
                return (p + f + c) / food.calories
            }
            if trackProtein { return food.protein / food.calories }
            if trackFat     { return food.fat / food.calories }
            if trackCarbs   { return food.carbs / food.calories }
            return 1.0 / food.calories
        }

        var remaining = calorieLimit
        var selected: [Food] = []
        for food in foods.filter({ $0.calories > 0 }).sorted(by: { score($0) > score($1) }) {
            if food.calories <= remaining { selected.append(food); remaining -= food.calories }
        }
        return selected
    }

    // MARK: - Legacy saveMeal

    func saveMeal() {
        guard !chosenFoods.isEmpty else { return }
        mealHistory.append(chosenFoods)
        persistHistory()
        let meal = Meal(date: Date(),
                        items: chosenFoods.map { MealItem(food: $0, amount: 100, unit: .gram) },
                        totalCalories: chosenFoods.reduce(0) { $0 + $1.calories },
                        totalProtein:  chosenFoods.reduce(0) { $0 + $1.protein },
                        totalFat:      chosenFoods.reduce(0) { $0 + $1.fat },
                        totalCarbs:    chosenFoods.reduce(0) { $0 + $1.carbs })
        addMealToToday(meal)
        updateTodayProgress()
        chosenFoods = []
    }

    // MARK: - Meal Management

    private func addMealToToday(_ meal: Meal) {
        let key = dateString(from: Date())
        var meals = dailyMeals[key] ?? []
        meals.append(meal)
        dailyMeals[key] = meals
        persistDailyMeals()
    }

    func getMeals(for date: Date) -> [Meal] { dailyMeals[dateString(from: date)] ?? [] }

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
        let day = TrackedDay(date: date,
                             calories: meals.reduce(0) { $0 + $1.totalCalories },
                             protein:  meals.reduce(0) { $0 + $1.totalProtein },
                             carbs:    meals.reduce(0) { $0 + $1.totalCarbs },
                             fat:      meals.reduce(0) { $0 + $1.totalFat },
                             goalCalories: goals.calories)
        trackedDays.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
        trackedDays.append(day)
        persistTrackedDays()
    }

    func getTrackedDay(for date: Date) -> TrackedDay? {
        trackedDays.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Persistence

    func saveGoals() {
        if let data = try? JSONEncoder().encode(goals) { storage.set(data, forKey: goalsKey) }
    }

    private func loadGoals() {
        guard let data = storage.data(forKey: goalsKey),
              let decoded = try? JSONDecoder().decode(Goals.self, from: data) else { return }
        goals = decoded
    }

    func saveDietaryProfile() {
        if let data = try? JSONEncoder().encode(dietaryProfile) { storage.set(data, forKey: dietaryProfileKey) }
    }

    private func loadDietaryProfile() {
        guard let data = storage.data(forKey: dietaryProfileKey),
              let decoded = try? JSONDecoder().decode(DietaryProfile.self, from: data) else { return }
        dietaryProfile = decoded
    }

    func savePreferences() {
        storage.set(["calories": trackCalories, "protein": trackProtein,
                     "fat": trackFat, "carbs": trackCarbs], forKey: prefsKey)
    }

    private func loadPreferences() {
        guard let p = storage.dictionary(forKey: prefsKey) as? [String: Bool] else { return }
        trackCalories = p["calories"] ?? true
        trackProtein  = p["protein"]  ?? true
        trackFat      = p["fat"]      ?? true
        trackCarbs    = p["carbs"]    ?? true
    }

    private func persistHistory() {
        if let data = try? JSONEncoder().encode(mealHistory) { storage.set(data, forKey: historyKey) }
    }

    private func loadHistory() {
        guard let data = storage.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([[Food]].self, from: data) else { return }
        mealHistory = decoded
    }

    private func persistTrackedDays() {
        if let data = try? JSONEncoder().encode(trackedDays) { storage.set(data, forKey: trackedDaysKey) }
    }

    private func loadTrackedDays() {
        guard let data = storage.data(forKey: trackedDaysKey),
              let decoded = try? JSONDecoder().decode([TrackedDay].self, from: data) else { return }
        trackedDays = decoded
    }

    private func persistDailyMeals() {
        if let data = try? JSONEncoder().encode(dailyMeals) { storage.set(data, forKey: dailyMealsKey) }
    }

    private func loadDailyMeals() {
        guard let data = storage.data(forKey: dailyMealsKey),
              let decoded = try? JSONDecoder().decode([String: [Meal]].self, from: data) else { return }
        dailyMeals = decoded
    }

    // MARK: - Helpers

    private func dateString(from date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }

    func searchOpenFoodFactsRaw(query: String) async throws -> [Food] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encoded)&search_simple=1&action=process&json=1&page_size=30")
        else { throw URLError(.badURL) }
        let data = try await network.get(url: url, ttl: 300)
        let decoded = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
        return decoded.products.compactMap { p in
            guard let name = p.product_name, !name.isEmpty, let n = p.nutriments else { return nil }
            return Food(name: name, calories: n.energyKcal100g ?? 0, protein: n.proteins100g ?? 0,
                        fat: n.fat100g ?? 0, carbs: n.carbohydrates100g ?? 0)
        }
    }

    private func searchUSDAraw(query: String) async throws -> [Food] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(encoded)&api_key=\(Secrets.usdaKey)")
        else { throw URLError(.badURL) }
        let data = try await network.get(url: url, ttl: 300)
        let decoded = try JSONDecoder().decode(USDAResponse.self, from: data)
        return decoded.foods.map { Food(name: $0.description, calories: $0.calories, protein: $0.protein,
                                        fat: $0.fat, carbs: $0.carbs) }
    }

    private func localFallbackFoods(query: String) -> [Food] {
        [Food(name: "Cheese Quesadilla", calories: 280, protein: 12, fat: 16, carbs: 22),
         Food(name: "Milk",              calories: 103, protein: 8,  fat: 2,  carbs: 12),
         Food(name: "Spaghetti",         calories: 220, protein: 8,  fat: 1,  carbs: 43)]
        .filter { $0.name.lowercased().contains(query.lowercased()) }
    }
}
