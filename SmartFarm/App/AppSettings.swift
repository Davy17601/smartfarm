import Foundation
import Combine

/// App-wide user preferences (persisted in `UserDefaults`). Injected via
/// `.environmentObject`; views observing it re-render when a value changes.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private static let currencyKey = "displayCurrency"

    /// Currency used for all aggregate totals (summary cards, dashboard, reports).
    /// Per-transaction currency is unaffected. Default: KHR.
    @Published var displayCurrency: Currency {
        didSet {
            UserDefaults.standard.set(displayCurrency.rawValue, forKey: Self.currencyKey)
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.currencyKey)
        self.displayCurrency = Currency(rawValue: saved ?? "") ?? .khr
    }
}
