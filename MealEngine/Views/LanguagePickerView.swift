import SwiftUI

struct LanguagePickerView: View {
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        Picker(languageManager.text(for: "switch_language"), selection: $languageManager.currentLanguage) {
            Text("English").tag("en")
            Text("中文").tag("zh")
        }
        .pickerStyle(.segmented)
        .onChange(of: languageManager.currentLanguage) { _, newValue in
            languageManager.setLanguage(newValue)
        }
        .padding(.horizontal)
    }
}
