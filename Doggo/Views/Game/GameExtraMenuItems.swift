//
//  GameExtraMenuItems.swift
//  Doggo
//

import SwiftUI

/// Entrées du menu de partie liées à Siri et à la Live Activity.
struct GameExtraMenuItems: View {
    let session: Session
    @Environment(AppModel.self) private var app
    @State private var refresh = 0

    var body: some View {
        let isActive = app.activeSessionID == session.sessionID
        Button {
            app.activeSessionID = session.sessionID
            Feedback.shared.success()
        } label: {
            Label(isActive ? "Partie utilisée par Siri" : "Utiliser cette partie avec Siri",
                  systemImage: isActive ? "checkmark.circle.fill" : "mic.fill")
        }
        .disabled(isActive)

        if LiveActivityManager.isAvailable {
            if LiveActivityManager.isRunning(session.sessionID) {
                Button {
                    LiveActivityManager.end(session.sessionID)
                    refresh += 1
                } label: {
                    Label("Retirer de l'écran verrouillé", systemImage: "lock.slash")
                }
            } else {
                Button {
                    LiveActivityManager.start(session, myID: app.playerID)
                    app.activeSessionID = session.sessionID
                    Feedback.shared.success()
                    refresh += 1
                } label: {
                    Label("Partir en balade (écran verrouillé)", systemImage: "figure.walk")
                }
            }
        }
    }
}
