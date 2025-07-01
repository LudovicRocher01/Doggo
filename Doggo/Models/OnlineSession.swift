//
//  OnlineSession.swift
//  Doggo
//
//  Created by Ludovic Rocher on 06/05/2025.
//

import Foundation
import FirebaseFirestore

enum GameMode: String, Codable, CaseIterable {
    case doggo = "Doggo 🐶"
    case gato = "Gato 🐱"
}

struct OnlineSession: Codable, Identifiable {
    @DocumentID var id: String?
    var mode: GameMode
    var players: [Player]
    var pendingRequests: [Player] = []
    var creatorID: String = ""
}
