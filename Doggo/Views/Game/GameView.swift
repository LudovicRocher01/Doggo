//
//  GameView.swift
//  Doggo
//

import SwiftUI

struct GameView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var model: GameModel

    @State private var showInvite = false
    @State private var showStats = false
    @State private var showHistory = false
    @State private var confirmLeave = false
    @State private var confirmFinish = false

    init(sessionID: String) {
        _model = State(initialValue: GameModel(sessionID: sessionID))
    }

    var body: some View {
        Group {
            if let session = model.session {
                content(session)
            } else if model.wasDeleted {
                ContentUnavailableView("Partie supprimée", systemImage: "trash", description: Text("L'hôte a supprimé cette partie."))
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            model.start()
            #if DEBUG
            switch UserDefaults.standard.string(forKey: "DoggoDemoSheet") {
            case "invite": showInvite = true
            case "stats": showStats = true
            case "history": showHistory = true
            case "live": if let session = model.session { LiveActivityManager.start(session, myID: model.me) }
            default: break
            }
            #endif
        }
        .onDisappear { model.stop() }
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: DemoDirector.notification)) { note in
            guard let command = note.object as? DemoDirector.Command else { return }
            switch command {
            case .score(let id): model.score(id)
            case .remote(let id): model.demoRemoteScore(id)
            case .sheet(let name):
                showInvite = name == "invite"
                showStats = name == "stats"
                showHistory = name == "history"
            case .dismissSheets:
                showInvite = false
                showStats = false
                showHistory = false
            }
        }
        #endif
        .onChange(of: model.wasDeleted) { _, deleted in
            if deleted { Task { try? await Task.sleep(for: .seconds(1.2)); dismiss() } }
        }
        .alert("Oups", isPresented: .constant(model.errorMessage != nil)) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func content(_ session: Session) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                GameHeader(session: session)

                if session.isFinished {
                    WinnerView(session: session, model: model)
                } else {
                    if model.isCreator && !session.requestIDs.isEmpty {
                        RequestsCard(session: session, model: model)
                    }

                    if session.memberIDs.count < 2 {
                        InvitePrompt(mode: session.mode) { showInvite = true }
                    }

                    PlayersGrid(session: session, model: model)

                    Text("Tape sur la carte de celui qui a crié « \(session.mode.shout) » en premier.\nAppui long pour annuler.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if !model.events.isEmpty {
                    HistoryPreview(model: model) { showHistory = true }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .top) {
            if let banner = model.banner {
                ScoreBanner(banner: banner, accent: session.mode.accent)
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .id(banner.id)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: model.banner)
        .navigationTitle(session.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar { toolbar(session) }
        .tint(session.mode.accent)
        .sheet(isPresented: $showInvite) { InviteSheet(session: session) }
        .sheet(isPresented: $showStats) { StatsView(session: session) }
        .sheet(isPresented: $showHistory) { HistoryView(model: model) }
        .confirmationDialog(
            model.isCreator ? "Supprimer la partie pour tout le monde ?" : "Quitter la partie ?",
            isPresented: $confirmLeave,
            titleVisibility: .visible
        ) {
            Button(model.isCreator ? "Supprimer la partie" : "Quitter la partie", role: .destructive) {
                Task { if await model.leaveOrDelete() { dismiss() } }
            }
        } message: {
            Text(model.isCreator ? "Les scores et l'historique seront définitivement effacés." : "Tes points dans cette partie seront perdus.")
        }
        .confirmationDialog("Terminer la partie maintenant ?", isPresented: $confirmFinish, titleVisibility: .visible) {
            Button("Terminer et désigner le vainqueur") { Task { await model.finishNow() } }
        } message: {
            Text("Le joueur en tête remporte la partie. Les points ne pourront plus être modifiés.")
        }
        .onAppear { if !session.isFinished { app.activeSessionID = session.sessionID } }
    }

    @ToolbarContentBuilder
    private func toolbar(_ session: Session) -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if !session.isFinished {
                Button { showInvite = true } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                }
                .accessibilityLabel("Inviter des amis")
            }
            Menu {
                Button { showStats = true } label: { Label("Statistiques", systemImage: "chart.bar.xaxis") }
                Button { showHistory = true } label: { Label("Historique", systemImage: "clock.arrow.circlepath") }
                if !session.isFinished {
                    GameExtraMenuItems(session: session)
                    if model.isCreator {
                        Divider()
                        Button { confirmFinish = true } label: { Label("Terminer la partie", systemImage: "flag.checkered") }
                    }
                }
                Divider()
                Button(role: .destructive) { confirmLeave = true } label: {
                    Label(model.isCreator ? "Supprimer la partie" : "Quitter la partie",
                          systemImage: model.isCreator ? "trash" : "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("Options")
        }
    }
}

// MARK: - En-tête

private struct GameHeader: View {
    let session: Session

    var body: some View {
        ZStack(alignment: .bottom) {
            IllustrationBanner(imageName: session.mode.backgroundImage, height: 200)
                .overlay {
                    LinearGradient(colors: [.clear, .clear, Theme.background.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                }
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    ModeBadge(mode: session.mode)
                    Text(session.displayName)
                        .font(.title.bold())
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(session.totalPoints)")
                        .font(.title2.bold())
                        .contentTransition(.numericText())
                        .animation(.snappy, value: session.totalPoints)
                    Text(session.totalPoints > 1 ? "\(session.mode.animalPlural) repérés" : "\(session.mode.animal) repéré")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .overlay(alignment: .topLeading) {
            if let target = session.targetScore, !session.isFinished {
                Label("Objectif \(target)", systemImage: "flag.checkered")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassSurface(cornerRadius: 14)
                    .padding(12)
            }
        }
    }
}

// MARK: - Joueurs

private struct PlayersGrid: View {
    let session: Session
    let model: GameModel

    var body: some View {
        let standings = session.standings
        let columns = [GridItem(.adaptive(minimum: standings.count <= 2 ? 150 : 155), spacing: 12)]
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(standings) { standing in
                PlayerCard(
                    standing: standing,
                    session: session,
                    isMe: standing.id == model.me,
                    isSoleLeader: session.soleLeaderID == standing.id,
                    burst: model.bursts[standing.id] ?? 0,
                    canUndo: model.lastEvent(for: standing.id) != nil,
                    onScore: { model.score(standing.id) },
                    onUndo: { Task { await model.undoLast(for: standing.id) } }
                )
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: standings.map(\.id))
    }
}

private struct PlayerCard: View {
    let standing: PlayerStanding
    let session: Session
    let isMe: Bool
    let isSoleLeader: Bool
    let burst: Int
    let canUndo: Bool
    var onScore: () -> Void
    var onUndo: () -> Void

    @State private var bounce = false

    var body: some View {
        Button(action: onScore) {
            VStack(spacing: 10) {
                HStack(alignment: .top) {
                    AvatarView(emoji: standing.member.emoji, id: standing.id, size: 52)
                        .overlay(alignment: .top) {
                            if isSoleLeader {
                                Text("👑")
                                    .font(.system(size: 22))
                                    .offset(y: -18)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    Spacer()
                    if let medal = Theme.medal(for: standing.rank), standing.score > 0 {
                        Text("\(standing.rank)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(medal, in: Circle())
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Text(standing.member.name)
                            .font(.headline)
                            .lineLimit(1)
                        if isMe {
                            Text("toi")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(session.mode.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(session.mode.accentSoft, in: Capsule())
                        }
                    }
                    Text("\(standing.score)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(session.mode.accent)
                        .contentTransition(.numericText(value: Double(standing.score)))
                        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: standing.score)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let target = session.targetScore {
                    ProgressView(value: Double(min(standing.score, target)), total: Double(target))
                        .tint(session.mode.accent)
                }

                Text(session.mode.shout)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .background(session.mode.gradient, in: Capsule())
            }
            .padding(14)
            .cardSurface(cornerRadius: 26)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(isSoleLeader ? Theme.gold.opacity(0.8) : .clear, lineWidth: 2)
            )
            .scaleEffect(bounce ? 1.05 : 1)
            .emojiBurst(trigger: burst, emojis: session.mode.burstEmojis)
        }
        .buttonStyle(PressableStyle(scale: 0.94))
        .contextMenu {
            Button(role: .destructive, action: onUndo) {
                Label("Annuler le dernier point de \(standing.member.name)", systemImage: "arrow.uturn.backward")
            }
            .disabled(!canUndo)
        }
        .onChange(of: burst) { _, _ in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { bounce = true }
            Task {
                try? await Task.sleep(for: .milliseconds(160))
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { bounce = false }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(standing.member.name)\(isMe ? ", toi" : ""), \(standing.score.pointsLabel)")
        .accessibilityHint("Touche deux fois pour lui donner un point")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Annuler son dernier point", onUndo)
    }
}

// MARK: - Demandes

private struct RequestsCard: View {
    let session: Session
    let model: GameModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Demandes pour rejoindre", systemImage: "person.badge.clock")
                .font(.headline)
            ForEach(session.requestIDs, id: \.self) { id in
                if let member = session.requests[id] {
                    HStack(spacing: 12) {
                        AvatarView(emoji: member.emoji, id: id, size: 40)
                        Text(member.name).font(.body.weight(.semibold))
                        Spacer()
                        Button {
                            Task { await model.reject(id) }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.bold())
                                .frame(width: 40, height: 40)
                                .background(Color.red.opacity(0.14), in: Circle())
                                .foregroundStyle(.red)
                        }
                        .accessibilityLabel("Refuser \(member.name)")
                        Button {
                            Task { await model.accept(id) }
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.body.bold())
                                .frame(width: 40, height: 40)
                                .background(Color.green.opacity(0.18), in: Circle())
                                .foregroundStyle(.green)
                        }
                        .accessibilityLabel("Accepter \(member.name)")
                    }
                    .buttonStyle(PressableStyle(scale: 0.88))
                }
            }
        }
        .padding(16)
        .glassSurface(cornerRadius: 24, tint: session.mode.accent)
        .transition(.scale(scale: 0.95).combined(with: .opacity))
    }
}

private struct InvitePrompt: View {
    let mode: GameMode
    var onInvite: () -> Void

    var body: some View {
        Button(action: onInvite) {
            HStack(spacing: 14) {
                Text("👋").font(.largeTitle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Invite ta bande").font(.headline)
                    Text("Partage le code ou le QR code de la partie.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(16)
            .glassSurface(cornerRadius: 22, tint: mode.accent)
        }
        .buttonStyle(PressableStyle(scale: 0.97))
        .foregroundStyle(.primary)
    }
}

// MARK: - Bannière

private struct ScoreBanner: View {
    let banner: GameModel.Banner
    let accent: Color

    var body: some View {
        HStack(spacing: 10) {
            Text(banner.emoji).font(.title2)
            Text(banner.text)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .glassSurface(cornerRadius: 26, tint: accent)
        .padding(.horizontal, 24)
        .accessibilityAddTraits(.updatesFrequently)
    }
}
