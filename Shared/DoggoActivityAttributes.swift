//
//  DoggoActivityAttributes.swift
//  Doggo (partagé app + extension DoggoWidgets)
//

import ActivityKit
import Foundation

/// Live Activity « Balade » : scores sur l'écran verrouillé et la Dynamic Island.
struct DoggoActivityAttributes: ActivityAttributes {
    struct Player: Codable, Hashable, Identifiable {
        var id: String
        var name: String
        var emoji: String
        var score: Int
    }

    struct ContentState: Codable, Hashable {
        /// Triés par score décroissant.
        var players: [Player]
        var lastScorerID: String?
        var targetScore: Int?
        var isFinished: Bool
    }

    var sessionID: String
    var sessionName: String
    /// "doggo" ou "gato".
    var mode: String
    /// Joueur de l'appareil (mis en avant).
    var myID: String

    var isGato: Bool { mode == "gato" }
    var emoji: String { isGato ? "🐱" : "🐶" }
    var shout: String { isGato ? "Gato !" : "Doggo !" }
}
