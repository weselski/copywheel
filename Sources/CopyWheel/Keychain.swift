import Foundation
import Security

/// Minimaler Wrapper um den macOS-Schlüsselbund für geheime Snippets.
/// Ein Eintrag pro Snippet, Account = Snippet-UUID.
enum Keychain {
    private static let service = "CopyWheel"

    private static func baseQuery(for account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    static func set(_ value: String, for account: String) {
        SecItemDelete(baseQuery(for: account) as CFDictionary)
        var attributes = baseQuery(for: account)
        attributes[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func get(_ account: String) -> String? {
        var query = baseQuery(for: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ account: String) {
        SecItemDelete(baseQuery(for: account) as CFDictionary)
    }
}
