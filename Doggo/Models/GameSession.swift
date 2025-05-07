//
//  GameSession.swift
//  Doggo
//
//  Created by Ludovic Rocher on 06/05/2025.
//

import Foundation

enum GameMode: String, Codable, CaseIterable {
    case doggo = "Doggo 🐶"
    case gato = "Gato 🐱"
}

struct GameSession: Identifiable, Codable {
    let id: UUID
    var mode: GameMode
    var players: [Player]
    
    init(id: UUID = UUID(), mode: GameMode, players: [Player] = []) {
        self.id = id
        self.mode = mode
        self.players = players
    }
}
