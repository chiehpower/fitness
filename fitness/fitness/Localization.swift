import Foundation

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
        return availableCodes.contains(defaultLanguageCode) ? defaultLanguageCode : (availableLanguages.first?.code ?? defaultLanguageCode)
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
