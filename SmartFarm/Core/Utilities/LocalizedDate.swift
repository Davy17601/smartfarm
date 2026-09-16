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

    /// Formats date and time with 12-hour format and Khmer/English AM/PM
    /// Always uses the real time from the Date parameter - never hardcoded.
    static func dateTimeWithAMPM(_ date: Date) -> String {
        let dateString = dayMonthString(date)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

        // Convert to 12-hour format
        let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)

        // Determine AM/PM in Khmer or English based on actual hour
        let ampm: String
        if LocalizationManager.shared.language == .khmer {
            if hour < 12 {
                ampm = "ព្រឹក" // morning (AM)
            } else if hour < 18 {
                ampm = "រសៀល" // afternoon (PM)
            } else {
                ampm = "ល្ងាច" // evening (PM)
            }
        } else {
            ampm = hour < 12 ? "AM" : "PM"
        }

        // Format with Khmer numerals if in Khmer locale
        let timeString: String
        if LocalizationManager.shared.language == .khmer {
            let hourStr = toKhmerNumerals("\(hour12)")
            let minuteStr = toKhmerNumerals(String(format: "%02d", minute))
            timeString = "\(dateString) \(hourStr):\(minuteStr) \(ampm)"
        } else {
            timeString = String(format: "%@ %d:%02d %@", dateString, hour12, minute, ampm)
        }

        return timeString
    }

    /// Long date format with Khmer numerals for Khmer locale (e.g., "៩ កញ្ញា ២០២៦").
    /// Falls back to regular formatting for other languages.
    static func longStringWithKhmerNumerals(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        let dateString = formatter.string(from: date)

        // Convert to Khmer numerals if in Khmer locale
        if LocalizationManager.shared.language == .khmer {
            return toKhmerNumerals(dateString)
        }
        return dateString
    }

    private static func formatted(_ date: Date, _ configure: (DateFormatter) -> Void) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        configure(formatter)
        return formatter.string(from: date)
    }

    /// Converts Arabic numerals (0-9) to Khmer numerals (០-៩).
    private static func toKhmerNumerals(_ text: String) -> String {
        let arabicToKhmer: [Character: Character] = [
            "0": "០", "1": "១", "2": "២", "3": "៣", "4": "៤",
            "5": "៥", "6": "៦", "7": "៧", "8": "៨", "9": "៩"
        ]
        return String(text.map { arabicToKhmer[$0] ?? $0 })
    }
}
