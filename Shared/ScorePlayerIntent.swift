//
//  ScorePlayerIntent.swift
//  Doggo (partagé app + extension DoggoWidgets)
//

import AppIntents
import Foundation

/// Point marqué depuis un bouton de la Live Activity.
/// Compilé dans les deux cibles pour que l'extension puisse créer le bouton ;
/// `perform()` s'exécute toujours dans l'app, qui enregistre `ScoreIntentBridge.handler` au lancement.
struct ScorePlayerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Marquer un point"
    static var description = IntentDescription("Donne un point à un joueur dans une partie Doggo.")
    static var isDiscoverable = false

    @Parameter(title: "Partie")
    var sessionID: String

    @Parameter(title: "Joueur")
    var playerID: String

    init() {}

    init(sessionID: String, playerID: String) {
        self.sessionID = sessionID
        self.playerID = playerID
    }

    func perform() async throws -> some IntentResult {
        await ScoreIntentBridge.handler?(sessionID, playerID)
        return .result()
    }
}

enum ScoreIntentBridge {
    /// Défini par l'app ; reste nil dans l'extension.
    nonisolated(unsafe) static var handler: ((_ sessionID: String, _ playerID: String) async -> Void)?
}
