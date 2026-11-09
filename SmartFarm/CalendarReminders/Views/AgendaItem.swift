import SwiftUI

/// A farm activity or reminder, unified for display in a date-based agenda
/// list — shared by the Calendar tab's schedule section, "Today's tasks",
/// and "View full schedule" screens.
enum AgendaItem: Identifiable {
    case activity(FarmActivity)
    case reminder(Reminder)

    var id: UUID {
        switch self {
        case .activity(let a): return a.id
        case .reminder(let r): return r.id
        }
    }

    var date: Date {
        switch self {
        case .activity(let a): return a.date
        case .reminder(let r): return r.dueDate
        }
    }

    var title: String {
        switch self {
        case .activity(let a): return a.title
        case .reminder(let r): return r.title
        }
    }

    var subtitle: String {
        "\(LocalizedDate.dayMonthString(date)) · \(LocalizedDate.timeString(date))"
    }

    var icon: String {
        switch self {
        case .activity(let a): return a.category.systemImage
        case .reminder: return "bell.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .activity(let a): return a.category.calendarAccent
        case .reminder: return CalendarTheme.deepGreen
        }
    }

    var isCompleted: Bool {
        switch self {
        case .activity(let a): return a.isCompleted
        case .reminder(let r): return r.isCompleted
        }
    }

    var completedAt: Date? {
        switch self {
        case .activity(let a): return a.completedAt
        case .reminder(let r): return r.completedAt
        }
    }

    /// Sort key for the "បានធ្វើរួច" (completed) group: falls back to `date`
    /// for items completed before `completedAt` existed, so they still sort
    /// somewhere sensible instead of all clumping at the same nil position.
    var completedSortDate: Date { completedAt ?? date }
}
