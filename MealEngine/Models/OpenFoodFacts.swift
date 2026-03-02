/*
Purpose:
Decoding structure for parsing JSON responses from the Open Food Facts API.
HLFR Tied To:
HLFR-1: Food Search & Retrieval
*/

import Foundation

/// API response from Open Food Facts
struct OpenFoodFactsResponse: Codable {
    let products: [OpenFoodProduct]
}

/// Product returned from Open Food Facts
struct OpenFoodProduct: Codable {
    let product_name: String?
    let nutriments: Nutriments?
}

/// Nutritional info returned from Open Food Facts
struct Nutriments: Codable {
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
