
// PURPOSE: Represents a single food entry inside a meal, including portion size and unit.
// HLFR: The system shall allow users to add food items to meals with quantitiies

import Foundation

struct MealItem: Codable, Identifiable {
    var id = UUID()
    var food: Food
    var amount: Double
    var unit: Unit
}

enum Unit: String, Codable, CaseIterable, Identifiable {
    case gram, serving, milliliter, piece
    var id: String { rawValue }
}
