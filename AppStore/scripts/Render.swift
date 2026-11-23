//
//  Render.swift — génère les visuels App Store de Doggo.
//
//  swiftc -O -parse-as-library AppStore/scripts/Render.swift -o /tmp/doggo-render
//  /tmp/doggo-render <dossier_captures_brutes> <dossier_assets_xcassets> <dossier_sortie> [iphone|ipad|banners]
//
//  Les captures brutes sont faites dans le simulateur en mode démo (voir AppStore/README.md).
//

import AppKit
import SwiftUI

// MARK: - Palette

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

enum Palette {
    static let cream = Color(hex: 0xFFF7EC)
    static let ink = Color(hex: 0x3B2416)
    static let caramelLight = Color(hex: 0xF7B35C)
    static let caramel = Color(hex: 0xE8862A)
    static let caramelDark = Color(hex: 0xC9661A)
    static let lavenderLight = Color(hex: 0xA48CF5)
    static let lavender = Color(hex: 0x6C4FD0)
    static let sky = Color(hex: 0x8FD3F0)
    static let skyDark = Color(hex: 0x4FA9D9)
    static let gold = Color(hex: 0xF5B82E)
    static let night = Color(hex: 0x1C1712)
}

// MARK: - Chargement des images

struct Assets {
    let raw: URL
    let xcassets: URL

    func screenshot(_ name: String) -> NSImage {
        NSImage(contentsOf: raw.appendingPathComponent("\(name).png"))!
    }

    func asset(_ set: String, _ file: String) -> NSImage {
        NSImage(contentsOf: xcassets.appendingPathComponent("\(set).imageset/\(file)"))!
    }

    var mascot: NSImage { asset("Mascot", "mascot.png") }
    var dogScene: NSImage { asset("doggo_fond", "doggo_fond.png") }
    var catScene: NSImage { asset("gato_fond", "gato_fond.png") }
}

extension NSImage {
    /// Recadre en coordonnées pixels (origine en haut à gauche).
    func cropped(_ rect: CGRect) -> NSImage {
        guard let cg = cgImage(forProposedRect: nil, context: nil, hints: nil),
              let part = cg.cropping(to: rect) else { return self }
        return NSImage(cgImage: part, size: rect.size)
    }
}

// MARK: - Éléments graphiques

/// Fond chaud avec empreintes de pattes discrètes.
struct PawBackground: View {
    let colors: [Color]
    var pawOpacity = 0.10
    var seed = 1

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                let unit = max(geo.size.width, geo.size.height) / 14
                ForEach(0..<46, id: \.self) { index in
                    let x = pseudo(index * 7 + seed) * geo.size.width
                    let y = pseudo(index * 13 + seed * 3) * geo.size.height
                    Text("🐾")
                        .font(.system(size: unit * (0.45 + pseudo(index * 5 + seed) * 0.5)))
                        .rotationEffect(.degrees(pseudo(index * 11 + seed) * 70 - 35))
                        .opacity(pawOpacity)
                        .position(x: x, y: y)
                }
            }
        }
    }

    private func pseudo(_ n: Int) -> CGFloat {
        let v = sin(Double(n) * 12.9898) * 43758.5453
        return CGFloat(v - floor(v))
    }
}

/// iPhone ou iPad stylisé autour d'une capture d'écran.
struct DeviceFrame: View {
    let image: NSImage
    let width: CGFloat
    let screenCorner: CGFloat

    var body: some View {
        let height = width * image.size.height / image.size.width
        let bezel = width * 0.022
        Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: screenCorner, style: .continuous))
            .padding(bezel)
            .background(
                RoundedRectangle(cornerRadius: screenCorner + bezel, style: .continuous)
                    .fill(Color(hex: 0x141414))
            )
            .overlay(
                RoundedRectangle(cornerRadius: screenCorner + bezel, style: .continuous)
                    .strokeBorder(Color(hex: 0x6B6B6B), lineWidth: bezel * 0.18)
            )
            .shadow(color: .black.opacity(0.28), radius: width * 0.05, y: width * 0.03)
    }
}

/// Illustration ronde façon « sticker ».
struct Sticker: View {
    let image: NSImage
    let diameter: CGFloat

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .scaledToFill()
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(.white, lineWidth: diameter * 0.035))
            .shadow(color: .black.opacity(0.22), radius: diameter * 0.05, y: diameter * 0.025)
    }
}

// MARK: - Captures marketing

struct Slide {
    let file: String
    let headline: String
    let background: [Color]
    var textColor: Color = .white
    var paws: Double = 0.10
}

struct ScreenshotPoster: View {
    let slide: Slide
    let shot: NSImage
    let canvas: CGSize
    let isPad: Bool

    var body: some View {
        let w = canvas.width
        let fontSize = isPad ? w * 0.062 : w * 0.083
        let deviceWidth = isPad ? w * 0.84 : w * 0.86
        let corner = isPad ? deviceWidth * 0.028 : deviceWidth * 0.135
        ZStack(alignment: .top) {
            PawBackground(colors: slide.background, pawOpacity: slide.paws, seed: slide.file.count)
            VStack(spacing: canvas.height * (isPad ? 0.035 : 0.04)) {
                Text(slide.headline)
                    .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineSpacing(fontSize * 0.04)
                    .foregroundStyle(slide.textColor)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: w * 0.9)
                    .shadow(color: .black.opacity(slide.textColor == .white ? 0.18 : 0), radius: fontSize * 0.08, y: fontSize * 0.04)
                    .padding(.top, canvas.height * (isPad ? 0.055 : 0.068))
                    .padding(.horizontal, w * 0.06)
                DeviceFrame(image: shot, width: deviceWidth, screenCorner: corner)
            }
        }
        .frame(width: canvas.width, height: canvas.height, alignment: .top)
        .fixedSize()
        .frame(width: canvas.width, height: canvas.height, alignment: .top)
        .clipped()
    }
}

let slides: [Slide] = [
    Slide(file: "game", headline: "Le premier qui crie\n« Doggo ! » marque",
          background: [Palette.caramelLight, Palette.caramelDark]),
    Slide(file: "home", headline: "Toute la bande,\nen direct",
          background: [Palette.sky, Palette.skyDark]),
    Slide(file: "invite", headline: "Invite tes amis\nen un scan",
          background: [Palette.cream, Color(hex: 0xF9DDB8)], textColor: Palette.ink, paws: 0.08),
    Slide(file: "gato_dark", headline: "Team chiens 🐶\nou team chats 🐱 ?",
          background: [Palette.lavenderLight, Palette.lavender]),
    Slide(file: "stats", headline: "Stats, records\net séries 🔥",
          background: [Color(hex: 0x7ED69B), Color(hex: 0x3FA866)]),
    Slide(file: "winner", headline: "Un podium…\net la revanche !",
          background: [Palette.gold, Palette.caramel]),
]

// MARK: - En-tête et résultats de recherche

struct BannerContent: View {
    let assets: Assets
    let canvas: CGSize
    /// Zone de sécurité centrée (texte et éléments clés).
    let safe: CGSize
    let showChips: Bool

    var body: some View {
        let dog = assets.dogScene.cropped(CGRect(x: 110, y: 230, width: 800, height: 800))
        let cat = assets.catScene.cropped(CGRect(x: 120, y: 260, width: 800, height: 800))
        let stickerSize = canvas.height * (showChips ? 0.44 : 0.86)
        // Centre horizontal des stickers : juste à l'extérieur de la zone de sécurité.
        let sideX = showChips ? max(stickerSize * 0.30, (canvas.width - safe.width) / 2 - stickerSize * 0.55) : canvas.width * 0.135
        let titleSize = safe.height * (showChips ? 0.25 : 0.36)

        ZStack {
            PawBackground(colors: [Palette.caramelLight, Palette.caramel, Palette.caramelDark], pawOpacity: 0.09, seed: 4)

            // Halo central pour la lisibilité.
            Ellipse()
                .fill(RadialGradient(colors: [.white.opacity(0.22), .clear], center: .center, startRadius: 0, endRadius: safe.width * 0.6))
                .frame(width: safe.width * 1.4, height: safe.height * 1.6)

            Sticker(image: dog, diameter: stickerSize)
                .rotationEffect(.degrees(-6))
                .position(x: sideX, y: canvas.height * (showChips ? 0.64 : 0.56))
            Sticker(image: cat, diameter: stickerSize * 0.9)
                .rotationEffect(.degrees(7))
                .position(x: canvas.width - sideX * (showChips ? 1 : 0.98), y: canvas.height * (showChips ? 0.36 : 0.47))

            VStack(spacing: safe.height * 0.06) {
                HStack(spacing: titleSize * 0.25) {
                    Sticker(image: assets.mascot, diameter: titleSize * 1.15)
                    Text("Doggo")
                        .font(.system(size: titleSize, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.18), radius: titleSize * 0.06, y: titleSize * 0.04)
                }
                Text("Le premier qui le dit marque le point !")
                    .font(.system(size: titleSize * 0.36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                if showChips {
                    HStack(spacing: safe.width * 0.025) {
                        Chip(text: "🐶  Score en direct", size: titleSize * 0.24)
                        Chip(text: "📷  Invitation par QR", size: titleSize * 0.24)
                        Chip(text: "🏆  Podium", size: titleSize * 0.24)
                    }
                    .padding(.top, safe.height * 0.03)
                }
            }
            .frame(width: safe.width, height: safe.height)
            .position(x: canvas.width / 2, y: canvas.height / 2)
        }
        .frame(width: canvas.width, height: canvas.height)
        .clipped()
    }
}

struct Chip: View {
    let text: String
    let size: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, size * 0.9)
            .padding(.vertical, size * 0.5)
            .background(Capsule().fill(Palette.cream))
            .shadow(color: .black.opacity(0.15), radius: size * 0.3, y: size * 0.15)
    }
}

// MARK: - Export PNG sans canal alpha

@MainActor
func export<V: View>(_ view: V, size: CGSize, to url: URL) {
    let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
    renderer.scale = 1
    renderer.isOpaque = true
    guard let cg = renderer.cgImage else { fatalError("rendu impossible : \(url.lastPathComponent)") }
    let width = Int(size.width), height = Int(size.height)
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
    let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
    print("✓ \(url.lastPathComponent)  \(width)×\(height)")
}

@main
struct Render {
    @MainActor
    static func main() {
        let args = CommandLine.arguments
        guard args.count >= 4 else {
            print("Usage : render <captures> <Assets.xcassets> <sortie> [iphone|ipad|banners]")
            exit(1)
        }
        let assets = Assets(raw: URL(fileURLWithPath: args[1]), xcassets: URL(fileURLWithPath: args[2]))
        let out = URL(fileURLWithPath: args[3])
        let what = args.count > 4 ? args[4] : "iphone"
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

        switch what {
        case "iphone", "ipad":
            let isPad = what == "ipad"
            for (index, slide) in slides.enumerated() {
                let shot = assets.screenshot(slide.file)
                let canvas = shot.representations.first.map { CGSize(width: $0.pixelsWide, height: $0.pixelsHigh) } ?? shot.size
                export(ScreenshotPoster(slide: slide, shot: shot, canvas: canvas, isPad: isPad), size: canvas,
                       to: out.appendingPathComponent(String(format: "%02d-%@.png", index + 1, slide.file)))
            }
        case "banners":
            let header = CGSize(width: 3840, height: 1646)
            export(BannerContent(assets: assets, canvas: header, safe: CGSize(width: 1646, height: 661), showChips: false),
                   size: header, to: out.appendingPathComponent("entete-3840x1646.png"))
            let search = CGSize(width: 3840, height: 2560)
            export(BannerContent(assets: assets, canvas: search, safe: CGSize(width: 2168, height: 1030), showChips: true),
                   size: search, to: out.appendingPathComponent("recherche-3840x2560.png"))
        default:
            print("Mode inconnu : \(what)")
        }
    }
}
