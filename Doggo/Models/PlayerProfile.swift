//
//  PlayerProfile.swift
//  Doggo
//

import Foundation

/// Le profil local du joueur : saisi une seule fois, réutilisé dans toutes les parties.
struct PlayerProfile: Codable, Equatable {
    var name: String
    var emoji: String

    static let avatarChoices = [
        "🐶", "🐱", "🦊", "🐼", "🐻", "🐨", "🐯", "🦁",
        "🐸", "🐵", "🐰", "🐹", "🐷", "🐮", "🐧", "🦉",
        "🦄", "🐙", "🦖", "🐢", "🦔", "🦦", "🐝", "👽",
    ]

    var member: Member { Member(name: name, emoji: emoji, joinedAt: Date()) }

    private static let storageKey = "playerProfile"

    static func load() -> PlayerProfile? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(PlayerProfile.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
