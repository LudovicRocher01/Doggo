//
//  GameManager.swift
//  Doggo
//
//  Created by Ludovic Rocher on 06/05/2025.
//

import Foundation

class GameManager: ObservableObject {
    @Published var sessions: [GameSession] = [] {
        didSet {
            saveSessions()
        }
    }

    init() {
        loadSessions()
    }

    func addSession(mode: GameMode, players: [Player]) {
        sessions.append(GameSession(mode: mode, players: players))
    }


    func removeSession(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "savedSessions")
        }
    }

    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "savedSessions"),
           let decoded = try? JSONDecoder().decode([GameSession].self, from: data) {
            sessions = decoded
        }
    }
}

