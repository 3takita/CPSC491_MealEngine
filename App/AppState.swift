import SwiftUI

final class AppState: ObservableObject {
    @Published var plannerVM = MealPlannerViewModel()
    @Published var goalsVM = GoalsViewModel()
    @Published var historyVM = HistoryViewModel()
}
