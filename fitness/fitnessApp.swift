//
//  fitnessApp.swift
//  fitness
//
//  Created by Chieh on 22/07/2024.
//

import SwiftUI
import Combine

struct AppLanguageOption: Identifiable, Hashable {
    let code: String

    var id: String { code }

    var localeIdentifier: String {
        code
    }

    var displayName: String {
        let locale = Locale(identifier: code)
        return locale.localizedString(forIdentifier: code)?
            .capitalized(with: locale) ?? code
    }
}

enum LocalizationSupport {
    static let defaultLanguageCode = "zh-Hant"
    static let fallbackLanguageCode = "en"

    static var availableLanguages: [AppLanguageOption] {
        let codes = Bundle.main.localizations
            .filter { $0 != "Base" }

        let preferredOrder = [defaultLanguageCode, "en"]

        return codes
            .uniqued()
            .sorted { lhs, rhs in
                let lhsRank = preferredOrder.firstIndex(of: lhs) ?? Int.max
                let rhsRank = preferredOrder.firstIndex(of: rhs) ?? Int.max
                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }
                return lhs.localizedCompare(rhs) == .orderedAscending
            }
            .map(AppLanguageOption.init(code:))
    }

    static func resolvedLanguageCode(from savedCode: String?) -> String {
        let availableCodes = Set(availableLanguages.map(\.code))
        if let savedCode, availableCodes.contains(savedCode) {
            return savedCode
        }

        for preferredLanguage in Locale.preferredLanguages {
            if availableCodes.contains(preferredLanguage) {
                return preferredLanguage
            }

            let languageCode = Locale(identifier: preferredLanguage).language.languageCode?.identifier
            if let languageCode,
               let matchedCode = availableCodes.first(where: { Locale(identifier: $0).language.languageCode?.identifier == languageCode }) {
                return matchedCode
            }
        }

        if availableCodes.contains(fallbackLanguageCode) {
            return fallbackLanguageCode
        }

        return availableCodes.contains(defaultLanguageCode) ? defaultLanguageCode : (availableLanguages.first?.code ?? fallbackLanguageCode)
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}

final class AppState: ObservableObject {
    @Published var pendingNfcTagId: String?
    @Published var shouldShowAddTrainingSet = false
    @Published var languageCode: String {
        didSet {
            UserDefaults.standard.set(languageCode, forKey: "appLanguage")
        }
    }

    init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage")
        languageCode = LocalizationSupport.resolvedLanguageCode(from: savedLanguage)
    }

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
                .environment(\.locale, Locale(identifier: appState.languageCode))
                .accentColor(.customAccent)
                .onOpenURL { url in
                    appState.handleDeepLink(url)
                }
        }
    }
}
