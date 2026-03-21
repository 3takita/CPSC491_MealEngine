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
            "planner": "规划",
            "history": "历史",
            "goals": "目标",
            "settings": "设置",
            "summary": "总结",
            "switch_language": "切换语言",
            "invalid_input": "输入无效",
            "ok": "确定",

            "track_calories": "追踪热量",
            "track_protein": "追踪蛋白质",
            "track_fat": "追踪脂肪",
            "track_carbs": "追踪碳水"
        ]
    } else {
        translations = [
            "welcome": "Welcome",
            "planner": "Planner",
            "history": "History",
            "goals": "Goals",
            "settings": "Settings",
            "summary": "Summary",
            "switch_language": "Switch Language",
            "invalid_input": "Invalid Input",
            "ok": "OK",

            "track_calories": "Track Calories",
            "track_protein": "Track Protein",
            "track_fat": "Track Fat",
            "track_carbs": "Track Carbs"
        ]
    }
}
    
    func text(for key: String) -> String {
        translations[key] ?? key
    }
}
