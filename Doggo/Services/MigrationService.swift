//
//  MigrationService.swift
//  Doggo
//
//  Convertit les parties de la v1 (tableau `players` avec scores, réécrit en entier à chaque point)
//  vers le schéma v2 (maps `members` / `scores`, `memberIDs` pour les requêtes).
//  Exécutée une seule fois par appareil ; chaque partie n'est convertie qu'une fois (transaction).
//

import Foundation
import FirebaseFirestore

enum MigrationService {
    private static let doneKey = "didMigrateV2"

    static func migrateIfNeeded(playerID: String) async {
        guard !UserDefaults.standard.bool(forKey: doneKey) else { return }
        let db = Firestore.firestore()
        do {
            // Dernier scan complet : les anciens documents n'ont pas de `memberIDs` interrogeable.
            let snapshot = try await db.collection("sessions").getDocuments()
            var allSucceeded = true
            for doc in snapshot.documents where doc.data()["schemaVersion"] == nil {
                guard isMember(playerID, of: doc.data()) else { continue }
                do {
                    try await migrate(doc.reference, db: db)
                } catch {
                    allSucceeded = false
                    print("❌ Migration de \(doc.documentID) : \(error.localizedDescription)")
                }
            }
            if allSucceeded { UserDefaults.standard.set(true, forKey: doneKey) }
        } catch {
            print("❌ Migration impossible (hors ligne ?) : \(error.localizedDescription)")
        }
    }

    private static func isMember(_ playerID: String, of data: [String: Any]) -> Bool {
        if data["creatorID"] as? String == playerID { return true }
        let players = data["players"] as? [[String: Any]] ?? []
        return players.contains { $0["id"] as? String == playerID }
    }

    static func migrate(_ ref: DocumentReference, db: Firestore) async throws {
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(ref)
                guard let data = snapshot.data(), data["schemaVersion"] == nil else { return nil }
                transaction.updateData(convert(data), forDocument: ref)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    /// Construit les champs v2 à partir d'un document v1.
    static func convert(_ data: [String: Any]) -> [AnyHashable: Any] {
        let creatorID = data["creatorID"] as? String ?? ""
        var players = (data["players"] as? [[String: Any]]) ?? []
        let pending = (data["pendingRequests"] as? [[String: Any]]) ?? []

        // En v1, le joueur créé par l'hôte avait un ID aléatoire (et non son ID d'appareil).
        // C'est toujours le premier du tableau : on le rattache au créateur.
        if !creatorID.isEmpty, !players.contains(where: { $0["id"] as? String == creatorID }), !players.isEmpty {
            players[0]["id"] = creatorID
        }

        let avatars = PlayerProfile.avatarChoices
        var memberIDs: [String] = []
        var members: [String: Any] = [:]
        var scores: [String: Any] = [:]
        for (index, player) in players.enumerated() {
            guard let id = player["id"] as? String, !memberIDs.contains(id) else { continue }
            memberIDs.append(id)
            members[id] = [
                "name": player["name"] as? String ?? "Joueur",
                "emoji": avatars[index % avatars.count],
            ]
            scores[id] = (player["score"] as? NSNumber)?.intValue ?? 0
        }

        var requestIDs: [String] = []
        var requests: [String: Any] = [:]
        for player in pending {
            guard let id = player["id"] as? String, !memberIDs.contains(id), !requestIDs.contains(id) else { continue }
            requestIDs.append(id)
            requests[id] = ["name": player["name"] as? String ?? "Joueur", "emoji": "🐾"]
        }

        let mode = GameMode(storedValue: data["mode"] as? String ?? "")
        return [
            "schemaVersion": 2,
            "code": CodeGenerator.make(),
            "mode": mode.rawValue,
            "creatorID": creatorID.isEmpty ? (memberIDs.first ?? "") : creatorID,
            "createdAt": Date(),
            "lastActivityAt": Date(),
            "status": Session.Status.active.rawValue,
            "memberIDs": memberIDs,
            "members": members,
            "scores": scores,
            "requestIDs": requestIDs,
            "requests": requests,
            "players": FieldValue.delete(),
            "pendingRequests": FieldValue.delete(),
        ]
    }
}
