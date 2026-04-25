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
    func fetchFood() {

        inputErrorMessage = nil

        let trimmed =
        query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if trimmed.isEmpty {
            inputErrorMessage =
            "Please enter a food name."
            return
        }

        guard let limit = Double(calorieLimit) else {
            inputErrorMessage =
            "Enter valid calories."
            return
        }

        Task { [weak self] in

            guard let self = self else { return }

            await MainActor.run {
                self.isLoading = true
                self.chosenFoods = []
            }

            do {

                print("Trying OpenFoodFacts...")

                let foods = try await self.searchOpenFoodFacts(
                    query: trimmed,
                    calorieLimit: limit
                )

                await self.finishSearch(foods)

            } catch {

                print("OFF failed. Trying USDA...")

                do {

                    let foods = try await self.searchUSDA(
                        query: trimmed,
                        calorieLimit: limit
                    )

                    await self.finishSearch(foods)

                } catch {

                    print("USDA failed. Using local fallback.")

                    let foods =
                    self.localFallbackFoods(
                        query: trimmed,
                        calorieLimit: limit
                    )

                    await self.finishSearch(foods)
                }
            }
        }
    }// end of fetchFood function

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

    print("Evaluating:", food.name, "cal:", food.calories)

    let cals = max(food.calories, 0)

    if cals <= remaining {

        selected.append(food)
        remaining -= cals

    } else {
        // For Fractional-Knpasack (fraction of items)
        /*let fraction = remaining / cals

        selected.append(
            Food(
                name: food.name,
                calories: food.calories * fraction,
                protein: food.protein * fraction,
                fat: food.fat * fraction,
                carbs: food.carbs * fraction
            )
        )

        break */
        continue // 0/1 Knapsack (whole items only)
    }
}
        print("Knapsack selected:", selected.count)
        // print("Partial selected:", food.name)
        // print("Fraction:", fraction)
        // print("Calories added:", food.calories * fraction)
        print("Remaining:", remaining)
        // print("Skipped:", food.name, "needs", cals, "remaining", remaining)
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
    
    // MARK: - OpenFoodFacts Primary Search
    private func searchOpenFoodFacts(
        query: String,
        calorieLimit: Double
    ) async throws -> [Food] {

        let encoded =
        query.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? query

        guard let url = URL(string:
        "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encoded)&search_simple=1&action=process&json=1&page_size=20"
        ) else {
            throw URLError(.badURL)
        }

        print("Trying OpenFoodFacts:")
        print(url.absoluteString)

        let data = try await network.get(
            url: url,
            ttl: 300
        )

        let decoded = try JSONDecoder()
            .decode(OpenFoodFactsResponse.self, from: data)

        let foods: [Food] = decoded.products.compactMap { (product: OpenFoodFactsProduct) -> Food? in
            guard let name = product.product_name, let nutr = product.nutriments else {
                return nil
            }
            let calories: Double = nutr.energyKcal100g ?? 0
            let protein: Double = nutr.proteins100g ?? 0
            let fat: Double = nutr.fat100g ?? 0
            let carbs: Double = nutr.carbohydrates100g ?? 0
            return Food(
                name: name,
                calories: calories,
                protein: protein,
                fat: fat,
                carbs: carbs
            )
        }

        print("OpenFoodFacts foods found:", foods.count)

        return knapsack(
            foods: foods,
            calorieLimit: calorieLimit
        )
    } // enf of searchOpenFoodFacts
    
    // MARK: - USDA Backup Search
    private func searchUSDA(
        query: String,
        calorieLimit: Double
    ) async throws -> [Food] {

        let encoded =
        query.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? query

        guard let url = URL(string:
        "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(encoded)&api_key=\(Secrets.usdaKey)"
        ) else {
            throw URLError(.badURL)
        }

        print("Trying USDA:", url.absoluteString)

        let data = try await network.get(
            url: url,
            ttl: 300
        )

        let decoded = try JSONDecoder()
            .decode(USDAResponse.self, from: data)

        let foods: [Food] = decoded.foods.map { item in

            Food(
                name: item.description,
                calories: item.calories,
                protein: item.protein,
                fat: item.fat,
                carbs: item.carbs
            )
        }

        print("USDA foods found:", foods.count)

        return knapsack(
            foods: foods,
            calorieLimit: calorieLimit
        )
    } // end of searchUSDA
    
    // MARK: - Local Offline Fallback Foods
    private func localFallbackFoods(
        query: String,
        calorieLimit: Double
    ) -> [Food] {

        let foods = [

            Food(
                name: "Cheese Quesadilla",
                calories: 280,
                protein: 12,
                fat: 16,
                carbs: 22
            ),

            Food(
                name: "Milk",
                calories: 103,
                protein: 8,
                fat: 2,
                carbs: 12
            ),

            Food(
                name: "Spaghetti",
                calories: 220,
                protein: 8,
                fat: 1,
                carbs: 43
            )
        ]

        let filtered = foods.filter {
            $0.name.lowercased()
            .contains(query.lowercased())
        }

        return knapsack(
            foods: filtered,
            calorieLimit: calorieLimit
        )
    } // enf of localFallbackFoods
    
    // MARK: - Finish Search UI Update

    @MainActor
    private func finishSearch(
        _ foods: [Food]
    ) {

        self.chosenFoods = foods
        self.isLoading = false

        if foods.isEmpty {
            self.inputErrorMessage =
            "No foods found."
        }
    }
} // end of MealPlannerViewModel class

