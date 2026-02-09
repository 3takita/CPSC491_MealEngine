// Functional Requirement:- The system shall represent a food item with nutritional values.
// Non-functional Requirement:- Provides Food Name, Calories, Protein, Carbs, Fat

import Foundation

struct Food: Codable, Identifiable {
    var id = UUID()
    let name: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
}
