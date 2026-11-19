//
//  JoinGameSheet.swift
//  Doggo
//

import SwiftUI

struct JoinGameSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var initialCode: String = ""

    private enum Step: Equatable {
        case enterCode
        case preview(Session)
        case sent(Session)
    }

    @State private var code = ""
    @State private var step: Step = .enterCode
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var codeFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                switch step {
                case .enterCode:
                    codeEntry
                case .preview(let session):
                    preview(session)
                case .sent(let session):
                    sent(session)
                }
            }
            .padding(20)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.background.ignoresSafeArea())
            .animation(.snappy, value: step)
            .navigationTitle("Rejoindre une partie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isSent ? "Fermer" : "Annuler") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            code = initialCode
            if !initialCode.isEmpty {
                Task { await lookup() }
            } else {
                codeFocused = true
            }
        }
    }

    private var isSent: Bool {
        if case .sent = step { return true }
        return false
    }

    // MARK: - Étapes

    private var codeEntry: some View {
        VStack(spacing: 16) {
            Text("Demande le code à l'hôte, ou scanne son QR code avec l'appareil photo.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("WOOF42", text: $code)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($codeFocused)
                .submitLabel(.go)
                .onSubmit { Task { await lookup() } }
                .padding(.vertical, 18)
                .cardSurface(cornerRadius: 20)
                .onChange(of: code) { _, value in
                    // Les codes courts sont en majuscules ; les anciens IDs (v1) sont laissés tels quels.
                    if value.count <= CodeGenerator.length, value != value.uppercased() { code = value.uppercased() }
                }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }

            Button {
                Task { await lookup() }
            } label: {
                if isLoading { ProgressView().tint(.white) } else { Text("Chercher la partie") }
            }
            .buttonStyle(PillButtonStyle(gradient: GameMode.doggo.gradient))
            .disabled(code.trimmingCharacters(in: .whitespaces).count < 4 || isLoading)
        }
    }

    private func preview(_ session: Session) -> some View {
        VStack(spacing: 18) {
            IllustrationBanner(imageName: session.mode.backgroundImage, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(spacing: 6) {
                ModeBadge(mode: session.mode)
                Text(session.displayName).font(.title2.bold())
                if let host = session.members[session.creatorID] {
                    Text("Créée par \(host.emoji) \(host.name)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                AvatarStack(members: session.standings.map { ($0.id, $0.member) }, size: 34, maxVisible: 6)
                    .padding(.top, 4)
                if let target = session.targetScore {
                    Text("Objectif : \(target) points").font(.footnote).foregroundStyle(.secondary)
                }
            }

            if let errorMessage {
                Text(errorMessage).font(.subheadline).foregroundStyle(.red)
            }

            Button {
                Task { await sendRequest(to: session) }
            } label: {
                if isLoading { ProgressView().tint(.white) } else { Text("Demander à rejoindre") }
            }
            .buttonStyle(PillButtonStyle(gradient: session.mode.gradient))
            .disabled(isLoading)

            Button("Changer de code") {
                errorMessage = nil
                step = .enterCode
            }
            .font(.subheadline)
        }
    }

    private func sent(_ session: Session) -> some View {
        VStack(spacing: 14) {
            Text("📨").font(.system(size: 64))
            Text("Demande envoyée !").font(.title2.bold())
            Text("Dès que l'hôte t'accepte, la partie « \(session.displayName) » apparaîtra sur ton écran d'accueil.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Super") { dismiss() }
                .buttonStyle(PillButtonStyle(gradient: session.mode.gradient))
                .padding(.top, 8)
        }
        .padding(.top, 20)
    }

    // MARK: - Actions

    private func lookup() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await app.repository.findSession(code: code)
            if session.memberIDs.contains(app.playerID) {
                dismiss()
                app.open(session.sessionID)
                return
            }
            step = .preview(session)
        } catch {
            Feedback.shared.warning()
            errorMessage = (error as? RepositoryError)?.errorDescription ?? "Partie introuvable. Vérifie le code et ta connexion."
        }
    }

    private func sendRequest(to session: Session) async {
        guard let profile = app.profile else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await app.repository.requestToJoin(session, playerID: app.playerID, member: profile.member)
            Feedback.shared.success()
            step = .sent(session)
        } catch RepositoryError.alreadyRequested {
            step = .sent(session)
        } catch {
            errorMessage = (error as? RepositoryError)?.errorDescription ?? "Impossible d'envoyer la demande. Vérifie ta connexion."
        }
    }
}
