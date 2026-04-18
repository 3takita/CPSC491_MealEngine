import XCTest
@testable import MealEngine

final class MealPlannerViewModelTests: XCTestCase {

    var mockNetwork: MockNetworkService!
    var mockStorage: MockStorageService!
    var vm: MealPlannerViewModel!

    override func setUp() {
        mockNetwork = MockNetworkService()
        mockStorage = MockStorageService()

        vm = MealPlannerViewModel(
            network: mockNetwork,
            storage: mockStorage
        )
    }

    // MARK: Network Success

    func testFetchFoodSuccess() async {

        let json = """
        {
          "products": [
            {
              "product_name": "Chicken Breast",
              "nutriments": {
                "energy-kcal_100g": 165,
                "proteins_100g": 31,
                "fat_100g": 3.6,
                "carbohydrates_100g": 0
              }
            }
          ]
        }
        """

        mockNetwork.mockData = json.data(using: .utf8)

        vm.query = "chicken"
        vm.calorieLimit = "500"

        vm.fetchFood()

        try? await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertEqual(vm.chosenFoods.count, 1)
        XCTAssertEqual(vm.chosenFoods.first?.name, "Chicken Breast")
    }

    // MARK: Network Failure

    func testFetchFoodFailureReturnsEmpty() async {

        mockNetwork.shouldThrow = true

        vm.query = "chicken"
        vm.calorieLimit = "500"

        vm.fetchFood()

        try? await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertTrue(vm.chosenFoods.isEmpty)
    }

    // MARK: Persistence

    func testSaveGoalsUsesStorage() {

        vm.goals.calories = 3000
        vm.saveGoals()

        XCTAssertNotNil(mockStorage.store["UserGoals"])
    }

    // MARK: Meal Save

    func testSaveMealStoresHistory() {

        vm.chosenFoods = [
            Food(name: "Rice", calories: 200, protein: 4, fat: 1, carbs: 45)
        ]

        vm.saveMeal()

        XCTAssertEqual(vm.mealHistory.count, 1)
    }
}
