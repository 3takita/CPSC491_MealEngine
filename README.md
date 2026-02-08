<<<<<<< HEAD
# CPSC491_MealEngine
Meals optimize for your goals
=======
# 🍽️ OptiMeal

**OptiMeal** is a Swift-based iOS app designed to help users optimize their meals based on personal health and dietary goals. Built with SwiftUI and leveraging the power of algorithms and persistent data storage, OptiMeal provides a personalized meal-planning experience.

---

## 📱 App Features

- ⚖️ **Optimizes meal plans** using the **Knapsack algorithm** to balance nutrition (calories, protein, fat, carbs) according to user-defined goals.
- 🍎 **Integrates with a food API** to fetch real-world food data.
- 💾 **Persistent storage** to save user preferences and meal plans locally.
- 🎨 Beautiful UI with **3 custom colors** and a clean, modern layout.
- 🧠 Utilizes 4 data types:  
  - `Double` for quantities and calorie counts  
  - `String` for food names and user preferences  
  - `Bool` for dietary filters and toggles  
  - Custom `Food` type for modeling nutrition info
- 📲 **3 Main Screens**:
  - **Welcome / Goal Setup** – set dietary goals and preferences
  - **Meal Planner** – select, edit, and generate meal plans
  - **Summary / Recommendations** – view optimized meals and stats

---

## 🧩 Core UI Elements

OptiMeal uses **8–9 essential SwiftUI elements** for interaction and layout:

- `Text`
- `TextField`
- `Toggle`
- `Slider`
- `Picker`
- `Button`
- `List`
- `NavigationView`
- `Image`

---

## 💾 Persistent Storage

User data is saved using **Swift's `@AppStorage` and `Codable` with `UserDefaults`**, enabling:

- Saving selected foods
- Remembering goals and settings
- Loading past meal plans at launch

---

## 🧮 Optimization Logic

Meal plans are optimized using a **0/1 Knapsack algorithm**, which selects the best combination of foods to meet:

- A calorie target
- Macronutrient ratios (protein, fat, carbs)
- User-defined filters (e.g., vegetarian, low-carb)

---

## 🎨 Custom Colors

The app uses a consistent theme with **3 main custom colors** for branding and visual consistency.

---

## 🔗 Technologies

- **Language**: Swift 5
- **UI Framework**: SwiftUI
- **Xcode**: 15+
- **Food API**: e.g., [OpenFoodFacts](https://world.openfoodfacts.org/data)
- **Storage**: `UserDefaults`, `Codable`, `@AppStorage`
- **Algorithm**: Knapsack for dietary optimization

---

## 📦 Installation

1. Clone the repository:
   ```bash
   git clone git@github.com:3takita/CPSC411_NutritionApp.git
2. Open the project in Xcode:
open OptiMeal.xcodeproj
3. Run on a simulator or physical iPhone.

🤝 Group Members and Contributors
-  `Stephen Anaba as Code Keeper`
-  `Liam Knight as Presenter`
-  `Jane Lin as API Lead`
-  `Curtis Quan-Tran as Data Lead`
-  `Angel Orduna as GUI Lead`

📝 License:
	This project is licensed under the MIT License. See LICENSE file for details..
>>>>>>> 660fef2 (Initial commit)
