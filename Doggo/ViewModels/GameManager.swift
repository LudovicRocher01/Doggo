//
//  GameManager.swift
//  Doggo
//
//  Created by Ludovic Rocher on 06/05/2025.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class GameManager: ObservableObject {
    @Published var sessions: [OnlineSession] = []

    private var pollingTimer: Timer?

    init() {
        refreshSessionsFromFirestore()
        startPollingSessions()
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

    func refreshSessionsFromFirestore() {
        let firestore = Firestore.firestore()
        firestore.collection("sessions").getDocuments { [self] snapshot, error in
            guard let documents = snapshot?.documents else { return }

            var ownedSessions: [OnlineSession] = []

            for doc in documents {
                if let session = try? doc.data(as: OnlineSession.self) {
                    if session.creatorID == self.currentPlayerID ||
                        session.players.contains(where: { $0.id == self.currentPlayerID }) {
                        
                        var mutableSession = session
                        mutableSession.id = doc.documentID
                        ownedSessions.append(mutableSession)
                    }
                }
            }

            DispatchQueue.main.async {
                self.sessions = ownedSessions

                if !ownedSessions.isEmpty {
                    self.stopPollingSessions()
                }
            }
        }
    }

    func startPollingSessions() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.refreshSessionsFromFirestore()
        }
    }

    func stopPollingSessions() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
}
