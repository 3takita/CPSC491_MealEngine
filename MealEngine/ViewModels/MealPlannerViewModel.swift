//
//  MealPlannerViewModel.swift
//  NutriPlanner -- Meals optimized for your goals
//  Features: knapsack algorithm, Open Food Facts API
//  Required: 3 data types (string, double, bool. Food), 3 screens, 3 colors, 3 GUI objects (8-9 core UI elements)
//  ...and persistent data storage
//  ============================
//  Group Members:
//  ----------------------------
//  1.  Stephen Anaba as Code Keeper
//  2.  Liam Knight as Presenter
//  3.  Jane Lin as API Lead
//  4.  Curtis Quan-Tran as Data Lead
//  5.  Angel Orduna as GUI Lead
//  ============================

import Foundation
import Combine

class MealPlannerViewModel: ObservableObject {
    // MARK: - User Inputs / state
    @Published var inputErrorMessage: String? // input validation
    @Published var calorieLimit: String = ""
    @Published var query: String = ""
    @Published var goals = Goals(calories: 2000, protein: 150, fat: 65, carbs: 250)
    
    // MARK: - Outputs
    @Published var chosenFoods: [Food] = []
    // @Published var mealHistory: [[Food]] = []
    
    // MARK: - Preferences
    /* @Published var trackCalories: Bool = true
    @Published var trackProtein: Bool = true
    @Published var trackFat: Bool = false
    @Published var trackCarbs: Bool = false */
    
    // MARK: - Current Progress (Today)
    @Published var currentCalories: Double = 0
    @Published var currentProtein: Double = 0
    @Published var currentFat: Double = 0
    @Published var currentCarbs: Double = 0
    
    // MARK: - Historical Tracking
    /* @Published var trackedDays: [TrackedDay] = []
    @Published var dailyMeals: [String: [Meal]] = [:] */ // date string -> meals

    // MARK: - Persistence Keys
    /* private let historyKey = "MealHistory"
    private let prefsKey = "NutrientPrefs"
    private let goalsKey = "UserGoals"
    private let trackedDaysKey = "TrackedDays"
    private let dailyMealsKey = "DailyMeals" */
    
    // MARK: - Init
    init() {
        /* loadHistory()
        loadPreferences()
        loadGoals()
        loadTrackedDays()
        loadDailyMeals() */
        updateTodayProgress()
    }
    
    // MARK: - Fetch food from Open Food Facts API
    /* func fetchFood() {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

    // --- VALIDATION 1: empty food input ----
    if trimmed.isEmpty {
        DispatchQueue.main.async {
            self.inputErrorMessage = "Please enter a food name before searching."
        }
        return
    }

    // --- VALIDATION 2: food name must NOT be a number ----
    if Double(trimmed) != nil {
        DispatchQueue.main.async {
            self.inputErrorMessage = "Food name cannot be a number."
        }
        return
    }

    // Handle calorieLimit validations
    let trimmedCalorieLimit = calorieLimit.trimmingCharacters(in: .whitespacesAndNewlines)

    // --- VALIDATION 3: calorieLimit empty (no entry) ---
    if trimmedCalorieLimit.isEmpty {
        DispatchQueue.main.async {
            self.inputErrorMessage = "Please enter a calorie limit."
        }
        return
    }

    // --- VALIDATION 4: calorieLimit negative ---
    if trimmedCalorieLimit.first == "-" {
        DispatchQueue.main.async {
            self.inputErrorMessage = "Calorie limit cannot be negative."
        }
        return
    }

    // --- VALIDATION 5: calorieLimit must be numeric ---
    if Double(trimmedCalorieLimit) == nil {
        DispatchQueue.main.async {
            self.inputErrorMessage = "Calorie limit must be a valid number."
        }
        return
    }

    // Continue with actual API fetch...
    let encodedQuery = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
    let urlString = "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&json=1"
    guard let url = URL(string: urlString) else { return }

    URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
        guard let self = self else { return }
        guard error == nil, let data = data else {
            DispatchQueue.main.async { self.chosenFoods = [] }
            return
        }

        do {
            let decoded = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)

            let foods: [Food] = decoded.products.compactMap { product in
                guard let name = product.product_name,
                      let nutr = product.nutriments else { return nil }

                let kcal   = nutr.energyKcal100g ?? 0
                let protein = nutr.proteins100g ?? 0
                let fat     = nutr.fat100g ?? 0
                let carbs   = nutr.carbohydrates100g ?? 0

                return Food(name: name, calories: kcal, protein: protein, fat: fat, carbs: carbs)
            }

            DispatchQueue.main.async {
                if let limit = Double(trimmedCalorieLimit), limit > 0 {
                    self.chosenFoods = self.knapsack(foods: foods, calorieLimit: limit)
                } else {
                    self.chosenFoods = foods
                }
            }
        } catch {
            DispatchQueue.main.async { self.chosenFoods = [] }
        }
    }.resume()
}*/ // end of fetchFood()


    // MARK: - Knapsack Algorithm
    private func knapsack(foods: [Food], calorieLimit: Double) -> [Food] {
        guard calorieLimit > 0, !foods.isEmpty else { return [] }
        
        func nutrientValue(_ food: Food) -> Double {
            /* if trackProtein { return food.protein }
            if trackFat { return food.fat }
            if trackCarbs { return food.carbs } */
            return food.calories
        }
        
        let eps = 1e-6
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
                let fraction = max(min(remaining / cals, 1.0), 0.0)
                let partial = Food(
                    name: food.name,
                    calories: food.calories * fraction,
                    protein:  food.protein * fraction,
                    fat:      food.fat * fraction,
                    carbs:    food.carbs * fraction
                )
                selected.append(partial)
                remaining = 0
            } else {
                if nutrientValue(food) > 0 {
                    selected.append(food)
                }
            }
        }

        return selected
    }
    
    // MARK: - Meal Management
    
    func saveMeal() {
        guard !chosenFoods.isEmpty else { return }
        
        // Save to history
        // mealHistory.append(chosenFoods) // removed
        // persistHistory()
        
        // Create meal and add to today
        let meal = createMealFromChosenFoods()
        // addMealToToday(meal)
        
        // Update today's progress
        // updateTodayProgress()
        
        // Clear chosen foods
        chosenFoods = []
    }
    
    private func createMealFromChosenFoods() -> Meal {
        let items = chosenFoods.map { food in
            MealItem(food: food, amount: 100, unit: .gram)
        }
        
        let totalCals = chosenFoods.reduce(0) { $0 + $1.calories }
        let totalProt = chosenFoods.reduce(0) { $0 + $1.protein }
        let totalFat = chosenFoods.reduce(0) { $0 + $1.fat }
        let totalCarbs = chosenFoods.reduce(0) { $0 + $1.carbs }
        
        return Meal(
            date: Date(),
            items: items,
            totalCalories: totalCals,
            totalProtein: totalProt,
            totalFat: totalFat,
            totalCarbs: totalCarbs
        )
    }
    
    /* private func addMealToToday(_ meal: Meal) {
        let dateKey = dateString(from: Date())
        var meals = dailyMeals[dateKey] ?? []
        meals.append(meal)
        dailyMeals[dateKey] = meals
        persistDailyMeals()
    }
    
    func getMeals(for date: Date) -> [Meal] {
        let dateKey = dateString(from: date)
        return dailyMeals[dateKey] ?? []
    } */
    
    // MARK: - Progress Tracking
    
    func updateTodayProgress() {
        currentCalories = chosenFoods.reduce(0) { $0 + $1.calories }
        currentProtein = chosenFoods.reduce(0) { $0 + $1.protein }
        currentFat = chosenFoods.reduce(0) { $0 + $1.fat }
        currentCarbs = chosenFoods.reduce(0) { $0 + $1.carbs }

        /*let today = Date()
        let meals = getMeals(for: today)
        
        currentCalories = meals.reduce(0) { $0 + $1.totalCalories }
        currentProtein = meals.reduce(0) { $0 + $1.totalProtein }
        currentFat = meals.reduce(0) { $0 + $1.totalFat }
        currentCarbs = meals.reduce(0) { $0 + $1.totalCarbs } */
        
        // Update or create tracked day
        // updateTrackedDay(for: today)
    }
    
    /* private func updateTrackedDay(for date: Date) {
        let meals = getMeals(for: date)
        let calories = meals.reduce(0) { $0 + $1.totalCalories }
        let protein = meals.reduce(0) { $0 + $1.totalProtein }
        let fat = meals.reduce(0) { $0 + $1.totalFat }
        let carbs = meals.reduce(0) { $0 + $1.totalCarbs }
        
        let trackedDay = TrackedDay(
            date: date,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            goalCalories: goals.calories
        )
        
        // Remove existing entry for this date
        trackedDays.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
        trackedDays.append(trackedDay)
        
        persistTrackedDays()
    }
    
    func getTrackedDay(for date: Date) -> TrackedDay? {
        trackedDays.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    } */
    
    // MARK: - Totals
    
    func totalCalories() -> Double {
        /* guard trackCalories else { return 0 }
        return */ chosenFoods.reduce(0) { $0 + $1.calories } 
    }

    func totalProtein() -> Double {
        /* guard trackProtein else { return 0 }
        return */ chosenFoods.reduce(0) { $0 + $1.protein }
    }

    func totalFat() -> Double {
        /* guard trackFat else { return 0 }
        return */ chosenFoods.reduce(0) { $0 + $1.fat }
    }

    func totalCarbs() -> Double {
        /* guard trackCarbs else { return 0 }
        return */ chosenFoods.reduce(0) { $0 + $1.carbs }
    }
    
    // MARK: - Persistence
    /*
    func saveGoals() {
        do {
            let data = try JSONEncoder().encode(goals)
            UserDefaults.standard.set(data, forKey: goalsKey)
        } catch {
            print("Failed to save goals: \(error)")
        }
    }
    
    private func loadGoals() {
        guard let data = UserDefaults.standard.data(forKey: goalsKey) else { return }
        if let decoded = try? JSONDecoder().decode(Goals.self, from: data) {
            goals = decoded
        }
    }
    
    func savePreferences() {
        let prefs: [String: Bool] = [
            "calories": trackCalories,
            "protein": trackProtein,
            "fat": trackFat,
            "carbs": trackCarbs
        ]
        UserDefaults.standard.set(prefs, forKey: prefsKey)
    }
    
    private func loadPreferences() {
        guard let prefs = UserDefaults.standard.dictionary(forKey: prefsKey) as? [String: Bool] else { return }
        trackCalories = prefs["calories"] ?? true
        trackProtein  = prefs["protein"]  ?? true
        trackFat      = prefs["fat"]      ?? false
        trackCarbs    = prefs["carbs"]    ?? false
    }
    
    private func persistHistory() {
        do {
            let data = try JSONEncoder().encode(mealHistory)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return }
        if let decoded = try? JSONDecoder().decode([[Food]].self, from: data) {
            mealHistory = decoded
        }
    }
    
    private func persistTrackedDays() {
        do {
            let data = try JSONEncoder().encode(trackedDays)
            UserDefaults.standard.set(data, forKey: trackedDaysKey)
        } catch {
            print("Failed to save tracked days: \(error)")
        }
    }
    
    private func loadTrackedDays() {
        guard let data = UserDefaults.standard.data(forKey: trackedDaysKey) else { return }
        if let decoded = try? JSONDecoder().decode([TrackedDay].self, from: data) {
            trackedDays = decoded
        }
    }
    
    private func persistDailyMeals() {
        do {
            let data = try JSONEncoder().encode(dailyMeals)
            UserDefaults.standard.set(data, forKey: dailyMealsKey)
        } catch {
            print("Failed to save daily meals: \(error)")
        }
    }
    
    private func loadDailyMeals() {
        guard let data = UserDefaults.standard.data(forKey: dailyMealsKey) else { return }
        if let decoded = try? JSONDecoder().decode([String: [Meal]].self, from: data) {
            dailyMeals = decoded
        }
    } */
    
    // MARK: - Helper
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
