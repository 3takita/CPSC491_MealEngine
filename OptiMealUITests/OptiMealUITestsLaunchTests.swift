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

final class OptiMealUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
