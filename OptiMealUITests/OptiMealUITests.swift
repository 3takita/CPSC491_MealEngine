//  ContentView.swift
//  NutriPlanner -- Meals optimized for your goals
//  Features: knapsack algorithm, Nutrionix API
//  Required: 3 data types (string, double, bool. Food), 3 screens, 3 colors, 3 GUI objects (8-9 core UI elements)
//  ...and persistent data storage
//  ==================
//  Group Members: 
//  ------------------
//  1.	Stephen Anaba as Code Keeper
//  2.	Liam Knight as Presenter
//  3.  Jane Lin as API Lead
//  4.  Curtis Quan-Tran as Data Lead
//  5.  Angel Orduna as GUI Lead 
//  ====================

import XCTest

final class OptiMealUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
