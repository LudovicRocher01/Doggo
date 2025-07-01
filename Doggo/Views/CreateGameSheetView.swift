//
//  CreateGameSheetView.swift
//  Doggo
//
//  Created by Ludovic Rocher on 01/07/2025.
//

import SwiftUI

struct CreateGameSheetView: View {
    @Binding var isPresented: Bool
    @Binding var selectedMode: GameMode
    @ObservedObject var manager: GameManager

    @State private var creatorName: String = ""
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Text("Créer une partie")
                .font(.title3.weight(.semibold))
                .padding(.bottom, 4)

            Picker("Mode de jeu", selection: $selectedMode) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            TextField("Entrez votre nom", text: $creatorName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 24)
                .padding(.top, 4)

            Button(action: createGame) {
                Text("Créer la partie")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 8)

            Button("Annuler") {
                isPresented = false
                creatorName = ""
            }
            .foregroundColor(.red)
            .padding(.top, 2)

            Spacer()
        }
        .alert("Veuillez entrer un nom", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
        .padding(.bottom)
        .presentationDetents([.fraction(0.38)])
    }

    private func createGame() {
        guard !creatorName.isEmpty else {
            showAlert = true
            return
        }

        let creator = Player(name: creatorName)
        let firestore = FirestoreGameService()

        firestore.createSession(mode: selectedMode, creator: creator, creatorID: manager.currentPlayerID) { sessionID in
            if let id = sessionID {
                var onlineSession = OnlineSession(mode: selectedMode, players: [creator])
                onlineSession.id = id
                onlineSession.creatorID = manager.currentPlayerID

                DispatchQueue.main.async {
                    manager.sessions.append(onlineSession)
                }
            } else {
                print("❌ Échec de la création de la session")
            }

            isPresented = false
            creatorName = ""
        }
    }
}
