//
//  ScoreMyPointIntent.swift
//  Doggo
//
//  « Dis Siri, point Doggo » / bouton Action : un point pour moi dans la partie active,
//  sans ouvrir l'app.
//

import AppIntents
import Foundation

struct ScoreMyPointIntent: AppIntent {
    static var title: LocalizedStringResource = "Marquer mon point"
    static var description = IntentDescription("Ajoute un point pour toi dans ta partie Doggo active.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        FirebaseBootstrap.configureIfNeeded()
        let me = Identity.playerID
        guard let sessionID = UserDefaults.standard.string(forKey: "activeSessionID"),
              let session = try? await SessionRepository.shared.fetchSession(sessionID),
              session.memberIDs.contains(me) else {
            return .result(dialog: "Ouvre d'abord une partie dans Doggo, puis réessaie.")
        }
        guard !session.isFinished else {
            return .result(dialog: "La partie « \(session.displayName) » est terminée.")
        }
        await ScoreActions.score(sessionID: sessionID, playerID: me)
        let total = session.score(of: me) + 1
        return .result(dialog: "\(session.mode.shout) Point pour toi : \(total) dans « \(session.displayName) ».")
    }
}

struct DoggoShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ScoreMyPointIntent(),
            phrases: [
                "Point \(.applicationName)",
                "\(.applicationName) point",
                "Marquer un point dans \(.applicationName)",
                "J'ai vu un chien sur \(.applicationName)",
                "J'ai vu un chat sur \(.applicationName)",
            ],
            shortTitle: "Doggo !",
            systemImageName: "pawprint.fill"
        )
    }
}

/// Marque un point depuis un intent (Siri, Live Activity) et attend la confirmation du serveur
/// (au plus quelques secondes : l'app peut être suspendue juste après).
@MainActor
enum ScoreActions {
    static func registerBridge() {
        ScoreIntentBridge.handler = { sessionID, playerID in
            await ScoreActions.score(sessionID: sessionID, playerID: playerID)
        }
    }

    static func score(sessionID: String, playerID: String) async {
        FirebaseBootstrap.configureIfNeeded()
        await AuthService.ensureSignedIn()
        LiveActivityManager.applyLocalPoint(sessionID: sessionID, playerID: playerID)
        await SessionRepository.shared.scoreAndWait(sessionID: sessionID, playerID: playerID, byID: Identity.playerID)
        if let session = try? await SessionRepository.shared.fetchSession(sessionID) {
            LiveActivityManager.update(session, lastScorerID: playerID)
        }
    }
}
