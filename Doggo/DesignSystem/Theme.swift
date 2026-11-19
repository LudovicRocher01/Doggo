//
//  Theme.swift
//  Doggo
//

import SwiftUI
import UIKit

enum Theme {
    /// Caramel, tiré de l'icône.
    static let doggo = Color(light: 0xE8862A, dark: 0xF6A452)
    /// Lavande pour les chats.
    static let gato = Color(light: 0x7457D6, dark: 0xA48CF5)

    static let background = Color(light: 0xFFF7EC, dark: 0x15120F)
    static let card = Color(light: 0xFFFFFF, dark: 0x26211C)
    static let cardStroke = Color(light: 0x000000, dark: 0xFFFFFF).opacity(0.06)
    static let sky = Color(light: 0x8FD3F0, dark: 0x2A4B5C)
    static let gold = Color(hex: 0xF5B82E)
    static let silver = Color(hex: 0xB8C0CC)
    static let bronze = Color(hex: 0xD08A53)

    /// Couleurs des avatars (attribuées de façon stable selon l'ID du joueur).
    static let avatarColors: [Color] = [
        Color(hex: 0xF6A452), Color(hex: 0x8FD3F0), Color(hex: 0xA48CF5), Color(hex: 0x7ED69B),
        Color(hex: 0xF58FA8), Color(hex: 0xF5D04E), Color(hex: 0x6FB7F5), Color(hex: 0xF08A6C),
    ]

    static func color(for id: String) -> Color {
        let hash = id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7FFFFFFF }
        return avatarColors[hash % avatarColors.count]
    }

    static func medal(for rank: Int) -> Color? {
        switch rank {
        case 1: gold
        case 2: silver
        case 3: bronze
        default: nil
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}
