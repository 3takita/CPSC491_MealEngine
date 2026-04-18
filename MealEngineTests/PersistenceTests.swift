import XCTest
@testable import MealEngine

final class PersistenceTests: XCTestCase {

    func testPreferencesSaveAndLoad() {

        let vm = MealPlannerViewModel()

        vm.trackCalories = false
        vm.trackProtein = true
        vm.trackFat = true
        vm.trackCarbs = false

        vm.savePreferences()

        let reloaded = MealPlannerViewModel()

        XCTAssertFalse(reloaded.trackCalories)
        XCTAssertTrue(reloaded.trackProtein)
        XCTAssertTrue(reloaded.trackFat)
        XCTAssertFalse(reloaded.trackCarbs)
    }
}
