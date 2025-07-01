//
//  FirestoreGameService.swift
//  Doggo
//
//  Created by Ludovic Rocher on 30/06/2025.
//

import Foundation
import FirebaseFirestore

class FirestoreGameService {
    private let db = Firestore.firestore()
    
    func createSession(mode: GameMode, creator: Player, creatorID: String, completion: @escaping (String?) -> Void) {
        var newSession = OnlineSession(mode: mode, players: [creator])
        newSession.creatorID = creatorID

        do {
            let ref = try db.collection("sessions").addDocument(from: newSession)
            completion(ref.documentID)
        } catch {
            print("Erreur Firestore : \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    func fetchSession(by id: String, completion: @escaping (OnlineSession?) -> Void) {
        db.collection("sessions").document(id).getDocument { doc, error in
            if let error = error {
                print("Erreur de récupération : \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let doc = doc, doc.exists {
                do {
                    let session = try doc.data(as: OnlineSession.self)
                    completion(session)
                } catch {
                    print("Erreur de décodage : \(error.localizedDescription)")
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }

    func fetchSessions(for playerID: String, completion: @escaping ([OnlineSession]) -> Void) {
        db.collection("sessions").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Erreur récupération : \(error.localizedDescription)")
                completion([])
                return
            }

            guard let docs = snapshot?.documents else {
                completion([])
                return
            }

            let sessions = docs.compactMap { doc -> OnlineSession? in
                try? doc.data(as: OnlineSession.self)
            }

            let filtered = sessions.filter {
                $0.creatorID == playerID || $0.players.contains(where: { $0.id == playerID })
            }
            completion(filtered)
        }
    }

    func updateSession(_ session: OnlineSession) {
        guard let id = session.id else { return }
        
        do {
            try db.collection("sessions").document(id).setData(from: session)
        } catch {
            print("Erreur de mise à jour : \(error.localizedDescription)")
        }
    }
    
    func sendJoinRequest(sessionID: String, player: Player, completion: @escaping (Bool) -> Void) {
        let ref = db.collection("sessions").document(sessionID)
        
        ref.getDocument { document, error in
            if let document = document, document.exists {
                do {
                    var session = try document.data(as: OnlineSession.self)
                    
                    if !session.pendingRequests.contains(where: { $0.id == player.id }) {
                        session.pendingRequests.append(player)
                        try ref.setData(from: session) { error in
                            completion(error == nil)
                        }
                    } else {
                        completion(true)
                    }
                } catch {
                    print("Erreur lors du décodage : \(error)")
                    completion(false)
                }
            } else {
                print("Session introuvable : \(error?.localizedDescription ?? "inconnue")")
                completion(false)
            }
        }
    }
}
