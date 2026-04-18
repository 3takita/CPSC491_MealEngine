import Foundation

final class GoalsViewModel: ObservableObject {
    @Published var currentCalories: Double = 0
    @Published var currentProtein: Double = 0
    @Published var currentCarbs: Double = 0
    @Published var currentFat: Double = 0

    @Published var goals = Goals()

    func sync(from planner: MealPlannerViewModel) {
        currentCalories = planner.currentCalories
        currentProtein = planner.currentProtein
        currentCarbs = planner.currentCarbs
        currentFat = planner.currentFat
    }
}
