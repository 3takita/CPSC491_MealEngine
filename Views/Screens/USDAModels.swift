// Maps USDA nutrients

import Foundation

// MARK: - Top Level USDA Response

struct USDAResponse: Codable {
    let foods: [USDAFood]
}

// MARK: - Food Item

struct USDAFood: Codable {

    let description: String
    let foodNutrients: [USDANutrient]

    var calories: Double {
        nutrientValue(for: "1008")
    }

    var protein: Double {
        nutrientValue(for: "1003")
    }

    var fat: Double {
        nutrientValue(for: "1004")
    }

    var carbs: Double {
        nutrientValue(for: "1005")
    }

    private func nutrientValue(
        for number: String
    ) -> Double {

        foodNutrients.first {
            $0.nutrientNumber == number
        }?.value ?? 0
    }
}

// MARK: - Nutrient Entry

struct USDANutrient: Codable {

    let nutrientNumber: String
    let value: Double
}
