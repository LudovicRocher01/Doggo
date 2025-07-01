//
//  GameManager.swift
//  Doggo
//
//  Created by Ludovic Rocher on 06/05/2025.
//

import Foundation
import SwiftUI

class GameManager: ObservableObject {
    @Published var sessions: [OnlineSession] = []

    init() {
        loadSessionsFromFirestore()
    }

    var currentPlayerID: String {
        if let existingID = UserDefaults.standard.string(forKey: "currentPlayerID") {
            return existingID
        } else {
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: "currentPlayerID")
            return newID
        }
    }

    func addSession(mode: GameMode, players: [Player]) {
        sessions.append(OnlineSession(mode: mode, players: players, creatorID: currentPlayerID))
    }

    func removeSession(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
    }

    func updateSession(_ updatedSession: OnlineSession) {
        if let index = sessions.firstIndex(where: { $0.id == updatedSession.id }) {
            sessions[index] = updatedSession
        }
    }

    func loadSessionsFromFirestore() {
        let service = FirestoreGameService()
        service.fetchSessions(for: currentPlayerID) { [weak self] sessions in
            DispatchQueue.main.async {
                self?.sessions = sessions
            }
        }
    }
}
