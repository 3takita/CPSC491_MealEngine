/*
Purpose:
Represents a food item with nutritional data (calories, protein, fat, carbs). Used for API decoding and meal calculations.
HLFR Tied To:
HLFR-1: Food Search & Retrieval
HLFR-2: Nutrient Optimization
*/

import Foundation

struct Food: Codable, Identifiable {
    var id = UUID()
    let name: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
}
