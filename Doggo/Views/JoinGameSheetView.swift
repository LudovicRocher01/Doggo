//
//  JoinGameSheetView.swift
//  Doggo
//
//  Created by Ludovic Rocher on 01/07/2025.
//

import SwiftUI
import FirebaseFirestore

struct JoinGameSheetView: View {
    @Binding var joinID: String
    @Binding var joinPlayerName: String
    @Binding var showJoinPopup: Bool
    var manager: GameManager

    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Text("Rejoindre une partie")
                .font(.title3.weight(.semibold))
                .padding(.bottom, 4)

            TextField("Code de la partie", text: $joinID)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 24)

            TextField("Entrez votre nom", text: $joinPlayerName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 24)

            Button(action: rejoindrePartie) {
                Text("Rejoindre")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 6)

            Button("Annuler") {
                joinID = ""
                joinPlayerName = ""
                showJoinPopup = false
            }
            .foregroundColor(.red)
            .padding(.top, 2)

            Spacer()
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                // L'utilisateur a vu le message
                if alertMessage.contains("✅") {
                    joinID = ""
                    joinPlayerName = ""
                    showJoinPopup = false
                }
            }
        }
        .padding(.bottom)
        .presentationDetents([.fraction(0.38)])
    }

    private func rejoindrePartie() {
        guard !joinID.isEmpty, !joinPlayerName.isEmpty else {
            alertMessage = "Veuillez entrer le code de la partie et votre nom."
            showAlert = true
            return
        }

        let firestore = Firestore.firestore()
        let player = Player(id: manager.currentPlayerID, name: joinPlayerName)

        firestore.collection("sessions").document(joinID).getDocument { document, error in
            guard let document = document, document.exists else {
                alertMessage = "❌ Partie introuvable."
                showAlert = true
                return
            }

            do {
                var session = try document.data(as: OnlineSession.self)

                if session.players.contains(where: { $0.id == player.id }) {
                    alertMessage = "ℹ️ Vous êtes déjà dans cette partie."
                    showAlert = true
                    return
                }

                if session.pendingRequests.contains(where: { $0.id == player.id }) {
                    alertMessage = "⏳ Demande déjà envoyée. En attente de réponse."
                    showAlert = true
                    return
                }

                session.pendingRequests.append(player)
                try firestore.collection("sessions").document(joinID).setData(from: session) { error in
                    if let error = error {
                        alertMessage = "❌ Erreur lors de l'envoi : \(error.localizedDescription)"
                    } else {
                        alertMessage = "✅ Demande envoyée !"
                        manager.startPollingSessions()
                    }
                    showAlert = true
                }

            } catch {
                alertMessage = "❌ Erreur de décodage."
                showAlert = true
            }
        }
    }
}
