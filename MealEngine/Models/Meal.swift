/*
Purpose:
Represents a complete meal composed of multiple MealItem objects and aggregated nutrient totals.
HLFR Tied To:
HLFR-3: Meal Tracking & History
*/ 

import Foundation

struct Meal: Codable, Identifiable {
    var id = UUID()
    var date: Date = Date()
    var items: [MealItem]
    var totalCalories: Double = 0
    var totalProtein: Double = 0
    var totalFat: Double = 0
    var totalCarbs: Double = 0
}
