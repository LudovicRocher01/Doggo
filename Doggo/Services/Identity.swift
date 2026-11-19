//
//  Identity.swift
//  Doggo
//

import Foundation
import Security

/// Identifiant anonyme et stable du joueur.
/// Stocké dans le Trousseau pour survivre à une réinstallation ; reprend l'ID de la v1 (UserDefaults).
enum Identity {
    private static let service = "com.ludovicrocher.Doggo"
    private static let account = "playerID"
    private static let legacyDefaultsKey = "currentPlayerID"

    static let playerID: String = {
        if let stored = readKeychain() { return stored }
        let id = UserDefaults.standard.string(forKey: legacyDefaultsKey) ?? UUID().uuidString
        writeKeychain(id)
        UserDefaults.standard.set(id, forKey: legacyDefaultsKey)
        return id
    }()

    private static func readKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8), !value.isEmpty else { return nil }
        return value
    }

    private static func writeKeychain(_ value: String) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(base as CFDictionary)
        var attributes = base
        attributes[kSecValueData as String] = Data(value.utf8)
        // Lisible écran verrouillé (après le premier déverrouillage) pour Siri et la Live Activity.
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }
}
