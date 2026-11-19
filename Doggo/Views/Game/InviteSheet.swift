//
//  InviteSheet.swift
//  Doggo
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct InviteSheet: View {
    let session: Session
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    private var url: URL { CodeGenerator.joinURL(for: session.code) }
    private var shareText: String {
        "Rejoins ma partie \(session.mode.title) \(session.mode.emoji) « \(session.displayName) » ! Code : \(session.code)\n\(url.absoluteString)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Tes amis scannent ce QR code avec l'appareil photo, ou tapent le code dans « Rejoindre ».")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if let qr = QRCode.image(for: url.absoluteString) {
                        Image(uiImage: qr)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .padding(18)
                            .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .overlay {
                                Text(session.mode.emoji)
                                    .font(.system(size: 34))
                                    .frame(width: 52, height: 52)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .shadow(color: .black.opacity(0.1), radius: 16, y: 6)
                            .accessibilityLabel("QR code de la partie")
                    }

                    Button {
                        UIPasteboard.general.string = session.code
                        Feedback.shared.success()
                        withAnimation { copied = true }
                        Task {
                            try? await Task.sleep(for: .seconds(1.6))
                            withAnimation { copied = false }
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(session.code)
                                .font(.system(size: 40, weight: .heavy, design: .monospaced))
                                .tracking(6)
                                .foregroundStyle(.primary)
                            Label(copied ? "Copié !" : "Toucher pour copier", systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(session.mode.accent)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .cardSurface(cornerRadius: 22)
                    }
                    .buttonStyle(PressableStyle(scale: 0.97))
                    .accessibilityLabel("Code \(session.code.map(String.init).joined(separator: " ")). Toucher pour copier.")

                    ShareLink(item: shareText) {
                        Label("Envoyer l'invitation", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PillButtonStyle(gradient: session.mode.gradient))

                    Text("L'hôte valide chaque demande avant que le joueur n'entre dans la partie.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Inviter des amis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("OK") { dismiss() } }
            }
        }
        .presentationDetents([.large])
    }
}

enum QRCode {
    static func image(for string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H" // tolère l'emoji au centre
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
