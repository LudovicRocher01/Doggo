//
//  ScoreEvent.swift
//  Doggo
//

import Foundation
import FirebaseFirestore

/// Un point marqué (document `sessions/{id}/events/{eventID}`).
struct ScoreEvent: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    /// Joueur qui reçoit le point.
    var playerID: String
    /// Joueur qui a tapé sur le bouton.
    var byID: String
    var delta: Int = 1
    var createdAt: Date
    var undone: Bool = false
    var undoneByID: String?

    var eventID: String { id ?? "\(playerID)-\(createdAt.timeIntervalSince1970)" }
}
