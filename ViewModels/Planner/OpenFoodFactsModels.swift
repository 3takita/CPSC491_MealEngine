import Foundation

// MARK: - Top-level response
struct OpenFoodFactsResponse: Codable {
    let products: [OpenFoodFactsProduct]
}

// MARK: - Product
struct OpenFoodFactsProduct: Codable {
    let product_name: String?
    let nutriments: OpenFoodFactsNutriments?
}

// MARK: - Nutrients
struct OpenFoodFactsNutriments: Codable {
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
