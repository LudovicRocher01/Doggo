//
//  DebugTools.swift
//  Doggo
//
//  Outils de développement (compilés uniquement en DEBUG) :
//  - `-DoggoDemo YES` : données fictives locales (aucun accès réseau), pour les captures et les previews.
//  - `-DoggoSelfTest YES` : test de bout en bout contre Firestore avec deux clients simultanés.
//

#if DEBUG
import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

enum DemoData {
    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: "DoggoDemo") }
    static let me = "demo-me"

    static func isDemo(_ sessionID: String) -> Bool { sessionID.hasPrefix("DEMO") }

    static let profile = PlayerProfile(name: "Ludo", emoji: "🦊")

    static var sessions: [Session] {
        let members: [String: Member] = [
            me: Member(name: "Ludo", emoji: "🦊"),
            "p2": Member(name: "Nina", emoji: "🐼"),
            "p3": Member(name: "Tom", emoji: "🐸"),
            "p4": Member(name: "Sarah", emoji: "🦄"),
        ]
        var doggo = Session(
            id: "DEMO01", code: "WOOF42", name: "Les colocs", mode: .doggo, creatorID: me,
            createdAt: Date().addingTimeInterval(-86400 * 20), lastActivityAt: Date(),
            targetScore: 50, memberIDs: [me, "p2", "p3", "p4"], members: members,
            scores: [me: 31, "p2": 27, "p3": 12, "p4": 27],
            requestIDs: ["p5"], requests: ["p5": Member(name: "Max", emoji: "🐻")]
        )
        doggo.id = "DEMO01"
        var gato = Session(
            id: "DEMO02", code: "MIAOU7", name: "Vacances Bretagne", mode: .gato, creatorID: "p2",
            createdAt: Date().addingTimeInterval(-86400 * 3), lastActivityAt: Date().addingTimeInterval(-3600),
            memberIDs: [me, "p2"], members: [me: members[me]!, "p2": members["p2"]!],
            scores: [me: 4, "p2": 9]
        )
        gato.id = "DEMO02"
        var finished = Session(
            id: "DEMO03", code: "OUAF99", name: "Été 2026", mode: .doggo, creatorID: me,
            createdAt: Date().addingTimeInterval(-86400 * 60), lastActivityAt: Date().addingTimeInterval(-86400 * 30),
            status: .finished, winnerID: "p3", finishedAt: Date().addingTimeInterval(-86400 * 30), targetScore: 25,
            memberIDs: [me, "p2", "p3", "p4"], members: members,
            scores: [me: 19, "p2": 22, "p3": 25, "p4": 8]
        )
        finished.id = "DEMO03"
        return [doggo, gato, finished]
    }

    static func events(for session: Session) -> [ScoreEvent] {
        var result: [ScoreEvent] = []
        let ids = session.memberIDs
        for index in 0..<40 {
            let playerID = ids[index % ids.count]
            var event = ScoreEvent(
                playerID: playerID,
                byID: index % 3 == 0 ? me : playerID,
                createdAt: Date().addingTimeInterval(-Double(index) * 5400 - 120),
                undone: index == 2
            )
            event.id = "E\(index)"
            result.append(event)
        }
        return result
    }
}

enum SelfTest {
    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: "DoggoSelfTest") }

    private static func log(_ message: String) { NSLog("SELFTEST %@", message) }

    static func run() async {
        log("début")
        let primaryDB = Firestore.firestore()
        // Second client Firebase indépendant = « un deuxième téléphone ».
        if FirebaseApp.app(name: "selftestB") == nil, let options = FirebaseApp.app()?.options {
            FirebaseApp.configure(name: "selftestB", options: options)
        }
        guard let appB = FirebaseApp.app(name: "selftestB") else { return log("FAIL pas de second client") }
        // Chaque client a sa propre session d'authentification (exigée par les règles).
        do {
            if Auth.auth(app: appB).currentUser == nil { _ = try await Auth.auth(app: appB).signInAnonymously() }
        } catch {
            return log("FAIL connexion anonyme du second client : \(error.localizedDescription)")
        }
        let dbB = Firestore.firestore(app: appB)
        let repoA = SessionRepository(firestore: primaryDB)
        let repoB = SessionRepository(firestore: dbB)

        let a = "selftest-A-\(UUID().uuidString.prefix(8))"
        let b = "selftest-B-\(UUID().uuidString.prefix(8))"
        var failures = 0
        func check(_ condition: Bool, _ label: String) {
            if condition { log("OK   \(label)") } else { failures += 1; log("FAIL \(label)") }
        }

        var sessionID = ""
        var legacyRef: DocumentReference?
        do {
            // 1. Création + code court
            let created = try await repoA.createSession(mode: .doggo, name: "Self-test", targetScore: nil, creatorID: a,
                                                        members: [a: Member(name: "Alice", emoji: "🦊")])
            sessionID = created.sessionID
            check(created.code.count == 6 && created.sessionID == created.code, "code court \(created.code)")

            // 2. Rejoindre par code (minuscules) + acceptation
            let found = try await repoB.findSession(code: created.code.lowercased())
            check(found.sessionID == sessionID, "recherche par code")
            try await repoB.requestToJoin(found, playerID: b, member: Member(name: "Bob", emoji: "🐼"))
            var session = try await repoA.fetchSession(sessionID)
            check(session?.requestIDs == [b], "demande reçue")
            try await repoA.accept(sessionID: sessionID, playerID: b, member: session!.requests[b]!)
            session = try await repoA.fetchSession(sessionID)
            check(session?.memberIDs.contains(b) == true && session?.score(of: b) == 0 && session?.requestIDs.isEmpty == true, "acceptation")

            // 3. Course : 2 clients × 20 points simultanés (chacun donne 10 points à A et 10 à B)
            let id = sessionID
            await withTaskGroup(of: Void.self) { group in
                for index in 0..<20 {
                    group.addTask { await repoA.scoreAndWait(sessionID: id, playerID: index.isMultiple(of: 2) ? a : b, byID: a) }
                    group.addTask { await repoB.scoreAndWait(sessionID: id, playerID: index.isMultiple(of: 2) ? a : b, byID: b) }
                }
            }
            session = try await repoA.fetchSession(sessionID)
            check(session?.score(of: a) == 20 && session?.score(of: b) == 20,
                  "40 points simultanés, aucun perdu (A=\(session?.score(of: a) ?? -1), B=\(session?.score(of: b) ?? -1))")
            let events = try await repoA.fetchAllEvents(sessionID)
            check(events.count == 40, "40 événements d'historique (\(events.count))")

            // 4. Double annulation simultanée du même point : un seul point retiré
            let target = events.first { $0.playerID == a }!
            async let undoA: Void? = try? repoA.undo(sessionID: id, eventID: target.id!, byID: a)
            async let undoB: Void? = try? repoB.undo(sessionID: id, eventID: target.id!, byID: b)
            _ = await (undoA, undoB)
            session = try await repoA.fetchSession(sessionID)
            check(session?.score(of: a) == 19, "double annulation → 1 seul point retiré (A=\(session?.score(of: a) ?? -1))")

            // 5. Fin de partie (B mène 20 à 19)
            try await repoA.finish(sessionID: sessionID, winnerID: session?.soleLeaderID)
            session = try await repoA.fetchSession(sessionID)
            check(session?.isFinished == true && session?.winnerID == b, "fin de partie, vainqueur B")

            // 6. Migration d'un document v1
            legacyRef = primaryDB.collection("sessions").document()
            try await legacyRef!.setData([
                "mode": "Gato 🐱",
                "creatorID": a,
                "players": [["id": UUID().uuidString, "name": "Alice", "score": 12],
                            ["id": b, "name": "Bob", "score": 7]],
                "pendingRequests": [["id": "selftest-C", "name": "Chloé", "score": 0]],
            ])
            try await MigrationService.migrate(legacyRef!, db: primaryDB)
            try await MigrationService.migrate(legacyRef!, db: primaryDB) // idempotent
            let migrated = try await legacyRef!.getDocument().data(as: Session.self)
            check(migrated.mode == .gato, "migration : mode")
            check(migrated.score(of: a) == 12 && migrated.score(of: b) == 7, "migration : scores conservés + créateur rattaché")
            check(migrated.memberIDs.sorted() == [a, b].sorted() && migrated.creatorID == a, "migration : membres")
            check(migrated.requestIDs == ["selftest-C"], "migration : demandes en attente")
            check(migrated.code.count == 6, "migration : code court \(migrated.code)")
            let found2 = try await repoB.findSession(code: migrated.code)
            check(found2.sessionID == legacyRef!.documentID, "migration : partie trouvable par son code court")
            let raw = try await legacyRef!.getDocument().data() ?? [:]
            check(raw["players"] == nil && raw["pendingRequests"] == nil, "migration : anciens champs supprimés")
        } catch {
            failures += 1
            log("FAIL erreur : \(error)")
        }

        // Nettoyage
        if !sessionID.isEmpty { try? await repoA.delete(sessionID: sessionID) }
        if let legacyRef { try? await legacyRef.delete() }
        let leftover = sessionID.isEmpty ? nil : try? await repoA.fetchSession(sessionID)
        check(leftover == nil, "nettoyage")
        log(failures == 0 ? "RESULTAT: TOUT EST OK" : "RESULTAT: \(failures) ECHEC(S)")
    }
}
#endif
