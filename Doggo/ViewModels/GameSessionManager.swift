//
//  GameSessionManager.swift
//  Doggo
//
//  Created by Ludovic Rocher on 07/05/2025.
//

import Foundation
import AVFoundation

class GameSessionManager: ObservableObject {
    @Published var session: OnlineSession
    private weak var globalManager: GameManager?
    private var player: AVAudioPlayer?

    init(session: OnlineSession, manager: GameManager) {
        self.session = session
        self.globalManager = manager
    }
    
    private func save() {
        globalManager?.updateSession(session)
    }

    func addPlayer(name: String) {
        session.players.append(Player(name: name))
        save()
    }

    func removePlayers(at offsets: IndexSet) {
        session.players.remove(atOffsets: offsets)
        save()
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
        if let index = session.pendingRequests.firstIndex(where: { $0.id == player.id }) {
            session.pendingRequests.remove(at: index)
            session.players.append(player)
            save()
        }
    }

    func rejectPlayer(_ player: Player) {
        session.pendingRequests.removeAll { $0.id == player.id }
        save()
    }

}

