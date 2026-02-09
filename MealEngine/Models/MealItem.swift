// Requirement Type:- Functional
// Requirement Description:- The system shall represent a food with quantity and units
// Usage:- For portion abstraction; critical for scaling and editing meals

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
