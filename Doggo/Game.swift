//
//  Game.swift
//  Doggo
//
//  Created by Ludovic Rocher on 02/05/2025.
//

import Foundation

class Game: ObservableObject {
    @Published var players: [Player] = [] {
        didSet {
            savePlayers()
        }
    }
    
    init() {
        loadPlayers()
    }
    
    func addPlayer(name: String) {
        let player = Player(name: name)
        players.append(player)
    }
    
    func incrementScore(for playerID: UUID) {
        if let index = players.firstIndex(where: { $0.id == playerID }) {     players[index].score += 1
        }
    }
    
    func decrementScore(for playerID: UUID) {
        if let index = players.firstIndex(where: { $0.id == playerID}) {
            players[index].score -= 1
        }
    }
    
    private func savePlayers() {
        if let encoded = try? JSONEncoder().encode(players) {
            UserDefaults.standard.set(encoded, forKey: "savedPlayers")
        }
    }

    private func loadPlayers() {
        if let savedPlayers = UserDefaults.standard.data(forKey: "savedPlayers"),
           let decodedPlayers = try? JSONDecoder().decode([Player].self, from: savedPlayers) {
            players = decodedPlayers
        }
    }
}
