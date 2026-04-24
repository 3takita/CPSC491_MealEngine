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
        value(1008)
    }

    var protein: Double {
        value(1003)
    }

    var fat: Double {
        value(1004)
    }

    var carbs: Double {
        value(1005)
    }

    private func value(_ id: Int) -> Double {

        foodNutrients.first {
            $0.nutrientId == id
        }?.value ?? 0
    }
}

// MARK: - Nutrient Entry

struct USDANutrient: Codable {

    let nutrientId: Int
    let value: Double

    enum CodingKeys: String, CodingKey {
        case nutrientId = "nutrientId"
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        value = try container.decode(Double.self, forKey: .value)

        // Try both formats safely
        if let id = try? container.decode(Int.self, forKey: .nutrientId) {
            nutrientId = id
        } else {
            nutrientId = 0
        }
    }
}
