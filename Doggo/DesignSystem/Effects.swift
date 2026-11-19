//
//  Effects.swift
//  Doggo
//

import SwiftUI

// MARK: - Explosion d'emojis à chaque point

/// Fait jaillir quelques emojis au-dessus de la vue à chaque incrément de `trigger`.
struct EmojiBurstModifier: ViewModifier {
    let trigger: Int
    let emojis: [String]

    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        let emoji: String
        let dx: CGFloat
        let rise: CGFloat
        let rotation: Double
        let delay: Double
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    ForEach(particles) { particle in
                        FlyingEmoji(particle: particle)
                    }
                }
                .allowsHitTesting(false)
            }
            .onChange(of: trigger) { _, _ in
                let new = (0..<7).map { index in
                    Particle(
                        emoji: emojis.randomElement() ?? "🐾",
                        dx: .random(in: -110...110),
                        rise: .random(in: 90...190),
                        rotation: .random(in: -50...50),
                        delay: Double(index) * 0.025
                    )
                }
                particles.append(contentsOf: new)
                let ids = Set(new.map(\.id))
                Task {
                    try? await Task.sleep(for: .seconds(1.3))
                    particles.removeAll { ids.contains($0.id) }
                }
            }
    }

    private struct FlyingEmoji: View {
        let particle: Particle
        @State private var launched = false

        var body: some View {
            Text(particle.emoji)
                .font(.system(size: 30))
                .scaleEffect(launched ? 1.15 : 0.3)
                .rotationEffect(.degrees(launched ? particle.rotation : 0))
                .offset(x: launched ? particle.dx : 0, y: launched ? -particle.rise : 0)
                .opacity(launched ? 0 : 1)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.1).delay(particle.delay)) { launched = true }
                }
        }
    }
}

extension View {
    func emojiBurst(trigger: Int, emojis: [String]) -> some View {
        modifier(EmojiBurstModifier(trigger: trigger, emojis: emojis))
    }
}

// MARK: - Confettis

struct ConfettiView: View {
    var colors: [Color] = [Theme.gold, Theme.doggo, Theme.gato, Color(hex: 0x7ED69B), Color(hex: 0x6FB7F5), Color(hex: 0xF58FA8)]

    private struct Piece {
        let x: CGFloat
        let speed: CGFloat
        let sway: CGFloat
        let spin: Double
        let size: CGSize
        let color: Int
        let delay: Double
    }

    @State private var start = Date()
    @State private var pieces: [Piece] = (0..<110).map { _ in
        Piece(
            x: .random(in: 0...1),
            speed: .random(in: 160...320),
            sway: .random(in: 10...40),
            spin: .random(in: 2...7),
            size: CGSize(width: .random(in: 6...11), height: .random(in: 10...16)),
            color: .random(in: 0..<6),
            delay: .random(in: 0...1.6)
        )
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(start)
                for piece in pieces {
                    let t = elapsed - piece.delay
                    guard t > 0 else { continue }
                    let y = -20 + CGFloat(t) * piece.speed
                    guard y < size.height + 30 else { continue }
                    let x = piece.x * size.width + sin(CGFloat(t) * 3 + piece.x * 10) * piece.sway
                    var copy = context
                    copy.translateBy(x: x, y: y)
                    copy.rotate(by: .radians(t * piece.spin))
                    let rect = CGRect(x: -piece.size.width / 2, y: -piece.size.height / 2, width: piece.size.width, height: piece.size.height)
                    copy.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(colors[piece.color % colors.count]))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
