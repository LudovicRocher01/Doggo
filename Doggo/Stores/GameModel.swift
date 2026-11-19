//
//  GameModel.swift
//  Doggo
//

import Foundation
import Observation
import FirebaseFirestore

/// État d'une partie ouverte : synchro temps réel, points, annulation, fin de partie.
@Observable
@MainActor
final class GameModel {
    struct Banner: Identifiable, Equatable {
        let id = UUID()
        let emoji: String
        let text: String
    }

    let sessionID: String
    private(set) var session: Session?
    private(set) var events: [ScoreEvent] = []
    private(set) var wasDeleted = false
    var banner: Banner?
    var errorMessage: String?
    /// Compteur par joueur, incrémenté à chaque point : déclenche les animations.
    private(set) var bursts: [String: Int] = [:]

    @ObservationIgnored private var listeners: [ListenerRegistration] = []
    @ObservationIgnored private var knownEventIDs: Set<String>?
    @ObservationIgnored private var bannerTask: Task<Void, Never>?
    @ObservationIgnored private let app = AppModel.shared
    @ObservationIgnored private var repository: SessionRepository { app.repository }

    init(sessionID: String) {
        self.sessionID = sessionID
        self.session = AppModel.shared.session(sessionID)
    }

    var me: String { app.playerID }
    var isCreator: Bool { session?.creatorID == me }
    var mode: GameMode { session?.mode ?? .doggo }

    func member(_ id: String) -> Member? {
        session?.members[id] ?? session?.requests[id]
    }

    func name(_ id: String) -> String { member(id)?.name ?? "Quelqu'un" }

    // MARK: - Synchro

    func start() {
        guard listeners.isEmpty else { return }
        #if DEBUG
        if DemoData.isDemo(sessionID) {
            apply(DemoData.events(for: session ?? DemoData.sessions[0]))
            return
        }
        #endif
        listeners.append(repository.listenToSession(sessionID) { [weak self] session in
            MainActor.assumeIsolated { self?.apply(session) }
        })
        listeners.append(repository.listenToEvents(sessionID) { [weak self] events in
            MainActor.assumeIsolated { self?.apply(events) }
        })
    }

    func stop() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        knownEventIDs = nil
    }

    private func apply(_ session: Session?) {
        guard let session else {
            wasDeleted = true
            return
        }
        self.session = session
        LiveActivityManager.update(session)
        checkTarget(session)
    }

    private func apply(_ events: [ScoreEvent]) {
        defer {
            self.events = events
            knownEventIDs = Set(events.compactMap(\.id))
        }
        // Premier chargement : pas de bannière pour l'historique existant.
        guard let known = knownEventIDs else { return }
        let fresh = events.filter { event in
            guard let id = event.id else { return false }
            return !known.contains(id) && event.byID != me && !event.undone
                && event.createdAt > Date().addingTimeInterval(-120)
        }
        guard let latest = fresh.first else { return }
        let scorer = member(latest.playerID)
        let text = latest.byID == latest.playerID
            ? "\(name(latest.playerID)) a crié \(mode.shout)"
            : "\(name(latest.byID)) a donné un point à \(name(latest.playerID))"
        show(Banner(emoji: scorer?.emoji ?? mode.emoji, text: text))
        bursts[latest.playerID, default: 0] += 1
        Feedback.shared.tap()
    }

    private func show(_ banner: Banner) {
        self.banner = banner
        bannerTask?.cancel()
        bannerTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            self?.banner = nil
        }
    }

    // MARK: - Points

    func score(_ playerID: String) {
        guard let session, !session.isFinished else { return }
        #if DEBUG
        if DemoData.isDemo(sessionID) {
            self.session?.scores[playerID, default: 0] += 1
            var event = ScoreEvent(playerID: playerID, byID: me, createdAt: Date())
            event.id = UUID().uuidString
            events.insert(event, at: 0)
            bursts[playerID, default: 0] += 1
            Feedback.shared.point(session.mode)
            return
        }
        #endif
        repository.score(sessionID: sessionID, playerID: playerID, byID: me)
        bursts[playerID, default: 0] += 1
        Feedback.shared.point(session.mode)
        app.activeSessionID = sessionID
        LiveActivityManager.applyLocalPoint(sessionID: sessionID, playerID: playerID)
    }

    func lastEvent(for playerID: String) -> ScoreEvent? {
        events.first { $0.playerID == playerID && !$0.undone && $0.id != nil }
    }

    func undo(_ event: ScoreEvent) async {
        guard let id = event.id else { return }
        do {
            try await repository.undo(sessionID: sessionID, eventID: id, byID: me)
            Feedback.shared.warning()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func undoLast(for playerID: String) async {
        if let event = lastEvent(for: playerID) { await undo(event) }
    }

    // MARK: - Demandes

    func accept(_ playerID: String) async {
        guard let member = session?.requests[playerID] else { return }
        await perform { try await self.repository.accept(sessionID: self.sessionID, playerID: playerID, member: member) }
        Feedback.shared.success()
    }

    func reject(_ playerID: String) async {
        await perform { try await self.repository.reject(sessionID: self.sessionID, playerID: playerID) }
    }

    // MARK: - Fin de partie

    private func checkTarget(_ session: Session) {
        guard session.status == .active, let target = session.targetScore,
              let leader = session.standings.first, leader.score >= target else { return }
        Task { try? await repository.finish(sessionID: sessionID, winnerID: leader.id) }
    }

    func finishNow() async {
        guard let session else { return }
        await perform { try await self.repository.finish(sessionID: self.sessionID, winnerID: session.soleLeaderID) }
    }

    /// Nouvelle partie avec les mêmes joueurs et le même objectif. Renvoie l'ID de la nouvelle partie.
    func rematch() async -> String? {
        guard let session else { return nil }
        do {
            let members = session.members.mapValues { Member(name: $0.name, emoji: $0.emoji, joinedAt: Date()) }
            let new = try await repository.createSession(
                mode: session.mode, name: session.name, targetScore: session.targetScore, creatorID: me, members: members
            )
            app.activeSessionID = new.sessionID
            return new.sessionID
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Quitter

    func leaveOrDelete() async -> Bool {
        do {
            if isCreator {
                try await repository.delete(sessionID: sessionID)
            } else {
                try await repository.leave(sessionID: sessionID, playerID: me)
            }
            if app.activeSessionID == sessionID { app.activeSessionID = nil }
            LiveActivityManager.end(sessionID)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func perform(_ action: @escaping () async throws -> Void) async {
        do { try await action() } catch { errorMessage = error.localizedDescription }
    }
}
