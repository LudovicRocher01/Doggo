//
//  Feedback.swift
//  Doggo
//

import AVFoundation
import UIKit

/// Sons et vibrations, avec les réglages de l'utilisateur.
@MainActor
final class Feedback {
    static let shared = Feedback()

    static let soundKey = "soundEnabled"
    static let hapticsKey = "hapticsEnabled"

    private var players: [GameMode: AVAudioPlayer] = [:]

    private init() {
        UserDefaults.standard.register(defaults: [Self.soundKey: true, Self.hapticsKey: true])
        // .ambient : respecte le mode silencieux et n'interrompt pas la musique.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        for mode in GameMode.allCases {
            if let url = Bundle.main.url(forResource: mode.soundName, withExtension: "mp3"),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[mode] = player
            }
        }
    }

    var soundEnabled: Bool { UserDefaults.standard.bool(forKey: Self.soundKey) }
    var hapticsEnabled: Bool { UserDefaults.standard.bool(forKey: Self.hapticsKey) }

    func point(_ mode: GameMode) {
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        guard soundEnabled, let player = players[mode] else { return }
        player.currentTime = 0
        player.play()
    }

    func tap() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func success() {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func warning() {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
