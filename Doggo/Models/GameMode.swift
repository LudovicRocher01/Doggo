//
//  GameMode.swift
//  Doggo
//

import SwiftUI

enum GameMode: String, CaseIterable, Identifiable, Codable {
    case doggo
    case gato

    var id: String { rawValue }

    /// Accepte les nouvelles valeurs ("doggo") et les anciennes de la v1 ("Doggo 🐶").
    init(storedValue: String) {
        self = storedValue.lowercased().hasPrefix("gat") ? .gato : .doggo
    }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self.init(storedValue: value)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var title: String { self == .doggo ? "Doggo" : "Gato" }
    var emoji: String { self == .doggo ? "🐶" : "🐱" }
    var shout: String { "\(title) !" }
    var animal: String { self == .doggo ? "chien" : "chat" }
    var animalPlural: String { self == .doggo ? "chiens" : "chats" }
    var soundName: String { self == .doggo ? "bark" : "meow" }
    var backgroundImage: String { self == .doggo ? "doggo_fond" : "gato_fond" }
    var burstEmojis: [String] {
        self == .doggo ? ["🐶", "🐕", "🦴", "🐾"] : ["🐱", "🐈", "🐟", "🐾"]
    }

    var accent: Color { self == .doggo ? Theme.doggo : Theme.gato }
    var accentSoft: Color { accent.opacity(0.16) }

    var gradient: LinearGradient {
        switch self {
        case .doggo:
            LinearGradient(colors: [Color(hex: 0xF6A84B), Color(hex: 0xE07A2B)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gato:
            LinearGradient(colors: [Color(hex: 0x9C83F0), Color(hex: 0x6C4FD0)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
