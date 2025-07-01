//
//  JoinGameSheetView.swift
//  Doggo
//
//  Created by Ludovic Rocher on 01/07/2025.
//

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
    @ObservedObject var manager: GameManager = GameManager()

    var body: some View {
        VStack {
            Text("Rejoindre une partie")
                .font(.title2)
                .bold()
                .padding(.top)

            TextField("Code de la partie", text: $joinID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Nom du joueur", text: $joinPlayerName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Rejoindre") {
                guard !joinID.isEmpty, !joinPlayerName.isEmpty else { return }

                let firestore = FirestoreGameService()
                let player = Player(name: joinPlayerName)

                firestore.sendJoinRequest(sessionID: joinID, player: player) { success in
                    if success {
                        print("✅ Demande envoyée")
                        joinID = ""
                        joinPlayerName = ""
                        showJoinPopup = false
                    } else {
                        print("❌ Échec de la demande")
                    }
                }
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)

            Button("Annuler") {
                showJoinPopup = false
            }
            .padding(.top)
        }
        .presentationDetents([.medium])
    }
}
