//
//  DoggoApp.swift
//  Doggo
//
//  Created by Ludovic Rocher on 02/05/2025.
//

import SwiftUI
import Firebase
import FirebaseFirestore

@main
struct DoggoApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
