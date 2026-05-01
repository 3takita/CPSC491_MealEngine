// PURPOSE: Stores the user's dietary restrictions and preferences.
// Used to filter food search results and drive smart recommendations.

import Foundation

enum DietaryRestriction: String, CaseIterable, Codable, Identifiable {
    case vegetarian  = "Vegetarian"
    case vegan       = "Vegan"
    case glutenFree  = "Gluten-Free"
    case dairyFree   = "Dairy-Free"
    case keto        = "Keto"
    case paleo       = "Paleo"
    case lowSodium   = "Low Sodium"
    case halal       = "Halal"
    case kosher      = "Kosher"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .vegetarian: return "leaf.fill"
        case .vegan:      return "leaf.fill"
        case .glutenFree: return "g.circle.fill"
        case .dairyFree:  return "drop.fill"
        case .keto:       return "bolt.fill"
        case .paleo:      return "flame.fill"
        case .lowSodium:  return "heart.fill"
        case .halal:      return "star.fill"
        case .kosher:     return "star.circle.fill"
        }
    }

    /// Keywords appended to API queries so the API does the heavy filtering
    var searchKeyword: String {
        switch self {
        case .vegetarian: return "vegetarian"
        case .vegan:      return "vegan"
        case .glutenFree: return "gluten free"
        case .dairyFree:  return "dairy free"
        case .keto:       return "keto"
        case .paleo:      return "paleo"
        case .lowSodium:  return "low sodium"
        case .halal:      return "halal"
        case .kosher:     return "kosher"
        }
    }

    /// Client-side macro guard — quick sanity check after API results come in
    func passes(_ food: Food) -> Bool {
        switch self {
        case .keto:
            return food.carbs < 10   // <10g carbs per 100g
        default:
            return true              // rely on keyword filtering from API
        }
    }
}

struct DietaryProfile: Codable {
    var restrictions: Set<DietaryRestriction> = []

    /// Builds the extra query fragment to append to API searches
    var searchSuffix: String {
        restrictions.map { $0.searchKeyword }.joined(separator: " ")
    }

    /// Returns true if this food passes all active client-side restriction checks
    func allows(_ food: Food) -> Bool {
        restrictions.allSatisfy { $0.passes(food) }
    }
}
