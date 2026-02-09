// Requirement Type:- Functional
// Requirement Addressed:- The system shall represent a collection of foods as a meal
// Usage: saveMeal() and Future history (next project phase). 

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
