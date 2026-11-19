//
//  Session.swift
//  Doggo
//

import Foundation
import FirebaseFirestore

/// Un joueur tel qu'il apparaît dans une partie.
struct Member: Codable, Equatable, Hashable {
    var name: String
    var emoji: String
    var joinedAt: Date?
}

/// Une partie (document `sessions/{id}`, schéma v2).
struct Session: Codable, Identifiable, Equatable {
    enum Status: String, Codable {
        case active
        case finished
    }

    @DocumentID var id: String?
    var schemaVersion: Int = 2
    var code: String
    var name: String?
    var mode: GameMode
    var creatorID: String
    var createdAt: Date?
    var lastActivityAt: Date?
    var status: Status = .active
    var winnerID: String?
    var finishedAt: Date?
    var targetScore: Int?
    var memberIDs: [String] = []
    var members: [String: Member] = [:]
    var scores: [String: Int] = [:]
    var requestIDs: [String] = []
    var requests: [String: Member] = [:]

    var sessionID: String { id ?? code }
    var displayName: String {
        if let name, !name.isEmpty { return name }
        return "Partie \(mode.title)"
    }
    var isFinished: Bool { status == .finished }

    func score(of playerID: String) -> Int { scores[playerID] ?? 0 }

    /// Joueurs triés par score décroissant puis par nom.
    var standings: [PlayerStanding] {
        let entries = memberIDs.compactMap { id -> PlayerStanding? in
            guard let member = members[id] else { return nil }
            return PlayerStanding(id: id, member: member, score: score(of: id), rank: 0)
        }
        .sorted { lhs, rhs in
            lhs.score != rhs.score ? lhs.score > rhs.score
                : lhs.member.name.localizedCaseInsensitiveCompare(rhs.member.name) == .orderedAscending
        }

        // Classement "olympique" : les ex-aequo partagent le même rang.
        var result: [PlayerStanding] = []
        for (index, entry) in entries.enumerated() {
            var ranked = entry
            if let previous = result.last, previous.score == entry.score {
                ranked.rank = previous.rank
            } else {
                ranked.rank = index + 1
            }
            result.append(ranked)
        }
        return result
    }

    /// Le leader s'il est seul en tête avec au moins un point.
    var soleLeaderID: String? {
        let top = standings.filter { $0.rank == 1 && $0.score > 0 }
        return top.count == 1 ? top.first?.id : nil
    }

    var totalPoints: Int { scores.values.reduce(0, +) }

    var leaderSummary: String {
        let standings = standings
        guard let first = standings.first, first.score > 0 else { return "Aucun point pour l'instant" }
        let leaders = standings.filter { $0.rank == 1 }
        if leaders.count > 1 { return "Égalité à \(first.score) pts" }
        return "\(first.member.emoji) \(first.member.name) mène avec \(first.score) pt\(first.score > 1 ? "s" : "")"
    }
}

struct PlayerStanding: Identifiable, Equatable {
    let id: String
    let member: Member
    let score: Int
    var rank: Int
}
