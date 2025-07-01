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
    @State private var showJoinPopup = false
    
    @State private var selectedMode: GameMode = .doggo
    @State private var creatorName = ""

    @State private var joinID = ""
    @State private var joinPlayerName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack {
                    Spacer().frame(height: 20)
                    Text("🐶 Doggo")
                        .font(.custom("ChalkboardSE-Bold", size: 28))
                        .foregroundColor(.brown)

                    Button("Créer une partie") {
                        creatorName = ""
                        selectedMode = .doggo
                        showPopup = true
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    Button("Rejoindre une partie") {
                        joinID = ""
                        joinPlayerName = ""
                        showJoinPopup = true
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
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
                            NavigationLink(destination: SessionDetailView(manager: GameSessionManager(session: session, manager: manager))) {
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
                CreateGameSheetView(
                    isPresented: $showPopup,
                    selectedMode: $selectedMode,
                    manager: manager
                )
            }

            .sheet(isPresented: $showJoinPopup) {
                JoinGameSheetView(
                    joinID: $joinID,
                    joinPlayerName: $joinPlayerName,
                    showJoinPopup: $showJoinPopup,
                    manager: manager
                )
            }
        }
    }
}
