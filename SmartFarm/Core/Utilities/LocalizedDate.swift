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

    static func monthYearString(_ date: Date) -> String {
        formatted(date) { $0.setLocalizedDateFormatFromTemplate("MMMMyyyy") }
    }

    /// "day month" (e.g. "21 កញ្ញា") — paired with `L("calendar.dayHeader")`
    /// for the Calendar tab's day-detail section header.
    static func dayOfMonthString(_ date: Date) -> String {
        formatted(date) { $0.setLocalizedDateFormatFromTemplate("dMMMM") }
    }

    static func dateTimeString(_ date: Date) -> String {
        formatted(date) { $0.dateStyle = .medium; $0.timeStyle = .short }
    }

    static func timeString(_ date: Date) -> String {
        formatted(date) { $0.dateStyle = .none; $0.timeStyle = .short }
    }

    /// Fixed Sunday-first weekday abbreviations (`L("weekday.sun")` … `L("weekday.sat")`),
    /// used instead of `DateFormatter` symbols so wording matches the app's own
    /// style exactly (e.g. Thursday shortened to "ព្រហ") rather than the OS's.
    static var weekdayAbbreviations: [String] {
        ["weekday.sun", "weekday.mon", "weekday.tue", "weekday.wed",
         "weekday.thu", "weekday.fri", "weekday.sat"].map(L)
    }

    /// Fixed weekday abbreviation for a specific date.
    static func weekdayAbbreviation(for date: Date, calendar: Calendar = .current) -> String {
        let index = calendar.component(.weekday, from: date) - 1
        let symbols = weekdayAbbreviations
        return symbols.indices.contains(index) ? symbols[index] : ""
    }

    /// Fixed weekday abbreviations rotated to start at `firstWeekday`
    /// (1 = Sunday … 7 = Saturday) — for a week-header row.
    static func weekdayHeaderAbbreviations(firstWeekday: Int) -> [String] {
        let symbols = weekdayAbbreviations
        let start = max(0, min(symbols.count - 1, firstWeekday - 1))
        return Array(symbols[start...] + symbols[..<start])
    }

    /// Full weekday names (`L("weekday.full.sun")` … `L("weekday.full.sat")`)
    /// used by the Calendar tab's month-grid header.
    private static var weekdayFullNames: [String] {
        ["weekday.full.sun", "weekday.full.mon", "weekday.full.tue", "weekday.full.wed",
         "weekday.full.thu", "weekday.full.fri", "weekday.full.sat"].map(L)
    }

    /// Full weekday names rotated to start at `firstWeekday`
    /// (1 = Sunday … 7 = Saturday) — for the Calendar tab's month-grid header row.
    static func weekdayHeaderFullNames(firstWeekday: Int) -> [String] {
        let symbols = weekdayFullNames
        let start = max(0, min(symbols.count - 1, firstWeekday - 1))
        return Array(symbols[start...] + symbols[..<start])
    }

    private static func formatted(_ date: Date, _ configure: (DateFormatter) -> Void) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        configure(formatter)
        return formatter.string(from: date)
    }

    /// "day month year" in the current language's native numerals (Khmer
    /// digits for Khmer, e.g. "១២ វិច្ឆិកា ២០២៦") — plain `Locale(identifier:
    /// "km")` formats digits as Arabic numerals, so this forces the Khmer
    /// numbering system explicitly when the app is in Khmer. Used by
    /// `headlineString` below and the Calendar tab's day-detail card title.
    static func dayMonthYearString(_ date: Date) -> String {
        let isKhmer = LocalizationManager.shared.language == .khmer
        let formatter = DateFormatter()
        formatter.locale = isKhmer ? Locale(identifier: "km@numbers=khmr") : locale
        formatter.setLocalizedDateFormatFromTemplate("dMMMMy")
        return formatter.string(from: date)
    }

    /// The Home screen's big "today" headline — "ថ្ងៃ" + full weekday + day +
    /// month + year, in Khmer numerals (e.g. "ថ្ងៃពុធ ៤ វិច្ឆិកា ២០២៦").
    static func headlineString(_ date: Date) -> String {
        let calendar = Calendar.current
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        let weekday = weekdayFullNames.indices.contains(weekdayIndex) ? weekdayFullNames[weekdayIndex] : ""
        let isKhmer = LocalizationManager.shared.language == .khmer
        let rest = dayMonthYearString(date)
        return isKhmer ? "ថ្ងៃ\(weekday) \(rest)" : "\(weekday), \(rest)"
    }

    /// Renders an integer using the current app language's native numerals —
    /// Khmer digits for Khmer (its plain `Locale` defaults to Arabic digits,
    /// same issue as `headlineString` above), Arabic digits for English.
    static func localizedNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = LocalizationManager.shared.language == .khmer
            ? Locale(identifier: "km@numbers=khmr")
            : locale
        formatter.numberStyle = .none
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
