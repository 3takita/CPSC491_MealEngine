// Purpose: Does instant repeat searches and reopen app later by using disk cache

import Foundation

final class APIClient {

    static let shared = APIClient()

    private let memoryCache = NSCache<NSString, NSData>()
    private let fileManager = FileManager.default
    private let cacheFolder: URL

    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheFolder = caches.appendingPathComponent("MealEngineAPICache", isDirectory: true)

        if !fileManager.fileExists(atPath: cacheFolder.path) {
            try? fileManager.createDirectory(
                at: cacheFolder,
                withIntermediateDirectories: true
            )
        }

        memoryCache.countLimit = 100
    }

    // MARK: - Public GET

    func get(url: URL, ttl: TimeInterval = 300) async throws -> Data {

        let key = cacheKey(for: url)

        // 1. Memory Cache
        if let cached = memoryCache.object(forKey: key as NSString) {
            return Data(referencing: cached)
        }

        // 2. Disk Cache
        if let diskData = try loadDiskCache(for: key, ttl: ttl) {
            memoryCache.setObject(diskData as NSData, forKey: key as NSString)
            return diskData
        }

        // 3. Network Fetch
        let request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 30
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              200...299 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        // Save caches
        memoryCache.setObject(data as NSData, forKey: key as NSString)
        try saveDiskCache(data: data, for: key)

        return data
    }

    // MARK: - Cache Helpers

    private func cacheKey(for url: URL) -> String {
        url.absoluteString
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
            .replacingOccurrences(of: "=", with: "_")
    }

    private func fileURL(for key: String) -> URL {
        cacheFolder.appendingPathComponent(key)
    }

    private func saveDiskCache(data: Data, for key: String) throws {
        let url = fileURL(for: key)
        try data.write(to: url, options: .atomic)
    }

    private func loadDiskCache(for key: String, ttl: TimeInterval) throws -> Data? {

        let url = fileURL(for: key)

        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        let attributes = try fileManager.attributesOfItem(atPath: url.path)

        guard let modified = attributes[.modificationDate] as? Date else {
            return nil
        }

        let age = Date().timeIntervalSince(modified)

        guard age <= ttl else {
            try? fileManager.removeItem(at: url)
            return nil
        }

        return try Data(contentsOf: url)
    }

    // MARK: - Optional Manual Cleanup

    func clearCache() {
        memoryCache.removeAllObjects()

        try? fileManager.removeItem(at: cacheFolder)

        try? fileManager.createDirectory(
            at: cacheFolder,
            withIntermediateDirectories: true
        )
    }
}
