import Foundation

/// Date formatting that follows the app's selected language (via
/// `LocalizationManager`), not a hardcoded locale. Formatters are created per
/// call because the locale can change at runtime when the user switches language.
enum LocalizedDate {
    private static var locale: Locale { LocalizationManager.shared.language.locale }

    static func mediumString(_ date: Date) -> String {
        formatted(date) { $0.dateStyle = .medium; $0.timeStyle = .none }
    }

    static func dayMonthString(_ date: Date) -> String {
        formatted(date) { $0.setLocalizedDateFormatFromTemplate("dMMM") }
    }

    static func dateTimeString(_ date: Date) -> String {
        formatted(date) { $0.dateStyle = .medium; $0.timeStyle = .short }
    }

    private static func formatted(_ date: Date, _ configure: (DateFormatter) -> Void) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        configure(formatter)
        return formatter.string(from: date)
    }
}
