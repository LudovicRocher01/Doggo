//
//  CreateGameSheetView.swift
//  Doggo
//
//  Created by Ludovic Rocher on 01/07/2025.
//

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
        VStack {
            Text("Créer une partie")
                .font(.title2)
                .bold()
                .padding(.top)

            Picker("Mode de jeu", selection: $selectedMode) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            TextField("Nom du joueur", text: $creatorName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
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

            }) {
                Text("Créer la partie")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Button("Annuler") {
                isPresented = false
                creatorName = ""
            }
            .padding(.top)
        }
        .alert("Veuillez entrer un nom", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .presentationDetents([.medium])
    }
}
