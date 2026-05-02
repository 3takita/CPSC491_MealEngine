import SwiftUI
import Combine

final class AppState: ObservableObject {

    let plannerVM: MealPlannerViewModel
    let goalsVM: GoalsViewModel
    let historyVM: HistoryViewModel

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.plannerVM = MealPlannerViewModel()
        self.goalsVM   = GoalsViewModel()
        self.historyVM = HistoryViewModel()

        // Keep GoalsViewModel in sync whenever plannerVM publishes any change.
        plannerVM.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.goalsVM.sync(from: self.plannerVM)
            }
            .store(in: &cancellables)
    }
}
