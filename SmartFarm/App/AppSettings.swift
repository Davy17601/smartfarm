import Foundation
import Combine

/// Which weekday the Calendar grid starts on. Raw values match
/// `Calendar.firstWeekday` (1 = Sunday, 2 = Monday, ...).
enum WeekStartDay: Int, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .sunday: return L("settings.weekStart.sunday")
        case .monday: return L("settings.weekStart.monday")
        }
    }
}

/// App-wide user preferences (persisted in `UserDefaults`). Injected via
/// `.environmentObject`; views observing it re-render when a value changes.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private static let currencyKey = "displayCurrency"
    private static let weekStartDayKey = "weekStartDay"

    /// Currency used for all aggregate totals (summary cards, dashboard, reports).
    /// Per-transaction currency is unaffected. Default: KHR.
    @Published var displayCurrency: Currency {
        didSet {
            UserDefaults.standard.set(displayCurrency.rawValue, forKey: Self.currencyKey)
        }
    }

    /// First weekday shown in the Calendar tab's grid. Default: Sunday.
    @Published var weekStartDay: WeekStartDay {
        didSet {
            UserDefaults.standard.set(weekStartDay.rawValue, forKey: Self.weekStartDayKey)
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.currencyKey)
        self.displayCurrency = Currency(rawValue: saved ?? "") ?? .khr

        let savedWeekStart = UserDefaults.standard.integer(forKey: Self.weekStartDayKey)
        self.weekStartDay = WeekStartDay(rawValue: savedWeekStart) ?? .sunday
    }
}
