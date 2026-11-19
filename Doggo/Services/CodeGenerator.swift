//
//  CodeGenerator.swift
//  Doggo
//

import Foundation

/// Codes de partie courts, faciles à dicter : pas de 0/O, 1/I/L.
enum CodeGenerator {
    static let alphabet = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
    static let length = 6

    static func make() -> String {
        String((0..<length).map { _ in alphabet.randomElement()! })
    }

    /// Normalise une saisie utilisateur ou un lien (`doggo://join/WOOF42`).
    /// Les anciens identifiants Firestore (20 caractères) sont conservés tels quels.
    static func normalize(_ input: String) -> String {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: value), url.scheme == "doggo" {
            value = url.lastPathComponent
        }
        let compact = value.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        return compact.count == length ? compact.uppercased() : compact
    }

    static func joinURL(for code: String) -> URL {
        URL(string: "doggo://join/\(code)")!
    }
}
