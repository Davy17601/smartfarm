import SwiftUI

/// Color palette for the Calendar tab's redesigned UI — kept separate from
/// `Theme` (used by Dashboard/Finance/Reports/Settings) so this one tab can
/// carry its own green identity without changing any other screen's colors.
enum CalendarTheme {
    static let deepGreen      = Color(hex: 0x2E7D32)
    /// Same green as `deepGreen` — the "farmGreen" referred to by this tab's
    /// solid fills (today's circle, the header icon badge).
    static let farmGreen      = deepGreen
    /// Darker shade for high-contrast text/badges (weekday names, the
    /// "កាលវិភាគ" section-title capsule) that need more contrast than a flat
    /// `farmGreen` fill gives on a light card.
    static let farmGreenDark  = Color(hex: 0x1B5E20)
    static let weekdayGray    = Color(hex: 0x8A9089)

    /// Darker, higher-contrast neutral than `Theme.secondaryText` for
    /// secondary copy on this tab's cards (schedule subtitles, counts,
    /// empty states) — `.secondaryLabel` reads too faint against them.
    static let mutedText = Color(hex: 0x4A504C)

    /// Primary text color for current-month day numbers in the grid.
    static let farmText    = Color(hex: 0x1A2420)
    /// Base color for adjacent-month day numbers — dimmed further with
    /// `.opacity(0.45)` at the call site, rather than baked into a separate
    /// pre-mixed pale color.
    static let farmSubtext = Color(hex: 0x54635C)
    /// Status-pill fill for "upcoming" items — paired with `farmGreen` for "today".
    static let actionBlue  = Color(hex: 0x1A6BD1)

    /// Small dot / icon-badge colors used on the month grid and activity
    /// list — see `FarmActivityCategory.calendarAccent` below.
    static let dotGreen  = Color(hex: 0x3FA65C)
    static let dotBlue   = Color(hex: 0x3B82C4)
    static let dotAmber  = Color(hex: 0xE0A02E)
    static let dotPurple = Color(hex: 0x8B5FBF)
    static let dotPink   = Color(hex: 0xE0527A)
}

/// Solid white card with a crisp shadow — this tab's equivalent of
/// `DashboardView`'s card style, so Calendar's cards read the same way
/// against its own photo background instead of the old pale green tints.
/// Scoped to the Calendar tab only, like the rest of `CalendarTheme`.
extension View {
    func farmCard() -> some View {
        self
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(CalendarTheme.farmGreen.opacity(0.12), lineWidth: 1)
            )
            .cornerRadius(Theme.Radius.card)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
    }
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
