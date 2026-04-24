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

    // MARK: - Outputs

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

    private let historyKey = "MealHistory"
    private let prefsKey = "NutrientPrefs"
    private let goalsKey = "UserGoals"
    private let trackedDaysKey = "TrackedDays"
    private let dailyMealsKey = "DailyMeals"

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
        loadTrackedDays()
        loadDailyMeals()
        updateTodayProgress()
    }

    // MARK: - Fetch Food
     // MARK: - Fetch Food
func fetchFood() {

    inputErrorMessage = nil

    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

    // MARK: Validation

    if trimmed.isEmpty {
        inputErrorMessage = "Please enter a food name before searching."
        return
    }

    if Double(trimmed) != nil {
        inputErrorMessage = "Food name cannot be a number."
        return
    }

    let trimmedCalorieLimit =
        calorieLimit.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmedCalorieLimit.isEmpty {
        inputErrorMessage = "Please enter a calorie limit."
        return
    }

    if trimmedCalorieLimit.first == "-" {
        inputErrorMessage = "Calorie limit cannot be negative."
        return
    }

    guard let limit = Double(trimmedCalorieLimit) else {
        inputErrorMessage = "Calorie limit must be a valid number."
        return
    }

    let encodedQuery =
        trimmed.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? trimmed

    // MARK: Primary URL (Stable legacy endpoint)

    guard let primaryURL = URL(string:
        "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&json=1&page_size=20"
    ) else {
        inputErrorMessage = "Invalid search request."
        return
    }

    // MARK: Backup URL

    guard let backupURL = URL(string:
        "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&json=1&page_size=10"
    ) else {
        inputErrorMessage = "Invalid backup request."
        return
    }

    Task { [weak self] in

        guard let self = self else { return }

        await MainActor.run {
            self.isLoading = true
            self.chosenFoods = []
        }

        do {

            print("========== FOOD SEARCH ==========")
            print("Query:", trimmed)
            print("Calorie Limit:", limit)
            print("Primary URL:", primaryURL.absoluteString)

            let foods = try await self.fetchFoods(
                from: primaryURL,
                calorieLimit: limit
            )

            await MainActor.run {

                self.chosenFoods = foods
                self.isLoading = false

                if foods.isEmpty {
                    self.inputErrorMessage =
                    "No foods found for '\(trimmed)'."
                }
            }

        } catch {

            print("Primary search failed:", error)
            print("Trying backup endpoint...")

            do {

                let foods = try await self.fetchFoods(
                    from: backupURL,
                    calorieLimit: limit
                )

                await MainActor.run {

                    self.chosenFoods = foods
                    self.isLoading = false

                    if foods.isEmpty {
                        self.inputErrorMessage =
                        "No foods found for '\(trimmed)'."
                    }
                }

            } catch {

                print("Backup search failed:", error)

                await MainActor.run {

                    self.isLoading = false
                    self.chosenFoods = []

                    if let urlError = error as? URLError {

                        switch urlError.code {

                        case .timedOut:
                            self.inputErrorMessage =
                            "The food database timed out."

                        case .notConnectedToInternet:
                            self.inputErrorMessage =
                            "No internet connection."

                        case .cannotConnectToHost:
                            self.inputErrorMessage =
                            "Unable to connect to food database."

                        case .badServerResponse:
                            self.inputErrorMessage =
                            "Food database is temporarily unavailable."

                        default:
                            self.inputErrorMessage =
                            "Network error: \(urlError.localizedDescription)"
                        }

                    } else if error is DecodingError {

                        self.inputErrorMessage =
                        "Food database returned unreadable data."

                    } else {

                        self.inputErrorMessage =
                        "Unable to fetch foods right now."
                    }
                }
            }
        }
    }
} // end of fetchFood function

// MARK: - Helper Fetch Function

private func fetchFoods(
    from url: URL,
    calorieLimit: Double
) async throws -> [Food] {

    let start = Date()

    let data = try await network.get(url: url, ttl: 300)

    let elapsed = Date().timeIntervalSince(start)

    print("Finished in \(elapsed) sec")
    print("Response bytes:", data.count)

    if let raw = String(data: data, encoding: .utf8) {
        print(raw.prefix(1000))
    }

    let decoded = try JSONDecoder()
        .decode(OpenFoodFactsResponse.self, from: data)

    print("Products returned:", decoded.products.count)

    let foods: [Food] = decoded.products.compactMap { product in

        guard let name = product.product_name,
              let nutr = product.nutriments else {
            return nil
        }

        return Food(
            name: name,
            calories: nutr.energyKcal100g ?? 0,
            protein: nutr.proteins100g ?? 0,
            fat: nutr.fat100g ?? 0,
            carbs: nutr.carbohydrates100g ?? 0
        )
    }

    print("Foods mapped:", foods.count)

    let optimized = knapsack(
        foods: foods,
        calorieLimit: calorieLimit
    )

    print("Foods selected:", optimized.count)

    return optimized
} // end of Helper fetchFood function 

    // MARK: - Knapsack Algorithm
    private func knapsack(
        foods: [Food],
        calorieLimit: Double
    ) -> [Food] {
        print("Knapsack input:", foods.count) // remove
        print("Limit:", calorieLimit) // remove
        guard calorieLimit > 0, !foods.isEmpty else { return [] }

        func nutrientValue(_ food: Food) -> Double {
            if trackProtein { return food.protein }
            if trackFat { return food.fat }
            if trackCarbs { return food.carbs }
            return food.calories
        }

        let eps = 0.0001

        let sorted = foods.sorted {
            (nutrientValue($0) / max($0.calories, eps)) >
            (nutrientValue($1) / max($1.calories, eps))
        }

        var remaining = calorieLimit
        var selected: [Food] = []

        for food in sorted {

            if remaining <= 0 { break }

            let cals = max(food.calories, 0)

            if cals <= remaining, cals > 0 {

                selected.append(food)
                remaining -= cals

            } else if cals > 0 {

                let fraction = remaining / cals

                selected.append(
                    Food(
                        name: food.name,
                        calories: food.calories * fraction,
                        protein: food.protein * fraction,
                        fat: food.fat * fraction,
                        carbs: food.carbs * fraction
                    )
                )

                remaining = 0
            }
        }
        print("Knapsack selected:", selected.count)
        return selected
    }

    // MARK: - Meal Management
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

        let items = chosenFoods.map {
            MealItem(food: $0, amount: 100, unit: .gram)
        }

        return Meal(
            date: Date(),
            items: items,
            totalCalories: chosenFoods.reduce(0) { $0 + $1.calories },
            totalProtein: chosenFoods.reduce(0) { $0 + $1.protein },
            totalFat: chosenFoods.reduce(0) { $0 + $1.fat },
            totalCarbs: chosenFoods.reduce(0) { $0 + $1.carbs }
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
        currentProtein = meals.reduce(0) { $0 + $1.totalProtein }
        currentFat = meals.reduce(0) { $0 + $1.totalFat }
        currentCarbs = meals.reduce(0) { $0 + $1.totalCarbs }

        updateTrackedDay(for: Date())
    }

    private func updateTrackedDay(for date: Date) {

        let meals = getMeals(for: date)

        let trackedDay = TrackedDay(
            date: date,
            calories: meals.reduce(0) { $0 + $1.totalCalories },
            protein: meals.reduce(0) { $0 + $1.totalProtein },
            carbs: meals.reduce(0) { $0 + $1.totalCarbs },
            fat: meals.reduce(0) { $0 + $1.totalFat },
            goalCalories: goals.calories
        )

        trackedDays.removeAll {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }

        trackedDays.append(trackedDay)

        persistTrackedDays()
    }

    func getTrackedDay(for date: Date) -> TrackedDay? {
        trackedDays.first {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }

    // MARK: - Totals

    func totalCalories() -> Double {
        trackCalories ? chosenFoods.reduce(0) { $0 + $1.calories } : 0
    }

    func totalProtein() -> Double {
        trackProtein ? chosenFoods.reduce(0) { $0 + $1.protein } : 0
    }

    func totalFat() -> Double {
        trackFat ? chosenFoods.reduce(0) { $0 + $1.fat } : 0
    }

    func totalCarbs() -> Double {
        trackCarbs ? chosenFoods.reduce(0) { $0 + $1.carbs } : 0
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

    func savePreferences() {

        let prefs: [String: Bool] = [
            "calories": trackCalories,
            "protein": trackProtein,
            "fat": trackFat,
            "carbs": trackCarbs
        ]

        storage.set(prefs, forKey: prefsKey)
    }

    private func loadPreferences() {

        guard let prefs =
            storage.dictionary(forKey: prefsKey) as? [String: Bool]
        else { return }

        trackCalories = prefs["calories"] ?? true
        trackProtein = prefs["protein"] ?? true
        trackFat = prefs["fat"] ?? false
        trackCarbs = prefs["carbs"] ?? false
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
}
