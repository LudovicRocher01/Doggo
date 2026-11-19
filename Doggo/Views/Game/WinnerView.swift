//
//  WinnerView.swift
//  Doggo
//

import SwiftUI

/// Résultats d'une partie terminée : vainqueur, podium, revanche.
struct WinnerView: View {
    let session: Session
    let model: GameModel
    @Environment(AppModel.self) private var app

    @State private var appeared = false
    @State private var showConfetti = true
    @State private var isCreatingRematch = false

    private var winner: PlayerStanding? {
        session.standings.first { $0.id == session.winnerID }
    }

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                if let winner {
                    Text("👑").font(.system(size: 40))
                        .offset(y: appeared ? 0 : -30)
                        .opacity(appeared ? 1 : 0)
                    AvatarView(emoji: winner.member.emoji, id: winner.id, size: 110)
                        .scaleEffect(appeared ? 1 : 0.3)
                    Text(winner.id == model.me ? "Tu as gagné !" : "\(winner.member.name) a gagné !")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("avec \(winner.score.pointsLabel)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("🤝").font(.system(size: 80)).scaleEffect(appeared ? 1 : 0.3)
                    Text("Égalité !").font(.largeTitle.bold())
                }
            }

            Podium(standings: Array(session.standings.prefix(3)), mode: session.mode, appeared: appeared)

            if session.standings.count > 3 {
                VStack(spacing: 8) {
                    ForEach(session.standings.dropFirst(3)) { standing in
                        HStack {
                            Text("\(standing.rank)").foregroundStyle(.secondary).frame(width: 24)
                            AvatarView(emoji: standing.member.emoji, id: standing.id, size: 30)
                            Text(standing.member.name)
                            Spacer()
                            Text("\(standing.score)").font(.headline)
                        }
                    }
                }
                .padding(16)
                .cardSurface(cornerRadius: 20)
            }

            Button {
                Task {
                    isCreatingRematch = true
                    if let id = await model.rematch() { app.open(id) }
                    isCreatingRematch = false
                }
            } label: {
                if isCreatingRematch { ProgressView().tint(.white) } else { Label("Revanche !", systemImage: "arrow.clockwise") }
            }
            .buttonStyle(PillButtonStyle(gradient: session.mode.gradient))
            .disabled(isCreatingRematch)

            if let finished = session.finishedAt {
                Text("Partie terminée le \(finished.formatted(date: .long, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .cardSurface(cornerRadius: 30)
        .overlay {
            if showConfetti { ConfettiView().frame(height: 700).offset(y: -200) }
        }
        .onAppear {
            Feedback.shared.success()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.15)) { appeared = true }
            Task {
                try? await Task.sleep(for: .seconds(5))
                withAnimation { showConfetti = false }
            }
        }
    }
}

private struct Podium: View {
    let standings: [PlayerStanding]
    let mode: GameMode
    let appeared: Bool

    /// Ordre d'affichage : 2e, 1er, 3e.
    private var arranged: [(standing: PlayerStanding, place: Int)] {
        let indexed = standings.enumerated().map { ($0.element, $0.offset) }
        let order = [1, 0, 2]
        return order.compactMap { index in indexed.first { $0.1 == index } }.map { ($0.0, $0.1) }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(arranged, id: \.standing.id) { item in
                VStack(spacing: 6) {
                    AvatarView(emoji: item.standing.member.emoji, id: item.standing.id, size: item.place == 0 ? 54 : 44)
                    Text(item.standing.member.name)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(mode.gradient.opacity(item.place == 0 ? 1 : 0.6))
                        .frame(height: appeared ? height(for: item.place) : 10)
                        .overlay(alignment: .top) {
                            VStack(spacing: 0) {
                                Text(["🥇", "🥈", "🥉"][item.place]).font(.title2)
                                Text("\(item.standing.score)").font(.headline).foregroundStyle(.white)
                            }
                            .padding(.top, 8)
                            .opacity(appeared ? 1 : 0)
                        }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 220, alignment: .bottom)
    }

    private func height(for place: Int) -> CGFloat {
        [130, 95, 70][place]
    }
}
