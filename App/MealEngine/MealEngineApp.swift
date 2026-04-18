/*
PURPOSE: Application entry point. Initializes the SwiftUI app lifecycle and creates the root ViewModel instance.
HLFR: The system shall launch the MealEngine application & present
the primary interface to the user
*/

import SwiftUI

@main
struct MealEngineApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
        }
    }
}
