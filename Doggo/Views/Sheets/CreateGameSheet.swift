//
//  CreateGameSheet.swift
//  Doggo
//

import SwiftUI

struct CreateGameSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var mode: GameMode = .doggo
    @State private var name = ""
    @State private var target: Int? = nil
    @State private var isCreating = false
    @State private var errorMessage: String?

    private let targets: [Int?] = [nil, 10, 25, 50, 100]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Qu'est-ce qu'on chasse ?").font(.headline)
                        HStack(spacing: 12) {
                            ForEach(GameMode.allCases) { option in
                                ModeChoiceCard(mode: option, isSelected: mode == option) {
                                    Feedback.shared.tap()
                                    withAnimation(.snappy) { mode = option }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nom de la partie").font(.headline)
                        TextField("Ex. Les colocs, Vacances 2026…", text: $name)
                            .padding(14)
                            .cardSurface(cornerRadius: 16)
                            .submitLabel(.done)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Objectif").font(.headline)
                        Text("Le premier à atteindre l'objectif gagne la partie.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            ForEach(targets, id: \.self) { value in
                                Button {
                                    Feedback.shared.tap()
                                    target = value
                                } label: {
                                    Text(value.map { "\($0)" } ?? "Libre")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                        .foregroundStyle(target == value ? .white : .primary)
                                        .background(
                                            Capsule().fill(target == value ? AnyShapeStyle(mode.gradient) : AnyShapeStyle(Color.primary.opacity(0.06)))
                                        )
                                }
                                .buttonStyle(PressableStyle(scale: 0.9))
                            }
                        }
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task { await create() }
                } label: {
                    if isCreating {
                        ProgressView().tint(.white)
                    } else {
                        Text("Créer la partie \(mode.emoji)")
                    }
                }
                .buttonStyle(PillButtonStyle(gradient: mode.gradient))
                .disabled(isCreating)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .navigationTitle("Nouvelle partie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
            .alert("Oups", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .presentationDetents([.large])
        .tint(mode.accent)
    }

    private func create() async {
        guard let profile = app.profile else { return }
        isCreating = true
        defer { isCreating = false }
        do {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let session = try await app.repository.createSession(
                mode: mode,
                name: trimmed.isEmpty ? nil : String(trimmed.prefix(40)),
                targetScore: target,
                creatorID: app.playerID,
                members: [app.playerID: profile.member]
            )
            Feedback.shared.success()
            app.activeSessionID = session.sessionID
            dismiss()
            app.open(session.sessionID)
        } catch {
            errorMessage = (error as? RepositoryError)?.errorDescription
                ?? "Impossible de créer la partie. Vérifie ta connexion internet."
        }
    }
}

private struct ModeChoiceCard: View {
    let mode: GameMode
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                IllustrationBanner(imageName: mode.backgroundImage, height: 130, focusY: 0.38)
                HStack {
                    Text("\(mode.emoji) \(mode.title)").font(.headline)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? mode.accent : .secondary)
                        .font(.title3)
                }
                .padding(12)
                .background(Theme.card)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? mode.accent : Theme.cardStroke, lineWidth: isSelected ? 3 : 1)
            )
            .shadow(color: isSelected ? mode.accent.opacity(0.3) : .black.opacity(0.05), radius: 10, y: 4)
            .scaleEffect(isSelected ? 1 : 0.97)
        }
        .buttonStyle(PressableStyle())
        .foregroundStyle(.primary)
        .accessibilityLabel("Mode \(mode.title), on compte les \(mode.animalPlural)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
