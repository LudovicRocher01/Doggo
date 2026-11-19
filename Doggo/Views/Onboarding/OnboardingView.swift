//
//  OnboardingView.swift
//  Doggo
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var app
    @State private var page = 0
    @State private var profile = PlayerProfile(name: "", emoji: "🐶")

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            TabView(selection: $page) {
                WelcomePage { withAnimation { page = 1 } }
                    .tag(0)
                VStack {
                    Spacer(minLength: 24)
                    Text("Ton profil")
                        .font(.largeTitle.bold())
                    Text("Tes amis te verront comme ça dans les parties.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    ProfileEditor(profile: $profile)
                        .padding(.top, 8)
                    Spacer(minLength: 16)
                    Button("C'est parti !") {
                        Feedback.shared.success()
                        app.saveProfile(profile)
                    }
                    .buttonStyle(PillButtonStyle(gradient: GameMode.doggo.gradient))
                    .disabled(profile.name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(profile.name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .frame(maxWidth: 520)
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .onChange(of: app.suggestedName, initial: true) { _, name in
            // Joueur de la v1 : on reprend le nom déjà utilisé dans ses parties.
            if profile.name.isEmpty, let name { profile.name = name }
        }
    }
}

private struct WelcomePage: View {
    var onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            MascotView(size: 150)
                .scaleEffect(appeared ? 1 : 0.6)
                .rotationEffect(.degrees(appeared ? 0 : -12))
            Text("Bienvenue dans Doggo")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 16) {
                RuleRow(emoji: "👀", title: "Repère un chien (ou un chat)", detail: "Dans la rue, au parc, à la fenêtre…")
                RuleRow(emoji: "🗣️", title: "Crie « Doggo ! » le premier", detail: "Ou « Gato ! » pour les chats.")
                RuleRow(emoji: "🏆", title: "Marque le point", detail: "Un tap dans l'app, et toute la bande voit le score en direct.")
            }
            .padding(20)
            .cardSurface()
            Spacer()
            Button("Continuer", action: onContinue)
                .buttonStyle(PillButtonStyle(gradient: GameMode.doggo.gradient))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .frame(maxWidth: 520)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.1)) { appeared = true }
        }
    }
}

private struct RuleRow: View {
    let emoji: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(emoji).font(.title)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

/// Saisie du nom et choix de l'avatar (onboarding et profil).
struct ProfileEditor: View {
    @Binding var profile: PlayerProfile
    @FocusState private var nameFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(spacing: 20) {
            AvatarView(emoji: profile.emoji, id: Identity.playerID, size: 96)
                .contentTransition(.symbolEffect)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: profile.emoji)

            TextField("Ton prénom", text: $profile.name)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .textContentType(.givenName)
                .submitLabel(.done)
                .focused($nameFocused)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .cardSurface(cornerRadius: 18)
                .onChange(of: profile.name) { _, value in
                    if value.count > 20 { profile.name = String(value.prefix(20)) }
                }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(PlayerProfile.avatarChoices, id: \.self) { emoji in
                    Button {
                        Feedback.shared.tap()
                        profile.emoji = emoji
                    } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(profile.emoji == emoji ? Theme.doggo.opacity(0.22) : Color.primary.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(profile.emoji == emoji ? Theme.doggo : .clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(PressableStyle(scale: 0.88))
                    .accessibilityLabel("Avatar \(emoji)")
                    .accessibilityAddTraits(profile.emoji == emoji ? .isSelected : [])
                }
            }
        }
    }
}
