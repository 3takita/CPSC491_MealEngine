import Foundation

protocol StorageServiceProtocol {
    func set(_ value: Any?, forKey key: String)
    func data(forKey key: String) -> Data?
    func dictionary(forKey key: String) -> [String: Any]?
}

final class StorageService: StorageServiceProtocol {

    func set(_ value: Any?, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    func data(forKey key: String) -> Data? {
        UserDefaults.standard.data(forKey: key)
    }

    func dictionary(forKey key: String) -> [String : Any]? {
        UserDefaults.standard.dictionary(forKey: key)
    }
}
