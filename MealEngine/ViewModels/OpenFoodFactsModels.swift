// This file contains API data structures

import Foundation

// Top-level response for Open Food Facts search API
struct OpenFoodFactsResponse: Codable {
    let products: [OFFProduct]
}

// Product model with the subset of fields we use
struct OFFProduct: Codable {
    let product_name: String?
    let nutriments: OFFNutriments?
}

// Nutrients used per 100g. All optional because some entries may lack data.
struct OFFNutriments: Codable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let fat100g: Double?
    let carbohydrates100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case fat100g = "fat_100g"
        case carbohydrates100g = "carbohydrates_100g"
    }
}
