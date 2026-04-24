import Foundation

protocol NetworkServiceProtocol {
    func get(url: URL, ttl: TimeInterval) async throws -> Data
}

final class NetworkService: NetworkServiceProtocol {
    func get(url: URL, ttl: TimeInterval) async throws -> Data {

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let http = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }

    print("HTTP STATUS:", http.statusCode)

    guard 200...299 ~= http.statusCode else {

        switch http.statusCode {

        case 429:
            throw NSError(domain: "", code: 429,
                userInfo: [NSLocalizedDescriptionKey:
                "Too many requests"])

        case 500...599:
            throw NSError(domain: "", code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey:
                "Server error"])

        default:
            throw NSError(domain: "", code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey:
                "HTTP Error \(http.statusCode)"])
        }
    }

    return data
}
}
