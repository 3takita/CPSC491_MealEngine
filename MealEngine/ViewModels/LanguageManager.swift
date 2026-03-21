import SwiftUI

@MainActor
class LanguageManager: ObservableObject {
    
    @Published var currentLanguage: String
    @Published var translations: [String: String] = [:]
    
    init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        loadTranslations()
    }
    
    func setLanguage(_ language: String) {
        currentLanguage = language
        UserDefaults.standard.set(language, forKey: "appLanguage")
        loadTranslations()
    }
    
    func loadTranslations() {
        if currentLanguage == "zh" {
            translations = [
                "welcome": "欢迎",
                "meal_planner": "餐食规划",
                "summary": "总结",
                "switch_language": "切换语言"
            ]
        } else {
            translations = [
                "welcome": "Welcome",
                "meal_planner": "Meal Planner",
                "summary": "Summary",
                "switch_language": "Switch Language"
            ]
        }
    }
    
    func text(for key: String) -> String {
        translations[key] ?? key
    }
}
