import XCTest
@testable import MealEngine

final class TDEECalculatorTests: XCTestCase {

    // Tests enum values used in TDEE screen

    func testActivityMultiplierModerate() {
        XCTAssertEqual(ActivityLevel.moderate.multiplier, 1.55)
    }

    func testActivityMultiplierSedentary() {
        XCTAssertEqual(ActivityLevel.sedentary.multiplier, 1.2)
    }

    func testCuttingAdjustment() {
        XCTAssertEqual(PhysiqGoal.cutting.calorieAdjustment, -500)
    }

    func testMaintainingAdjustment() {
        XCTAssertEqual(PhysiqGoal.maintaining.calorieAdjustment, 0)
    }

    func testBulkingAdjustment() {
        XCTAssertEqual(PhysiqGoal.bulking.calorieAdjustment, 300)
    }

    func testWeightUnitExists() {
        XCTAssertEqual(WeightUnit.kg.rawValue, "kg")
        XCTAssertEqual(WeightUnit.lbs.rawValue, "lbs")
    }

    func testHeightUnitExists() {
        XCTAssertEqual(HeightUnit.cm.rawValue, "cm")
        XCTAssertEqual(HeightUnit.ft.rawValue, "ft/in")
    }
}
