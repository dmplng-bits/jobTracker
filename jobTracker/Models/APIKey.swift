import Foundation
import Combine

/// Represents a stored RapidAPI key with a label
struct APIKey: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String
    var key: String
    var isActive: Bool

    init(id: UUID = UUID(), label: String, key: String, isActive: Bool = false) {
        self.id = id
        self.label = label
        self.key = key
        self.isActive = isActive
    }
}

/// Manages multiple API keys with persistence
class APIKeyManager: ObservableObject {
    static let shared = APIKeyManager()

    @Published var keys: [APIKey] = []

    private let storageKey = "rapidAPIKeys"

    private init() {
        loadKeys()
    }

    /// The currently active API key
    var activeKey: APIKey? {
        keys.first { $0.isActive }
    }

    /// The active key string for API requests
    var activeKeyString: String? {
        activeKey?.key
    }

    // MARK: - Key Management

    func addKey(label: String, key: String) {
        let isFirst = keys.isEmpty
        let newKey = APIKey(label: label, key: key, isActive: isFirst)
        keys.append(newKey)
        saveKeys()
    }

    func updateKey(_ apiKey: APIKey) {
        if let index = keys.firstIndex(where: { $0.id == apiKey.id }) {
            keys[index] = apiKey
            saveKeys()
        }
    }

    func deleteKey(_ apiKey: APIKey) {
        let wasActive = apiKey.isActive
        keys.removeAll { $0.id == apiKey.id }

        // If deleted key was active, make first remaining key active
        if wasActive && !keys.isEmpty {
            keys[0].isActive = true
        }
        saveKeys()
    }

    func setActiveKey(_ apiKey: APIKey) {
        for index in keys.indices {
            keys[index].isActive = (keys[index].id == apiKey.id)
        }
        saveKeys()
    }

    // MARK: - Persistence

    private func loadKeys() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([APIKey].self, from: data) else {
            // Migrate from old single-key storage
            migrateFromLegacyStorage()
            return
        }
        keys = decoded
    }

    private func saveKeys() {
        if let data = try? JSONEncoder().encode(keys) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Migrates from the old single API key storage format
    private func migrateFromLegacyStorage() {
        if let legacyKey = UserDefaults.standard.string(forKey: "rapidAPIKey"), !legacyKey.isEmpty {
            keys = [APIKey(label: "Default", key: legacyKey, isActive: true)]
            saveKeys()
            // Clean up legacy storage
            UserDefaults.standard.removeObject(forKey: "rapidAPIKey")
        }
    }
}
