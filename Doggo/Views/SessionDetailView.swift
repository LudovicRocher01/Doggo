//
//  SessionDetailView.swift
//  Doggo
//
//  Created by Ludovic Rocher on 06/05/2025.
//

import SwiftUI

struct SessionDetailView: View {
    @StateObject var manager: GameSessionManager

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(manager.session.mode == .doggo ? "🐶 Doggo" : "🐱 Gato")
                    .font(.custom("ChalkboardSE-Bold", size: 28))
                    .foregroundColor(.brown)
                    .padding(.top, 8)

                if let id = manager.session.id {
                    HStack(spacing: 4) {
                        Text("Code de la partie :")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Button(action: {
                            UIPasteboard.general.string = id
                        }) {
                            Label(id, systemImage: "doc.on.doc")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.96, green: 0.93, blue: 0.87))

            ZStack(alignment: .bottom) {
                Image(manager.session.mode == .doggo ? "doggo_fond" : "gato_fond")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.2)
                    .ignoresSafeArea()

                List {
                    Section(header: Text("Joueurs").font(.headline)) {
                        ForEach(manager.session.players) { player in
                            VStack(alignment: .leading) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(player.name)
                                            .font(.headline)
                                        Text("\(player.score) \(player.score > 1 ? "points" : "point")")
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    HStack(spacing: 8) {
                                        Button {
                                            manager.decrementScore(for: player)
                                        } label: {
                                            Text("-1")
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
                                                .background(Color.red.opacity(0.2))
                                                .foregroundColor(.red)
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(.borderless)

                                        Button {
                                            manager.incrementScore(for: player)
                                        } label: {
                                            Text(manager.session.mode == .doggo ? "🐶 Doggo !" : "🐱 Gato !")
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
                                                .background(Color.green.opacity(0.2))
                                                .foregroundColor(.green)
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                        .onDelete(perform: manager.removePlayers)
                    }

                    if !manager.session.pendingRequests.isEmpty {
                        Section(header: Text("Demandes de participation").font(.headline)) {
                            ForEach(manager.session.pendingRequests) { request in
                                HStack {
                                    Text(request.name)
                                    Spacer()
                                    Button("Accepter") {
                                        manager.acceptPlayer(request)
                                    }
                                    .foregroundColor(.green)

                                    Button("Refuser") {
                                        manager.rejectPlayer(request)
                                    }
                                    .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                Text(manager.topScorerText)
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                    .padding()
            }
        }
    }
}
