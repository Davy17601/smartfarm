import SwiftUI

/// Color palette for the Calendar tab's redesigned UI — kept separate from
/// `Theme` (used by Dashboard/Finance/Reports/Settings) so this one tab can
/// carry its own green identity without changing any other screen's colors.
enum CalendarTheme {
    static let deepGreen      = Color(hex: 0x2E7D4F)
    /// Lighter partner shade for the header icon's gradient.
    static let deepGreenLight = Color(hex: 0x4E9B71)
    static let lightGreenTint = Color(hex: 0xE8F5EC)
    /// Text color for dates outside the displayed month.
    static let outOfMonthText = Color(hex: 0xC7CCC6)
    static let weekdayGray    = Color(hex: 0x8A9089)
    /// Hairline divider between the month grid's table cells.
    static let gridLine       = Color(hex: 0xC7E3D0)

    static let todayPillBackground    = Color(hex: 0xDCF1E2)
    static let todayPillText          = deepGreen
    static let upcomingPillBackground = Color(hex: 0xFBEACB)
    static let upcomingPillText       = Color(hex: 0xB4740E)

    /// Small dot / icon-badge colors used on the month grid and activity
    /// list — see `FarmActivityCategory.calendarAccent` below.
    static let dotGreen  = Color(hex: 0x3FA65C)
    static let dotBlue   = Color(hex: 0x3B82C4)
    static let dotAmber  = Color(hex: 0xE0A02E)
    static let dotPurple = Color(hex: 0x8B5FBF)
    static let dotPink   = Color(hex: 0xE0527A)
}

extension FarmActivityCategory {
    /// Calendar-tab-only accent color (grid dots, activity-list icon badges)
    /// — distinct from `color` (used by Dashboard/Reports) so harvest gets
    /// its own red/pink here per the Calendar redesign, without touching
    /// those other screens' palette.
    var calendarAccent: Color {
        switch self {
        case .planting:    return CalendarTheme.dotGreen
        case .watering:    return CalendarTheme.dotBlue
        case .fertilizing: return CalendarTheme.dotAmber
        case .care:        return CalendarTheme.dotPurple
        case .harvest:     return CalendarTheme.dotPink
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                   green: Double((hex >> 8) & 0xFF) / 255,
                   blue: Double(hex & 0xFF) / 255)
    }
}
