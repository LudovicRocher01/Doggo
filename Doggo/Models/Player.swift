//
//  Player.swift
//  Doggo
//
//  Created by Ludovic Rocher on 02/05/2025.
//

import Foundation

struct Player: Identifiable, Codable {
    var id: String
    var name: String
    var score: Int

    init(id: String = UUID().uuidString, name: String, score: Int = 0) {
        self.id = id
        self.name = name
        self.score = score
    }
}
