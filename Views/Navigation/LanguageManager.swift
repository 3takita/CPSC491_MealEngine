import SwiftUI

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case en
    case zh

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .en: return "English"
        case .zh: return "中文"
        }
    }
}

// MARK: - Language Manager

final class LanguageManager: ObservableObject {
    @Published var currentLanguage: AppLanguage {
        didSet { persist() }
    }

    private let storageKey = "AppLanguage"

    // A lightweight key-based translation store
    // Add new keys here as your app grows.
    private let translations: [String: [AppLanguage: String]] = [
        // General
        "switch_language": [.en: "Language", .zh: "语言"],
        "settings": [.en: "Settings", .zh: "设置"],
        "goals_section": [.en: "Goals", .zh: "目标"],
        "calculate_goals_tdee": [.en: "Calculate Goals (TDEE)", .zh: "计算目标（TDEE）"],
        "goal_calculator_title": [.en: "Goal Calculator", .zh: "目标计算器"],

        // Sections
        "personal_info": [.en: "Personal Info", .zh: "个人信息"],
        "body_measurements": [.en: "Body Measurements", .zh: "身体数据"],
        "activity_level": [.en: "Activity Level", .zh: "活动水平"],
        "your_goal": [.en: "Your Goal", .zh: "你的目标"],

        // Inputs
        "biological_sex": [.en: "Biological Sex", .zh: "生理性别"],
        "age": [.en: "Age", .zh: "年龄"],
        "weight": [.en: "Weight", .zh: "体重"],
        "height": [.en: "Height", .zh: "身高"],

        // Buttons
        "calculate_my_goals": [.en: "Calculate My Goals", .zh: "计算我的目标"],
        "apply_these_goals": [.en: "Apply These Goals", .zh: "应用这些目标"],
        "close": [.en: "Close", .zh: "关闭"],
        "apply": [.en: "Apply", .zh: "应用"],
        "cancel": [.en: "Cancel", .zh: "取消"],
    ]

    init() {
        if let saved = UserDefaults.standard.string(forKey: storageKey),
           let lang = AppLanguage(rawValue: saved) {
            currentLanguage = lang
        } else {
            // Default to device language if possible
            let deviceLang = Locale.preferredLanguages.first ?? "en"
            if deviceLang.hasPrefix("zh") {
                currentLanguage = .zh
            } else {
                currentLanguage = .en
            }
        }
    }

    func setLanguage(_ language: AppLanguage) {
        guard currentLanguage != language else { return }
        currentLanguage = language
    }

    func text(for key: String, default defaultText: String? = nil) -> String {
        if let value = translations[key]?[currentLanguage] {
            return value
        }
        if let defaultText { return defaultText }
        return key
    }

    private func persist() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: storageKey)
    }
}
