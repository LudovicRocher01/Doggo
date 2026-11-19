//
//  DoggoLiveActivity.swift
//  DoggoWidgets
//
//  Écran verrouillé + Dynamic Island : un bouton par joueur pour marquer sans déverrouiller.
//

import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

private extension DoggoActivityAttributes {
    var accent: Color {
        isGato ? Color(red: 0.46, green: 0.34, blue: 0.84) : Color(red: 0.91, green: 0.53, blue: 0.16)
    }
}

struct DoggoLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DoggoActivityAttributes.self) { context in
            LockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.35))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let attributes = context.attributes
            let state = context.state
            let me = state.players.first { $0.id == attributes.myID }
            let leader = state.players.first

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(attributes.sessionName).font(.caption.weight(.semibold)).lineLimit(1)
                    } icon: {
                        Text(attributes.emoji)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let leader, leader.score > 0 {
                        Text("👑 \(leader.emoji) \(leader.score)")
                            .font(.caption.weight(.bold))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    PlayerButtons(attributes: attributes, state: state, compact: true)
                }
            } compactLeading: {
                Text(attributes.emoji)
            } compactTrailing: {
                Text("\(me?.score ?? 0)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(attributes.accent)
                    .contentTransition(.numericText())
            } minimal: {
                Text(attributes.emoji)
            }
            .keylineTint(attributes.accent)
        }
    }
}

private struct LockScreenView: View {
    let attributes: DoggoActivityAttributes
    let state: DoggoActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(attributes.emoji).font(.title3)
                Text(attributes.sessionName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if state.isFinished {
                    Text("Partie terminée").font(.caption.weight(.semibold))
                } else if let target = state.targetScore {
                    Text("Objectif \(target)").font(.caption.weight(.semibold)).opacity(0.8)
                }
            }
            .foregroundStyle(.white)

            PlayerButtons(attributes: attributes, state: state, compact: false)
        }
        .padding(16)
    }
}

private struct PlayerButtons: View {
    let attributes: DoggoActivityAttributes
    let state: DoggoActivityAttributes.ContentState
    let compact: Bool

    var body: some View {
        HStack(spacing: 8) {
            ForEach(state.players.prefix(4)) { player in
                Button(intent: ScorePlayerIntent(sessionID: attributes.sessionID, playerID: player.id)) {
                    VStack(spacing: 2) {
                        Text(player.emoji).font(compact ? .body : .title3)
                        Text("\(player.score)")
                            .font((compact ? Font.subheadline : .title3).weight(.heavy).monospacedDigit())
                            .contentTransition(.numericText())
                        Text(player.id == attributes.myID ? "Moi" : player.name)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, compact ? 4 : 8)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(attributes.accent.opacity(player.id == state.lastScorerID ? 0.95 : 0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.white.opacity(player.id == attributes.myID ? 0.8 : 0), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .disabled(state.isFinished)
                .accessibilityLabel("Un point pour \(player.name), actuellement \(player.score)")
            }
        }
    }
}
