import XCTest

final class MealEngineUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testAppLaunches() {
        XCTAssertTrue(app.exists)
    }

    func testNavigateToSettings() {
        app.buttons["Settings"].tap()
    }

    func testNavigateToHistory() {
        app.buttons["History"].tap()
    }

    func testNavigateToPlanner() {
        app.buttons["Planner"].tap()
    }
}
