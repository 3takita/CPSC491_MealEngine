import SwiftUI

struct LanguagePickerView: View {
    
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        Picker(
            languageManager.text(for: "switch_language", default: "Language"),
            selection: $languageManager.currentLanguage
        ) {
            ForEach(AppLanguage.allCases) { lang in
                Text(lang.displayName).tag(lang)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: languageManager.currentLanguage) {
            languageManager.setLanguage(languageManager.currentLanguage)
        }
        .padding(.horizontal)
    }
}

#Preview {
    LanguagePickerView()
        .environmentObject(LanguageManager())
}
