//
//  LiveActivityManager.swift
//  Doggo
//

import ActivityKit
import Foundation

@MainActor
enum LiveActivityManager {
    static var isAvailable: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    private static func activity(for sessionID: String) -> Activity<DoggoActivityAttributes>? {
        Activity<DoggoActivityAttributes>.activities.first { $0.attributes.sessionID == sessionID }
    }

    static func isRunning(_ sessionID: String) -> Bool {
        activity(for: sessionID).map { $0.activityState == .active } ?? false
    }

    static func state(for session: Session, lastScorerID: String? = nil) -> DoggoActivityAttributes.ContentState {
        DoggoActivityAttributes.ContentState(
            players: session.standings.map {
                .init(id: $0.id, name: $0.member.name, emoji: $0.member.emoji, score: $0.score)
            },
            lastScorerID: lastScorerID,
            targetScore: session.targetScore,
            isFinished: session.isFinished
        )
    }

    static func start(_ session: Session, myID: String) {
        guard isAvailable, !isRunning(session.sessionID) else { return }
        let attributes = DoggoActivityAttributes(
            sessionID: session.sessionID,
            sessionName: session.displayName,
            mode: session.mode.rawValue,
            myID: myID
        )
        do {
            _ = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state(for: session), staleDate: Date().addingTimeInterval(8 * 3600)),
                pushType: nil
            )
        } catch {
            print("❌ Live Activity : \(error.localizedDescription)")
        }
    }

    static func update(_ session: Session, lastScorerID: String? = nil) {
        guard let activity = activity(for: session.sessionID) else { return }
        let newState = state(for: session, lastScorerID: lastScorerID ?? activity.content.state.lastScorerID)
        guard newState != activity.content.state else { return }
        Task {
            if session.isFinished {
                await activity.end(ActivityContent(state: newState, staleDate: nil), dismissalPolicy: .after(Date().addingTimeInterval(1800)))
            } else {
                await activity.update(ActivityContent(state: newState, staleDate: Date().addingTimeInterval(8 * 3600)))
            }
        }
    }

    static func end(_ sessionID: String) {
        guard let activity = activity(for: sessionID) else { return }
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    /// Mise à jour optimiste immédiate quand on marque depuis l'écran verrouillé.
    static func applyLocalPoint(sessionID: String, playerID: String) {
        guard let activity = activity(for: sessionID) else { return }
        var state = activity.content.state
        guard let index = state.players.firstIndex(where: { $0.id == playerID }) else { return }
        state.players[index].score += 1
        state.players.sort { $0.score > $1.score }
        state.lastScorerID = playerID
        Task { await activity.update(ActivityContent(state: state, staleDate: Date().addingTimeInterval(8 * 3600))) }
    }
}
