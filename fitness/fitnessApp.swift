//
//  fitnessApp.swift
//  fitness
//
//  Created by Chieh on 22/07/2024.
//

import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var pendingNfcTagId: String?
    @Published var shouldShowAddTrainingSet = false

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "fitness" else {
            return
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let host = url.host ?? ""
        let idFromQuery = components?.queryItems?.first(where: { $0.name == "id" })?.value
        let idFromPath = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        guard host == "equipment" || url.path.contains("equipment") else {
            return
        }

        let candidate = idFromQuery ?? (idFromPath.isEmpty ? nil : idFromPath)
        guard let tagId = candidate, !tagId.isEmpty else {
            return
        }

        pendingNfcTagId = tagId
        shouldShowAddTrainingSet = true
    }
}

@main
struct fitnessApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .accentColor(.customAccent)
                .onOpenURL { url in
                    appState.handleDeepLink(url)
                }
        }
    }
}
