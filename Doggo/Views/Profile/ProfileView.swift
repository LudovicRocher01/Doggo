//
//  ProfileView.swift
//  Doggo
//

import SwiftUI
import AppIntents

struct ProfileView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var draft = PlayerProfile(name: "", emoji: "🐶")
    @AppStorage(Feedback.soundKey) private var soundEnabled = true
    @AppStorage(Feedback.hapticsKey) private var hapticsEnabled = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ProfileEditor(profile: $draft)

                    HStack(spacing: 12) {
                        StatTile(value: app.totalPoints(for: .doggo), label: "points Doggo", emoji: "🐶", color: Theme.doggo)
                        StatTile(value: app.totalPoints(for: .gato), label: "points Gato", emoji: "🐱", color: Theme.gato)
                        StatTile(value: app.wins, label: app.wins > 1 ? "victoires" : "victoire", emoji: "🏆", color: Theme.gold)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(title: "Marquer encore plus vite")
                        Text("Dis « Dis Siri, point Doggo » pour marquer un point dans ta partie active, ou associe le raccourci « Doggo ! » au bouton Action de ton iPhone (Réglages → Bouton Action → Raccourci).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        SiriTipView(intent: ScoreMyPointIntent())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 0) {
                        Toggle(isOn: $soundEnabled) { Label("Sons", systemImage: "speaker.wave.2.fill") }
                            .padding()
                        Divider().padding(.leading)
                        Toggle(isOn: $hapticsEnabled) { Label("Vibrations", systemImage: "iphone.radiowaves.left.and.right") }
                            .padding()
                    }
                    .cardSurface(cornerRadius: 18)

                    VStack(spacing: 0) {
                        Link(destination: URL(string: "https://github.com/LudovicRocher01/Doggo/blob/main/Confidentialit%C3%A9.md")!) {
                            LinkRow(title: "Confidentialité", icon: "hand.raised.fill")
                        }
                        Divider().padding(.leading)
                        Link(destination: URL(string: "https://github.com/LudovicRocher01/Doggo/blob/main/Support.md")!) {
                            LinkRow(title: "Support", icon: "questionmark.circle.fill")
                        }
                    }
                    .cardSurface(cornerRadius: 18)

                    Text("Doggo \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "") · fait avec 🐾")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        app.saveProfile(draft)
                        Feedback.shared.success()
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty || draft == app.profile)
                }
            }
        }
        .onAppear { if let profile = app.profile { draft = profile } }
    }
}

struct StatTile: View {
    let value: Int
    let label: String
    let emoji: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji).font(.title2)
            Text("\(value)")
                .font(.title.bold())
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardSurface(cornerRadius: 18)
    }
}

private struct LinkRow: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .padding()
    }
}
