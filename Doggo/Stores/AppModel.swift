//
//  AppModel.swift
//  Doggo
//

import Foundation
import Observation
import FirebaseFirestore

/// État global : profil, liste des parties en temps réel, partie active, liens profonds.
@Observable
@MainActor
final class AppModel {
    static let shared = AppModel()

    #if DEBUG
    let playerID = DemoData.isEnabled ? DemoData.me : Identity.playerID
    #else
    let playerID = Identity.playerID
    #endif
    let repository = SessionRepository.shared

    var profile: PlayerProfile? = {
        #if DEBUG
        if DemoData.isEnabled { return DemoData.profile }
        #endif
        return PlayerProfile.load()
    }()
    private(set) var sessions: [Session] = []
    private(set) var outgoingRequests: [Session] = []
    private(set) var isLoaded = false
    private(set) var hasStarted = false

    /// Code reçu par lien profond ou QR code, en attente d'affichage de l'écran « Rejoindre ».
    var pendingJoinCode: String?
    /// Pile de navigation (IDs de parties).
    var path: [String] = []

    /// Partie utilisée par Siri, le bouton Action et la Live Activity.
    var activeSessionID: String? = UserDefaults.standard.string(forKey: "activeSessionID") {
        didSet { UserDefaults.standard.set(activeSessionID, forKey: "activeSessionID") }
    }

    @ObservationIgnored private var listeners: [ListenerRegistration] = []

    private init() {}

    // MARK: - Démarrage

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        #if DEBUG
        if DemoData.isEnabled {
            profile = DemoData.profile
            sessions = DemoData.sessions
            isLoaded = true
            if let id = UserDefaults.standard.string(forKey: "DoggoDemoOpen") { path = [id] }
            if DemoDirector.isEnabled { Task { await DemoDirector.run(app: self) } }
            return
        }
        #endif
        await AuthService.ensureSignedIn()
        #if DEBUG
        if SelfTest.isEnabled { await SelfTest.run() }
        #endif
        await MigrationService.migrateIfNeeded(playerID: playerID)
        listeners.append(repository.listenToSessions(memberID: playerID) { [weak self] sessions in
            MainActor.assumeIsolated {
                self?.sessions = sessions.sorted(by: Self.byRecentActivity)
                self?.isLoaded = true
                sessions.forEach { LiveActivityManager.update($0) }
            }
        })
        listeners.append(repository.listenToRequests(playerID: playerID) { [weak self] sessions in
            MainActor.assumeIsolated { self?.outgoingRequests = sessions }
        })
        // Si l'écoute ne répond pas (hors ligne au premier lancement), on n'affiche pas un chargement infini.
        try? await Task.sleep(for: .seconds(4))
        isLoaded = true
    }

    private static func byRecentActivity(_ lhs: Session, _ rhs: Session) -> Bool {
        (lhs.lastActivityAt ?? lhs.createdAt ?? .distantPast) > (rhs.lastActivityAt ?? rhs.createdAt ?? .distantPast)
    }

    // MARK: - Accès

    var activeSessions: [Session] { sessions.filter { !$0.isFinished } }
    var finishedSessions: [Session] { sessions.filter(\.isFinished) }

    func session(_ id: String) -> Session? { sessions.first { $0.sessionID == id } }

    var activeSession: Session? {
        if let id = activeSessionID, let session = session(id), !session.isFinished { return session }
        return activeSessions.first
    }

    /// Nom déjà utilisé dans une partie migrée de la v1, pour pré-remplir l'onboarding.
    var suggestedName: String? {
        sessions.compactMap { $0.members[playerID]?.name }.first
    }

    // MARK: - Profil

    func saveProfile(_ profile: PlayerProfile) {
        let trimmed = PlayerProfile(name: profile.name.trimmingCharacters(in: .whitespacesAndNewlines), emoji: profile.emoji)
        self.profile = trimmed
        trimmed.save()
        repository.updateMember(playerID: playerID, member: trimmed.member, in: sessions.map(\.sessionID))
    }

    /// Totaux de points du joueur, par mode, sur toutes ses parties.
    func totalPoints(for mode: GameMode) -> Int {
        sessions.filter { $0.mode == mode }.reduce(0) { $0 + $1.score(of: playerID) }
    }

    var wins: Int { sessions.filter { $0.isFinished && $0.winnerID == playerID }.count }

    // MARK: - Liens profonds

    func handle(url: URL) {
        guard url.scheme == "doggo" else { return }
        if url.host == "join" || url.host == nil {
            let code = CodeGenerator.normalize(url.lastPathComponent)
            if !code.isEmpty { pendingJoinCode = code }
        } else if url.host == "session" {
            let id = url.lastPathComponent
            if !id.isEmpty { path = [id] }
        } else if let host = url.host {
            // doggo://WOOF42
            pendingJoinCode = CodeGenerator.normalize(host)
        }
    }

    func endLiveActivity(_ sessionID: String) {
        LiveActivityManager.end(sessionID)
    }

    func open(_ sessionID: String) {
        path = [sessionID]
    }
}
