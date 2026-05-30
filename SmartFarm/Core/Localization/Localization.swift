import Foundation
import SwiftUI

/// Supported UI languages. Khmer is the default / development language.
enum AppLanguage: String, CaseIterable, Identifiable {
    case khmer = "km"
    case english = "en"

    var id: String { rawValue }
    var locale: Locale { Locale(identifier: rawValue) }

    /// Shown natively in its own language (convention for language pickers).
    var displayName: String {
        switch self {
        case .khmer:   return "ខ្មែរ"
        case .english: return "English"
        }
    }
}

/// Drives in-app language switching. Looks strings up in the selected `.lproj`
/// bundle so the choice overrides the system language. Changing `language`
/// republishes; the root view rebuilds via `.id(language)` so the whole UI
/// re-renders live — no reinstall, no forced restart.
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    private static let storageKey = "appLanguage"

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
            bundle = Self.bundle(for: language)
        }
    }

    private var bundle: Bundle

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.storageKey)
        let initial = AppLanguage(rawValue: saved ?? "") ?? .khmer
        self.language = initial
        self.bundle = Self.bundle(for: initial)
    }

    private static func bundle(for language: AppLanguage) -> Bundle {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }

    /// Returns the localized string, or the key itself if missing (visible in QA).
    func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }
}

/// Global shorthand for `LocalizationManager.shared.localized(_:)`.
func L(_ key: String) -> String {
    LocalizationManager.shared.localized(key)
}
