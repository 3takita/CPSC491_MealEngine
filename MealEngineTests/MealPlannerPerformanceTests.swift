func testKnapsackPerformance() {

    let foods = (0..<1000).map {
        Food(
            name: "Food \($0)",
            calories: Double(Int.random(in: 50...500)),
            protein: Double.random(in: 1...50),
            fat: 5,
            carbs: 10
        )
    }

    measure {
        _ = vm.optimizeFoodsForTesting(foods, calorieLimit: 2200)
    }
}
