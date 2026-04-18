import Foundation
@testable import MealEngine

final class MockNetworkService: NetworkServiceProtocol {

    var mockData: Data?
    var shouldThrow = false

    func get(url: URL, ttl: TimeInterval) async throws -> Data {

        if shouldThrow {
            throw URLError(.badServerResponse)
        }

        return mockData ?? Data()
    }
}
