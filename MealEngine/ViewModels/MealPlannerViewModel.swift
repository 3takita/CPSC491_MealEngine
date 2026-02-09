// Requirement Type:- Functional
// Requirement Description: The system shall validate user input, calculate totals and manage curent meal selection by holding chosenFoods, calculates macro totals, creates meal objects, saves meal locally and updates progress.

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
    
    // MARK: - Current Progress (Today)
    @Published var currentCalories: Double = 0
    @Published var currentProtein: Double = 0
    @Published var currentFat: Double = 0
    @Published var currentCarbs: Double = 0 
    
    // MARK: - Init
    init() { 
        updateTodayProgress()
    } 

    // MARK: - Knapsack Algorithm
    private func knapsack(foods: [Food], calorieLimit: Double) -> [Food] {
        guard calorieLimit > 0, !foods.isEmpty else { return [] }
        
        func nutrientValue(_ food: Food) -> Double { 
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
    
    // MARK: - Progress Tracking
    
    func updateTodayProgress() {
        currentCalories = chosenFoods.reduce(0) { $0 + $1.calories }
        currentProtein = chosenFoods.reduce(0) { $0 + $1.protein }
        currentFat = chosenFoods.reduce(0) { $0 + $1.fat }
        currentCarbs = chosenFoods.reduce(0) { $0 + $1.carbs } 
    } 
    
    // MARK: - Totals
    
    func totalCalories() -> Double {
        chosenFoods.reduce(0) { $0 + $1.calories } 
    }

    func totalProtein() -> Double {
        chosenFoods.reduce(0) { $0 + $1.protein }
    }

    func totalFat() -> Double {
        chosenFoods.reduce(0) { $0 + $1.fat }
    }

    func totalCarbs() -> Double {
        chosenFoods.reduce(0) { $0 + $1.carbs }
    }
    
    // MARK: - Helper
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
