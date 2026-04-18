/* import SwiftUI

final class AppState: ObservableObject {
    @Published var plannerVM = MealPlannerViewModel()
    @Published var goalsVM = GoalsViewModel()
    @Published var historyVM = HistoryViewModel()
} */

import SwiftUI

final class AppState: ObservableObject {

    let plannerVM: MealPlannerViewModel
    let goalsVM: GoalsViewModel
    let historyVM: HistoryViewModel

    init() {
        self.plannerVM = MealPlannerViewModel()
        self.goalsVM = GoalsViewModel()
        self.historyVM = HistoryViewModel()
    }
}
