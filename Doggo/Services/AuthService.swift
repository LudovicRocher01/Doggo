//
//  AuthService.swift
//  Doggo
//

import Foundation
import FirebaseAuth

/// Authentification anonyme Firebase : aucune donnée personnelle,
/// elle permet seulement aux règles Firestore de refuser les accès non authentifiés.
enum AuthService {
    static func ensureSignedIn() async {
        guard Auth.auth().currentUser == nil else { return }
        do {
            _ = try await Auth.auth().signInAnonymously()
        } catch {
            // Si l'auth anonyme n'est pas activée dans la console, l'app continue de fonctionner
            // tant que les règles Firestore l'autorisent.
            NSLog("⚠️ Connexion anonyme impossible : %@", error.localizedDescription)
        }
    }
}
