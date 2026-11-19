//
//  HistoryView.swift
//  Doggo
//

import SwiftUI

/// Aperçu des derniers points sur l'écran de partie.
struct HistoryPreview: View {
    let model: GameModel
    var onShowAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Derniers points").font(.headline)
                Spacer()
                Button("Tout voir", action: onShowAll).font(.subheadline.weight(.semibold))
            }
            .padding(.bottom, 6)

            ForEach(model.events.prefix(4)) { event in
                EventRow(event: event, model: model)
                if event.id != model.events.prefix(4).last?.id { Divider() }
            }
        }
        .padding(16)
        .cardSurface()
    }
}

struct EventRow: View {
    let event: ScoreEvent
    let model: GameModel

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(emoji: model.member(event.playerID)?.emoji ?? model.mode.emoji, id: event.playerID, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(model.name(event.playerID)) +\(event.delta) \(model.mode.emoji)")
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(event.undone)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if event.undone {
                Text("annulé")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }
        }
        .padding(.vertical, 4)
        .opacity(event.undone ? 0.55 : 1)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let time = event.createdAt.formatted(.relative(presentation: .named))
        if event.byID == event.playerID { return time.capitalizedFirst }
        return "Par \(model.name(event.byID)) · \(time)"
    }
}

/// Historique complet, groupé par jour, avec annulation par balayage.
struct HistoryView: View {
    let model: GameModel
    @Environment(\.dismiss) private var dismiss

    private var days: [(day: Date, events: [ScoreEvent])] {
        let grouped = Dictionary(grouping: model.events) { Calendar.current.startOfDay(for: $0.createdAt) }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                if model.events.isEmpty {
                    ContentUnavailableView("Aucun point", systemImage: "pawprint", description: Text("Les points marqués apparaîtront ici."))
                }
                ForEach(days, id: \.day) { day in
                    Section {
                        ForEach(day.events) { event in
                            EventRow(event: event, model: model)
                                .swipeActions(edge: .trailing) {
                                    if !event.undone && model.session?.isFinished == false {
                                        Button("Annuler", role: .destructive) {
                                            Task { await model.undo(event) }
                                        }
                                    }
                                }
                        }
                    } header: {
                        HStack {
                            Text(day.day.formatted(.dateTime.weekday(.wide).day().month(.wide)).capitalizedFirst)
                            Spacer()
                            Text(day.events.filter { !$0.undone }.count.pointsLabel)
                        }
                    }
                }
            }
            .navigationTitle("Historique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("OK") { dismiss() } }
            }
        }
        .tint(model.mode.accent)
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
