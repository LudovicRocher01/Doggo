//
//  StatsView.swift
//  Doggo
//

import SwiftUI
import Charts

struct StatsView: View {
    let session: Session
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var stats: SessionStats?
    @State private var failed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let stats {
                    content(stats)
                } else if failed {
                    ContentUnavailableView("Stats indisponibles", systemImage: "wifi.slash", description: Text("Vérifie ta connexion."))
                } else {
                    ProgressView().padding(.top, 60)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Statistiques")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("OK") { dismiss() } }
            }
        }
        .tint(session.mode.accent)
        .task {
            #if DEBUG
            if DemoData.isDemo(session.sessionID) {
                stats = SessionStats(events: DemoData.events(for: session))
                return
            }
            #endif
            do {
                stats = SessionStats(events: try await app.repository.fetchAllEvents(session.sessionID))
            } catch {
                failed = true
            }
        }
    }

    private func name(_ id: String) -> String { session.members[id]?.name ?? "Ancien joueur" }

    /// Une couleur distincte par joueur présent dans le graphique (ordre du classement).
    private func chartNames(_ stats: SessionStats) -> [String] {
        let present = Set(stats.lastSevenDays.map(\.playerID))
        let ordered = session.standings.map(\.id).filter(present.contains) + present.subtracting(session.memberIDs).sorted()
        return ordered.map(name)
    }

    private func content(_ stats: SessionStats) -> some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                StatCard(emoji: session.mode.emoji, value: "\(stats.today)", label: "aujourd'hui", color: session.mode.accent)
                StatCard(emoji: "🔥", value: "\(stats.currentStreak) j", label: "série en cours", color: .orange)
                StatCard(emoji: "📅", value: stats.bestDay.map { "\($0.count)" } ?? "–",
                         label: stats.bestDay.map { "record, le \($0.day.formatted(.dateTime.day().month()))" } ?? "meilleure journée",
                         color: Theme.gold)
                StatCard(emoji: "🏅", value: "\(stats.longestStreak) j", label: "plus longue série", color: Theme.gato)
            }

            if !stats.lastSevenDays.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("7 derniers jours").font(.headline)
                    Chart(stats.lastSevenDays) { item in
                        BarMark(
                            x: .value("Jour", item.day, unit: .day),
                            y: .value("Points", item.count)
                        )
                        .foregroundStyle(by: .value("Joueur", name(item.playerID)))
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                        }
                    }
                    .chartForegroundStyleScale(
                        domain: chartNames(stats),
                        range: chartNames(stats).indices.map { Theme.avatarColors[$0 % Theme.avatarColors.count] }
                    )
                    .frame(height: 200)
                }
                .padding(16)
                .cardSurface()
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Classement").font(.headline)
                ForEach(session.standings) { standing in
                    HStack(spacing: 12) {
                        Text(standing.rank == 1 && standing.score > 0 ? "🥇" : standing.rank == 2 ? "🥈" : standing.rank == 3 ? "🥉" : "\(standing.rank)")
                            .frame(width: 28)
                        AvatarView(emoji: standing.member.emoji, id: standing.id, size: 34)
                        Text(standing.member.name).font(.subheadline.weight(.semibold))
                        Spacer()
                        if let today = stats.todayByPlayer[standing.id] {
                            Text("+\(today) auj.").font(.caption).foregroundStyle(.secondary)
                        }
                        Text("\(standing.score)").font(.headline).foregroundStyle(session.mode.accent)
                    }
                }
            }
            .padding(16)
            .cardSurface()

            VStack(alignment: .leading, spacing: 8) {
                if let hour = stats.favoriteHour {
                    Label("Heure de pointe : \(hour)h – \(hour + 1)h", systemImage: "clock")
                }
                Label("\(stats.activeDays) jour\(stats.activeDays > 1 ? "s" : "") de chasse", systemImage: "calendar")
                if let created = session.createdAt {
                    Label("Partie créée le \(created.formatted(date: .long, time: .omitted))", systemImage: "sparkles")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .cardSurface()

            Text("Les statistiques sont calculées depuis l'historique des points (disponible depuis la version 2.0).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
    }
}

private struct StatCard: View {
    let emoji: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(emoji).font(.title2)
            Text(value).font(.title.bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary).lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cardSurface(cornerRadius: 20)
    }
}
