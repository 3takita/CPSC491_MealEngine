import SwiftUI

struct LocalizedText: View {
    @EnvironmentObject var languageManager: LanguageManager
    let key: String

    var body: some View {
        Text(languageManager.text(for: key))
    }
}
