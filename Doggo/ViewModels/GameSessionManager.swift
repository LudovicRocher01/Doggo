//
//  GameSessionManager.swift
//  Doggo
//
//  Created by Ludovic Rocher on 07/05/2025.
//

import Foundation
import AVFoundation
import FirebaseFirestore

class GameSessionManager: ObservableObject {
    @Published var session: OnlineSession
    weak var globalManager: GameManager?
    private var player: AVAudioPlayer?
    private let firestoreService = FirestoreGameService()
    private var listener: ListenerRegistration?

    init(session: OnlineSession, manager: GameManager) {
        self.session = session
        self.globalManager = manager
        self.startListeningSessionUpdates()
    }

    deinit {
        listener?.remove()
    }

    private func startListeningSessionUpdates() {
        guard let id = session.id else { return }

        listener = Firestore.firestore()
            .collection("sessions")
            .document(id)
            .addSnapshotListener { [weak self] docSnapshot, error in
                guard let self = self, let doc = docSnapshot, doc.exists else { return }

                do {
                    let updatedSession = try doc.data(as: OnlineSession.self)
                    DispatchQueue.main.async {
                        self.session = updatedSession
                    }
                } catch {
                    print("Erreur de décodage de session en temps réel : \(error.localizedDescription)")
                }
            }
    }

    private func save() {
        globalManager?.updateSession(session)
        firestoreService.updateSession(session)
    }

    func incrementScore(for player: Player) {
        if let index = session.players.firstIndex(where: { $0.id == player.id }) {
            session.players[index].score += 1
            playSound(for: session.mode)
            save()
        }
    }

    func decrementScore(for player: Player) {
        if let index = session.players.firstIndex(where: { $0.id == player.id }),
           session.players[index].score > 0 {
            session.players[index].score -= 1
            save()
        }
    }

    var topScorerText: String {
        let scores = session.players.map { $0.score }
        guard let maxScore = scores.max(), maxScore > 0 else {
            return "Aucun point marqué"
        }

        let topPlayers = session.players.filter { $0.score == maxScore }

        if topPlayers.count == 1 {
            return "En tête : \(topPlayers.first!.name)"
        } else {
            return "Égalité"
        }
    }

    private func playSound(for mode: GameMode) {
        let soundName = mode == .doggo ? "bark" : "meow"
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("Erreur audio : \(error.localizedDescription)")
        }
    }

    func acceptPlayer(_ player: Player) {
        guard let index = session.pendingRequests.firstIndex(where: { $0.id == player.id }) else { return }
        session.pendingRequests.remove(at: index)
        if !session.players.contains(where: { $0.id == player.id }) {
            session.players.append(player)
        }
        save()
    }



    func rejectPlayer(_ player: Player) {
        session.pendingRequests.removeAll { $0.id == player.id }
        session.players.removeAll { $0.id == player.id }
        save()
    }

    func leaveSession(completion: @escaping () -> Void) {
        let currentID = globalManager?.currentPlayerID ?? ""
        let isCreator = session.creatorID == currentID

        firestoreService.removePlayer(from: session, playerID: currentID) { updatedSession in
            DispatchQueue.main.async {
                if isCreator {
                    self.globalManager?.sessions.removeAll { $0.id == self.session.id }
                    completion()
                    return
                }

                if let updated = updatedSession {
                    self.session = updated
                    self.globalManager?.updateSession(updated)
                }
                completion()
            }
        }
    }

}

