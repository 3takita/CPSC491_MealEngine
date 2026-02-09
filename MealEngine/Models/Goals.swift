// Requirement Type:- Functional 
// Requirement Addressed:- The system shall store daily nutrition targets.
// Usage:- Provides Food Name, Calories, Protein, Carbs, Fat
// Used by: PlannerView, MealPlannerViewModel

import Foundation

struct Goals: Codable {
    var calories: Double = 0
    var protein: Double = 0
    var fat: Double = 0
    var carbs: Double = 0
    
    func goalsDictionary() -> [String: Double] {
        [
            "Calories": calories,
            "Protein": protein,
            "Fat": fat,
            "Carbs": carbs
        ]
    }
    
    func progress(
        currentCalories: Double,
        currentProtein: Double,
        currentFat: Double,
        currentCarbs: Double
    ) -> [String: Double] {
        [
            "Calories": currentCalories / calories,
            "Protein": currentProtein / protein,
            "Fat": currentFat / fat,
            "Carbs": currentCarbs / carbs
        ]
    }
}
