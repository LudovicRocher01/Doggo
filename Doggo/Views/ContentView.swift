//
//  ContentView.swift
//  Doggo
//
//  Created by Ludovic Rocher on 02/05/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject var manager = GameManager()
    @State private var showPopup = false
    @State private var selectedMode: GameMode = .doggo
    @State private var newPlayerName = ""
    @State private var players: [Player] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack {
                    Spacer().frame(height: 20)
                    Text("🎲 Parties")
                        .font(.custom("ChalkboardSE-Bold", size: 28))
                        .foregroundColor(.brown)

                    Button("Créer une partie") {
                        showPopup = true
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    Spacer().frame(height: 20)
                }
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.96, green: 0.93, blue: 0.87))


                ZStack {
                    Image("fond")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.2)
                        .ignoresSafeArea()

                    List {
                        ForEach(manager.sessions) { session in
                            NavigationLink(destination: SessionDetailView(session: binding(for: session))) {
                                VStack(alignment: .leading) {
                                    Text(session.mode.rawValue)
                                        .font(.headline)
                                    Text(session.players.map(\.name).joined(separator: ", "))
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .onDelete(perform: manager.removeSession)
                    }
                    .listStyle(InsetGroupedListStyle())
                    .scrollContentBackground(.hidden)
                }
            }

            .sheet(isPresented: $showPopup) {
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

                    HStack {
                        TextField("Nom du joueur", text: $newPlayerName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Button {
                            guard !newPlayerName.isEmpty else { return }
                            players.append(Player(name: newPlayerName))
                            newPlayerName = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)

                    List {
                        ForEach(players) { player in
                            Text(player.name)
                        }
                        .onDelete { indexSet in
                            players.remove(atOffsets: indexSet)
                        }
                    }

                    Button(action: {
                        if players.isEmpty { return }
                        manager.addSession(mode: selectedMode, players: players)
                        players.removeAll()
                        showPopup = false
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
                        showPopup = false
                        players.removeAll()
                    }
                    .padding(.top)
                }
                .presentationDetents([.medium])
            }
        }
    }

    private func binding(for session: GameSession) -> Binding<GameSession> {
        guard let index = manager.sessions.firstIndex(where: { $0.id == session.id }) else {
            fatalError("Session not found")
        }
        return $manager.sessions[index]
    }
}
