//
//  Components.swift
//  Doggo
//

import SwiftUI

// MARK: - Surfaces

extension View {
    /// Surface flottante : Liquid Glass sur iOS 26, matériau translucide sinon.
    @ViewBuilder
    func glassSurface(cornerRadius: CGFloat = 24, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(tint?.opacity(0.35)).interactive(interactive), in: .rect(cornerRadius: cornerRadius))
        } else {
            self.background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        if let tint {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(tint.opacity(0.18))
                        }
                    }
                    .shadow(color: .black.opacity(0.10), radius: 16, y: 6)
            }
        }
    }

    /// Carte pleine, utilisée pour le contenu (parties, joueurs, stats).
    func cardSurface(cornerRadius: CGFloat = 24) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).strokeBorder(Theme.cardStroke))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        }
    }
}

// MARK: - Boutons

struct PillButtonStyle: ButtonStyle {
    var fill: AnyShapeStyle
    var foreground: Color = .white

    init(_ color: Color, foreground: Color = .white) {
        fill = AnyShapeStyle(color)
        self.foreground = foreground
    }

    init(gradient: LinearGradient) {
        fill = AnyShapeStyle(gradient)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(fill, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Effet « ressort » pour les éléments tapables.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

// MARK: - Avatars

struct AvatarView: View {
    let emoji: String
    let id: String
    var size: CGFloat = 44

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.55))
            .frame(width: size, height: size)
            .background(Theme.color(for: id).opacity(0.28), in: Circle())
            .overlay(Circle().strokeBorder(Theme.color(for: id).opacity(0.6), lineWidth: max(1, size / 22)))
            .accessibilityHidden(true)
    }
}

struct AvatarStack: View {
    let members: [(id: String, member: Member)]
    var size: CGFloat = 30
    var maxVisible = 4

    var body: some View {
        HStack(spacing: -size * 0.3) {
            ForEach(Array(members.prefix(maxVisible).enumerated()), id: \.offset) { _, item in
                AvatarView(emoji: item.member.emoji, id: item.id, size: size)
                    .background(Theme.card, in: Circle())
            }
            if members.count > maxVisible {
                Text("+\(members.count - maxVisible)")
                    .font(.caption.bold())
                    .frame(width: size, height: size)
                    .background(Color.secondary.opacity(0.2), in: Circle())
            }
        }
    }
}

// MARK: - Illustrations

/// Affiche une illustration portrait (2:3) dans un bandeau, cadrée sur le visage de l'animal.
struct IllustrationBanner: View {
    let imageName: String
    var height: CGFloat = 200
    /// Position verticale (0…1) du point de l'image à placer au centre du bandeau.
    var focusY: CGFloat = 0.36

    var body: some View {
        Color.clear
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                GeometryReader { geo in
                    let imageHeight = geo.size.width * 1.5
                    let offset = min(0, max(height - imageHeight, height / 2 - imageHeight * focusY))
                    Image(imageName)
                        .resizable()
                        .frame(width: geo.size.width, height: imageHeight)
                        .offset(y: offset)
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }
}

// MARK: - Mascotte

struct MascotView: View {
    var size: CGFloat = 120

    var body: some View {
        Image("Mascot")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: size / 30))
            .shadow(color: Theme.doggo.opacity(0.3), radius: size / 8, y: size / 20)
            .accessibilityHidden(true)
    }
}

// MARK: - Divers

struct ModeBadge: View {
    let mode: GameMode

    var body: some View {
        Text("\(mode.emoji) \(mode.title)")
            .font(.caption.weight(.bold))
            .foregroundStyle(mode.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(mode.accentSoft, in: Capsule())
            .background(Theme.card, in: Capsule())
    }
}

struct SectionTitle: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title3.bold())
            Spacer()
            if let trailing {
                Text(trailing).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

extension Int {
    var pointsLabel: String { self > 1 || self < -1 ? "\(self) points" : "\(self) point" }
}
