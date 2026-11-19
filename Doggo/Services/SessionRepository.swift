//
//  SessionRepository.swift
//  Doggo
//
//  Toute la couche Firestore. Les points sont marqués avec FieldValue.increment :
//  deux amis qui tapent en même temps ne perdent plus jamais de point, et cela fonctionne hors ligne.
//

import Foundation
import FirebaseFirestore

enum RepositoryError: LocalizedError {
    case notFound
    case alreadyMember
    case alreadyRequested
    case codeUnavailable
    case alreadyUndone

    var errorDescription: String? {
        switch self {
        case .notFound: "Partie introuvable. Vérifie le code."
        case .alreadyMember: "Tu fais déjà partie de cette partie."
        case .alreadyRequested: "Demande déjà envoyée, en attente de l'hôte."
        case .codeUnavailable: "Impossible de créer la partie. Vérifie ta connexion."
        case .alreadyUndone: "Ce point a déjà été annulé."
        }
    }
}

final class SessionRepository {
    static let shared = SessionRepository()

    private let makeFirestore: () -> Firestore
    /// Paresseux : Firebase doit être configuré avant le premier accès.
    private lazy var db = makeFirestore()

    init(firestore: @escaping @autoclosure () -> Firestore = Firestore.firestore()) {
        makeFirestore = firestore
    }
    private var sessions: CollectionReference { db.collection("sessions") }

    private func events(_ sessionID: String) -> CollectionReference {
        sessions.document(sessionID).collection("events")
    }

    private func path(_ parts: String...) -> FieldPath { FieldPath(parts) }

    private func encode(_ member: Member) -> [String: Any] {
        (try? Firestore.Encoder().encode(member)) ?? ["name": member.name, "emoji": member.emoji]
    }

    // MARK: - Écoute temps réel

    func listenToSessions(memberID: String, onChange: @escaping ([Session]) -> Void) -> ListenerRegistration {
        sessions.whereField("memberIDs", arrayContains: memberID).addSnapshotListener { snapshot, error in
            if let error { print("❌ Écoute des parties : \(error.localizedDescription)") }
            guard let docs = snapshot?.documents else { return }
            onChange(docs.compactMap { try? $0.data(as: Session.self) })
        }
    }

    func listenToRequests(playerID: String, onChange: @escaping ([Session]) -> Void) -> ListenerRegistration {
        sessions.whereField("requestIDs", arrayContains: playerID).addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            onChange(docs.compactMap { try? $0.data(as: Session.self) })
        }
    }

    func listenToSession(_ sessionID: String, onChange: @escaping (Session?) -> Void) -> ListenerRegistration {
        sessions.document(sessionID).addSnapshotListener { snapshot, _ in
            guard let snapshot else { return }
            onChange(snapshot.exists ? try? snapshot.data(as: Session.self) : nil)
        }
    }

    func listenToEvents(_ sessionID: String, limit: Int = 200, onChange: @escaping ([ScoreEvent]) -> Void) -> ListenerRegistration {
        events(sessionID)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                onChange(docs.compactMap { try? $0.data(as: ScoreEvent.self) })
            }
    }

    func fetchAllEvents(_ sessionID: String) async throws -> [ScoreEvent] {
        let snapshot = try await events(sessionID).order(by: "createdAt", descending: true).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: ScoreEvent.self) }
    }

    func fetchSession(_ sessionID: String) async throws -> Session? {
        let doc = try await sessions.document(sessionID).getDocument()
        return doc.exists ? try doc.data(as: Session.self) : nil
    }

    // MARK: - Création

    func createSession(
        mode: GameMode,
        name: String? = nil,
        targetScore: Int?,
        creatorID: String,
        members: [String: Member]
    ) async throws -> Session {
        for _ in 0..<6 {
            let code = CodeGenerator.make()
            let ref = sessions.document(code)
            let session = Session(
                code: code,
                name: name,
                mode: mode,
                creatorID: creatorID,
                createdAt: Date(),
                lastActivityAt: Date(),
                targetScore: targetScore,
                memberIDs: Array(members.keys),
                members: members,
                scores: members.mapValues { _ in 0 }
            )
            let created = try await db.runTransaction { transaction, errorPointer -> Any? in
                do {
                    if try transaction.getDocument(ref).exists { return false }
                    try transaction.setData(from: session, forDocument: ref)
                    return true
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
            if created as? Bool == true {
                var result = session
                result.id = code
                return result
            }
        }
        throw RepositoryError.codeUnavailable
    }

    // MARK: - Rejoindre

    /// Cherche une partie par code court (ID du document ou champ `code` des parties migrées)
    /// ou par ancien identifiant Firestore.
    func findSession(code input: String) async throws -> Session {
        let code = CodeGenerator.normalize(input)
        guard !code.isEmpty, !code.contains("/") else { throw RepositoryError.notFound }
        if let session = try await fetchSession(code) { return session }
        let query = try await sessions.whereField("code", isEqualTo: code).limit(to: 1).getDocuments()
        if let doc = query.documents.first, let session = try? doc.data(as: Session.self) {
            return session
        }
        throw RepositoryError.notFound
    }

    func requestToJoin(_ session: Session, playerID: String, member: Member) async throws {
        if session.memberIDs.contains(playerID) { throw RepositoryError.alreadyMember }
        if session.requestIDs.contains(playerID) { throw RepositoryError.alreadyRequested }
        try await sessions.document(session.sessionID).updateData([
            path("requests", playerID): encode(member),
            "requestIDs": FieldValue.arrayUnion([playerID]),
        ])
    }

    func cancelRequest(sessionID: String, playerID: String) async throws {
        try await sessions.document(sessionID).updateData([
            path("requests", playerID): FieldValue.delete(),
            "requestIDs": FieldValue.arrayRemove([playerID]),
        ])
    }

    func accept(sessionID: String, playerID: String, member: Member) async throws {
        var joined = member
        joined.joinedAt = Date()
        try await sessions.document(sessionID).updateData([
            path("requests", playerID): FieldValue.delete(),
            "requestIDs": FieldValue.arrayRemove([playerID]),
            path("members", playerID): encode(joined),
            path("scores", playerID): FieldValue.increment(Int64(0)),
            "memberIDs": FieldValue.arrayUnion([playerID]),
        ])
    }

    func reject(sessionID: String, playerID: String) async throws {
        try await cancelRequest(sessionID: sessionID, playerID: playerID)
    }

    // MARK: - Points

    /// Marque un point. Ne fait pas d'`await` : l'écriture part dans le cache local
    /// immédiatement (même hors ligne) et sera synchronisée dès que possible.
    /// Lot atomique : +1 au score (FieldValue.increment) et création de l'événement d'historique.
    private func scoreBatch(sessionID: String, playerID: String, byID: String) -> (WriteBatch, DocumentReference) {
        let eventRef = events(sessionID).document()
        let event = ScoreEvent(playerID: playerID, byID: byID, delta: 1, createdAt: Date())
        let batch = db.batch()
        batch.updateData([
            path("scores", playerID): FieldValue.increment(Int64(1)),
            "lastActivityAt": Date(),
        ], forDocument: sessions.document(sessionID))
        _ = try? batch.setData(from: event, forDocument: eventRef)
        return (batch, eventRef)
    }

    @discardableResult
    func score(sessionID: String, playerID: String, byID: String) -> String {
        let (batch, eventRef) = scoreBatch(sessionID: sessionID, playerID: playerID, byID: byID)
        batch.commit { error in
            if let error { print("❌ Point non enregistré : \(error.localizedDescription)") }
        }
        return eventRef.documentID
    }

    /// Variante pour les intents : attend la confirmation du serveur (6 s max),
    /// car l'app peut être suspendue juste après.
    func scoreAndWait(sessionID: String, playerID: String, byID: String) async {
        let (batch, _) = scoreBatch(sessionID: sessionID, playerID: playerID, byID: byID)
        await withTaskGroup(of: Void.self) { group in
            group.addTask { try? await batch.commit() }
            group.addTask { try? await Task.sleep(for: .seconds(6)) }
            await group.next()
            group.cancelAll()
        }
    }

    /// Annule un point. Transaction : deux personnes qui annulent le même point ne retirent qu'un seul point.
    func undo(sessionID: String, eventID: String, byID: String) async throws {
        let sessionRef = sessions.document(sessionID)
        let eventRef = events(sessionID).document(eventID)
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let event = try transaction.getDocument(eventRef).data(as: ScoreEvent.self)
                guard !event.undone else { throw RepositoryError.alreadyUndone }
                transaction.updateData(["undone": true, "undoneByID": byID], forDocument: eventRef)
                transaction.updateData([
                    self.path("scores", event.playerID): FieldValue.increment(Int64(-event.delta)),
                ], forDocument: sessionRef)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    // MARK: - Fin de partie

    func finish(sessionID: String, winnerID: String?) async throws {
        let ref = sessions.document(sessionID)
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let session = try transaction.getDocument(ref).data(as: Session.self)
                guard session.status == .active else { return nil }
                var fields: [String: Any] = ["status": Session.Status.finished.rawValue, "finishedAt": Date()]
                fields["winnerID"] = winnerID ?? FieldValue.delete()
                transaction.updateData(fields, forDocument: ref)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    // MARK: - Quitter / supprimer

    func leave(sessionID: String, playerID: String) async throws {
        try await sessions.document(sessionID).updateData([
            "memberIDs": FieldValue.arrayRemove([playerID]),
            path("members", playerID): FieldValue.delete(),
            path("scores", playerID): FieldValue.delete(),
        ])
    }

    func delete(sessionID: String) async throws {
        // Supprime d'abord l'historique (sous-collection), par lots de 400.
        while true {
            let snapshot = try await events(sessionID).limit(to: 400).getDocuments()
            if snapshot.documents.isEmpty { break }
            let batch = db.batch()
            snapshot.documents.forEach { batch.deleteDocument($0.reference) }
            try await batch.commit()
        }
        try await sessions.document(sessionID).delete()
    }

    // MARK: - Profil

    /// Répercute un changement de nom ou d'avatar dans toutes les parties du joueur.
    func updateMember(playerID: String, member: Member, in sessionIDs: [String]) {
        for id in sessionIDs {
            sessions.document(id).updateData([
                path("members", playerID, "name"): member.name,
                path("members", playerID, "emoji"): member.emoji,
            ])
        }
    }
}
