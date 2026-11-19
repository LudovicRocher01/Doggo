//
//  DoggoApp.swift
//  Doggo
//
//  Created by Ludovic Rocher on 02/05/2025.
//

import SwiftUI
import FirebaseCore

enum FirebaseBootstrap {
    /// Appelé au lancement et par les intents (Siri, Live Activity) qui peuvent démarrer l'app en arrière-plan.
    private static var isConfigured = false

    static func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true
        FirebaseApp.configure()
    }
}

@main
struct DoggoApp: App {
    init() {
        FirebaseBootstrap.configureIfNeeded()
        ScoreActions.registerBridge()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(AppModel.shared)
                .fontDesign(.rounded)
                .tint(Theme.doggo)
                .onOpenURL { AppModel.shared.handle(url: $0) }
                .task { await AppModel.shared.start() }
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Group {
            if app.profile == nil {
                OnboardingView()
                    .transition(.opacity)
            } else {
                HomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: app.profile == nil)
    }
}
