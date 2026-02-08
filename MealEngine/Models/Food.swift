import Foundation

/// Represents a food item
struct Food: Codable, Identifiable {
    var id = UUID()
    let name: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
}