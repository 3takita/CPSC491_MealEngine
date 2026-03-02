/*
Purpose:
Represents aggregated nutrient totals for a specific calendar day compared to goal values.
HLFR Tied To:
HLFR-3: Daily Progress Tracking
HLFR-4: Goal Comparison
*/

import Foundation

struct TrackedDay: Identifiable, Hashable, Codable {
    let id: UUID
    let date: Date
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var goalCalories: Double

    var progress: Double {
        guard goalCalories > 0 else { return 0 }
        return min(calories / goalCalories, 1)
    }
    
    init(id: UUID = UUID(), date: Date, calories: Double, protein: Double, carbs: Double, fat: Double, goalCalories: Double) {
        self.id = id
        self.date = date
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.goalCalories = goalCalories
    }
}
