import Foundation

protocol NetworkServiceProtocol {
    func get(url: URL, ttl: TimeInterval) async throws -> Data
}

final class NetworkService: NetworkServiceProtocol {
    func get(url: URL, ttl: TimeInterval) async throws -> Data {
        try await APIClient.shared.get(url: url, ttl: ttl)
    }
}
