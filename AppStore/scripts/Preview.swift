//
//  Preview.swift — convertit un enregistrement du simulateur en aperçu App Store.
//
//  swiftc -O AppStore/scripts/Preview.swift -o /tmp/doggo-preview
//  /tmp/doggo-preview <entree.mov> <audio.m4a> <sortie.mp4> <debut_s> <duree_s> [largeur hauteur]
//
//  Sortie : H.264, 30 i/s, 886 × 1920 par défaut (iPhone 6,1/6,3 pouces), piste audio AAC stéréo.
//  Avec l'option --frames <dossier>, exporte aussi une image par seconde pour vérification.
//

import AVFoundation
import AppKit

let args = CommandLine.arguments
guard args.count >= 6 else {
    print("Usage : preview <entree.mov> <audio.m4a> <sortie.mp4> <debut_s> <duree_s> [largeur hauteur] [--frames dossier]")
    exit(1)
}
let input = URL(fileURLWithPath: args[1])
let audioURL = URL(fileURLWithPath: args[2])
let output = URL(fileURLWithPath: args[3])
let start = Double(args[4])!
let duration = Double(args[5])!
let numbers = args.dropFirst(6).compactMap(Double.init)
let renderSize = numbers.count >= 2 ? CGSize(width: numbers[0], height: numbers[1]) : CGSize(width: 886, height: 1920)
let framesDir = args.firstIndex(of: "--frames").map { URL(fileURLWithPath: args[$0 + 1]) }

let semaphore = DispatchSemaphore(value: 0)

Task {
    do {
        let source = AVURLAsset(url: input)
        let sourceVideo = try await source.loadTracks(withMediaType: .video).first!
        let naturalSize = try await sourceVideo.load(.naturalSize)
        let preferred = try await sourceVideo.load(.preferredTransform)
        let oriented = naturalSize.applying(preferred)
        let sourceSize = CGSize(width: abs(oriented.width), height: abs(oriented.height))

        let composition = AVMutableComposition()
        let range = CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600),
                                duration: CMTime(seconds: duration, preferredTimescale: 600))
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        try videoTrack.insertTimeRange(range, of: sourceVideo, at: .zero)

        // Piste audio (silencieuse) : l'App Store attend une piste audio stéréo.
        let audio = AVURLAsset(url: audioURL)
        if let audioTrack = try await audio.loadTracks(withMediaType: .audio).first {
            let target = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
            let audioDuration = try await audio.load(.duration)
            let length = min(range.duration, audioDuration)
            try target.insertTimeRange(CMTimeRange(start: .zero, duration: length), of: audioTrack, at: .zero)
        }

        // Mise à l'échelle « remplir » puis recadrage centré.
        let scale = max(renderSize.width / sourceSize.width, renderSize.height / sourceSize.height)
        let scaled = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        let transform = preferred
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(translationX: (renderSize.width - scaled.width) / 2,
                                             y: (renderSize.height - scaled.height) / 2))
        let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layer.setTransform(transform, at: .zero)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: range.duration)
        instruction.layerInstructions = [layer]
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = [instruction]

        try? FileManager.default.removeItem(at: output)
        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            fatalError("export impossible")
        }
        export.videoComposition = videoComposition
        try await export.export(to: output, as: .mp4)
        print("✓ \(output.lastPathComponent)  \(Int(renderSize.width))×\(Int(renderSize.height))  \(duration)s")

        if let framesDir {
            try? FileManager.default.createDirectory(at: framesDir, withIntermediateDirectories: true)
            let result = AVURLAsset(url: output)
            let generator = AVAssetImageGenerator(asset: result)
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            generator.maximumSize = CGSize(width: 300, height: 650)
            for second in stride(from: 0.0, to: duration, by: 1.0) {
                let (image, _) = try await generator.image(at: CMTime(seconds: second, preferredTimescale: 600))
                let rep = NSBitmapImageRep(cgImage: image)
                try rep.representation(using: .png, properties: [:])!
                    .write(to: framesDir.appendingPathComponent(String(format: "f%02d.png", Int(second))))
            }
        }
    } catch {
        print("❌ \(error)")
        exit(1)
    }
    semaphore.signal()
}
semaphore.wait()
