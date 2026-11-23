//
//  HomeView.swift
//  Doggo
//

import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var app
    @State private var showCreate = false
    @State private var showJoin = false
    @State private var showProfile = false
    @State private var joinCode = ""
    @State private var showFinished = false

    var body: some View {
        @Bindable var app = app
        NavigationStack(path: $app.path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HomeHeader(profile: app.profile) { showProfile = true }

                    if !app.isLoaded && app.sessions.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if app.sessions.isEmpty && app.outgoingRequests.isEmpty {
                        EmptyHomeView { showCreate = true }
                    }

                    if !app.outgoingRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "En attente")
                            ForEach(app.outgoingRequests) { session in
                                PendingRequestCard(session: session)
                            }
                        }
                    }

                    if !app.activeSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "En cours", trailing: "\(app.activeSessions.count)")
                            ForEach(app.activeSessions) { session in
                                NavigationLink(value: session.sessionID) {
                                    SessionCard(session: session, playerID: app.playerID)
                                }
                                .buttonStyle(PressableStyle(scale: 0.97))
                            }
                        }
                    }

                    if !app.finishedSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                withAnimation(.snappy) { showFinished.toggle() }
                            } label: {
                                HStack {
                                    SectionTitle(title: "Terminées", trailing: "\(app.finishedSessions.count)")
                                    Image(systemName: "chevron.down")
                                        .rotationEffect(.degrees(showFinished ? 0 : -90))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            if showFinished {
                                ForEach(app.finishedSessions) { session in
                                    NavigationLink(value: session.sessionID) {
                                        FinishedSessionRow(session: session)
                                    }
                                    .buttonStyle(PressableStyle(scale: 0.97))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                HomeActionBar(onCreate: { showCreate = true }, onJoin: {
                    joinCode = ""
                    showJoin = true
                })
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                // .id : chaque partie a son propre état (sinon « Revanche » réaffiche l'ancienne partie).
                GameView(sessionID: id)
                    .id(id)
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateGameSheet()
        }
        .sheet(isPresented: $showJoin) {
            JoinGameSheet(initialCode: joinCode)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .onChange(of: app.pendingJoinCode, initial: true) { _, code in
            guard let code else { return }
            app.pendingJoinCode = nil
            // Lien vers une partie dont on est déjà membre : on l'ouvre directement.
            if let session = app.sessions.first(where: { $0.code == code || $0.sessionID == code }) {
                app.open(session.sessionID)
                return
            }
            joinCode = code
            showCreate = false
            showProfile = false
            showJoin = true
        }
    }
}

// MARK: - En-tête

private struct HomeHeader: View {
    let profile: PlayerProfile?
    var onProfile: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("fond")
                .resizable()
                .scaledToFill()
                .frame(height: 230)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(alignment: .bottom) {
                    LinearGradient(colors: [.clear, Theme.background], startPoint: .center, endPoint: .bottom)
                }
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

            HStack(alignment: .bottom, spacing: 14) {
                MascotView(size: 76)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Doggo")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                    Text("Le premier qui le dit marque !")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onProfile) {
                Text(profile?.emoji ?? "🙂")
                    .font(.system(size: 26))
                    .frame(width: 48, height: 48)
                    .glassSurface(cornerRadius: 24, interactive: true)
            }
            .buttonStyle(PressableStyle())
            .padding(12)
            .accessibilityLabel("Profil et réglages")
        }
        .padding(.top, 8)
    }
}

// MARK: - Cartes

struct SessionCard: View {
    let session: Session
    let playerID: String

    private var myStanding: PlayerStanding? { session.standings.first { $0.id == playerID } }

    var body: some View {
        HStack(spacing: 14) {
            Text(session.mode.emoji)
                .font(.system(size: 34))
                .frame(width: 60, height: 60)
                .background(session.mode.gradient.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(session.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    if session.creatorID == playerID && !session.requestIDs.isEmpty {
                        Text("\(session.requestIDs.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.red, in: Capsule())
                            .accessibilityLabel("\(session.requestIDs.count) demande(s) en attente")
                    }
                }
                Text(session.leaderSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                AvatarStack(members: session.standings.map { ($0.id, $0.member) }, size: 26)
            }

            Spacer(minLength: 0)

            if let mine = myStanding {
                VStack(spacing: 0) {
                    Text("\(mine.score)")
                        .font(.title.bold())
                        .foregroundStyle(session.mode.accent)
                        .contentTransition(.numericText())
                    Text(mine.rank == 1 && mine.score > 0 ? "👑 1er" : "\(mine.rank)e")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .animation(.snappy, value: mine.score)
            }
        }
        .padding(14)
        .cardSurface()
        .contentShape(Rectangle())
    }
}

private struct FinishedSessionRow: View {
    let session: Session

    var body: some View {
        HStack(spacing: 12) {
            Text("🏆").font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayName).font(.headline)
                if let winner = session.winnerID.flatMap({ session.members[$0] }) {
                    Text("\(winner.emoji) \(winner.name) a gagné").font(.subheadline).foregroundStyle(.secondary)
                } else {
                    Text("Égalité").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            ModeBadge(mode: session.mode)
        }
        .padding(14)
        .cardSurface(cornerRadius: 20)
        .opacity(0.85)
    }
}

private struct PendingRequestCard: View {
    @Environment(AppModel.self) private var app
    let session: Session

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayName).font(.headline)
                Text("Demande envoyée, en attente de l'hôte")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Annuler", role: .destructive) {
                Task { try? await app.repository.cancelRequest(sessionID: session.sessionID, playerID: app.playerID) }
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(14)
        .glassSurface(cornerRadius: 20, tint: session.mode.accent)
    }
}

private struct EmptyHomeView: View {
    var onCreate: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("🐾").font(.system(size: 54))
            Text("Aucune partie pour l'instant")
                .font(.title3.bold())
            Text("Crée une partie et invite tes amis, ou rejoins-en une avec un code.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Créer ma première partie", action: onCreate)
                .buttonStyle(PillButtonStyle(gradient: GameMode.doggo.gradient))
                .padding(.top, 6)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .cardSurface()
    }
}

private struct HomeActionBar: View {
    var onCreate: () -> Void
    var onJoin: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onCreate) {
                Label("Créer", systemImage: "plus")
            }
            .buttonStyle(PillButtonStyle(gradient: GameMode.doggo.gradient))

            Button(action: onJoin) {
                Label("Rejoindre", systemImage: "qrcode")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .glassSurface(cornerRadius: 27, interactive: true)
            }
            .buttonStyle(PressableStyle(scale: 0.96))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(maxWidth: 560)
    }
}
