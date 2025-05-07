//
//  SessionDetailView.swift
//  Doggo
//
//  Created by Ludovic Rocher on 06/05/2025.
//

import SwiftUI

struct SessionDetailView: View {
    @StateObject var manager: GameSessionManager
    @State private var newPlayerName = ""

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Text(manager.session.mode == .doggo ? "🐶 Doggo" : "🐱 Gato")
                    .font(.custom("ChalkboardSE-Bold", size: 28))
                    .foregroundColor(.brown)

                HStack {
                    TextField("Nom du joueur", text: $newPlayerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button {
                        guard !newPlayerName.isEmpty else { return }
                        manager.addPlayer(name: newPlayerName)
                        newPlayerName = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing)
                }

                Spacer().frame(height: 10)
            }
            .background(Color(red: 0.96, green: 0.93, blue: 0.87))

            ZStack(alignment: .bottom) {
                Image(manager.session.mode == .doggo ? "doggo_fond" : "gato_fond")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.2)
                    .ignoresSafeArea()

                List {
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
                        .contentShape(Rectangle())
                    }
                    .onDelete(perform: manager.removePlayers)
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
