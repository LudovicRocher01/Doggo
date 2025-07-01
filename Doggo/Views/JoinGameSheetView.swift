//
//  JoinGameSheetView.swift
//  Doggo
//
//  Created by Ludovic Rocher on 01/07/2025.
//

import SwiftUI

struct JoinGameSheetView: View {
    @Binding var joinID: String
    @Binding var joinPlayerName: String
    @Binding var showJoinPopup: Bool
    var manager: GameManager

    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Rejoindre une partie")
                .font(.title2.bold())
                .padding(.top)

            TextField("Code de la partie", text: $joinID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Nom du joueur", text: $joinPlayerName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: rejoindrePartie) {
                Text("Rejoindre")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Button("Annuler") {
                showJoinPopup = false
            }
            .foregroundColor(.red)

            Spacer()
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .presentationDetents([.medium])
    }

    private func rejoindrePartie() {
        guard !joinID.isEmpty, !joinPlayerName.isEmpty else {
            alertMessage = "Veuillez entrer le code de la partie et votre nom."
            showAlert = true
            return
        }

        let firestore = FirestoreGameService()
        let player = Player(id: manager.currentPlayerID, name: joinPlayerName)

        firestore.sendJoinRequest(sessionID: joinID, player: player) { success in
            if success {
                // Demande acceptée, on attend que l’autre joueur accepte réellement
                alertMessage = "✅ Demande envoyée !"
                showAlert = true
                joinID = ""
                joinPlayerName = ""
                showJoinPopup = false

                // Démarre un polling pour détecter automatiquement si on est accepté
                manager.startPollingSessions()

            } else {
                alertMessage = "❌ Code invalide ou erreur réseau."
                showAlert = true
            }
        }
    }
}
