import SwiftUI

/// One row in the Notifications tab: a round checkbox (or, in "បានធ្វើរួច", a
/// filled checkmark that undoes completion), a category icon in a colored
/// rounded square, title + date/time, and a trailing status pill. Swipeable
/// left to reveal "ធ្វើរួច"/"លុប" (not shown in "បានធ្វើរួច", where the
/// checkmark itself is the undo control). Tapping the row body (not the
/// checkbox) opens the item in the existing add/edit sheet.
struct NotificationRow: View {
    let item: AgendaItem
    let segment: NotificationsSegment
    let onToggle: () -> Void
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var confirmingDelete = false

    var body: some View {
        SwipeActionsRow(actions: swipeActions) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    checkbox
                    iconBadge
                    titleBlock
                    Spacer(minLength: 8)
                    trailingBadge
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.white)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        .alert(isPresented: $confirmingDelete) {
            Alert(title: Text(L("notif.delete.confirmTitle")),
                  message: Text(L("notif.delete.confirmMessage")),
                  primaryButton: .destructive(Text(L("common.delete")), action: onDelete),
                  secondaryButton: .cancel(Text(L("common.cancel"))))
        }
    }

    // MARK: - Checkbox / checkmark

    private var checkbox: some View {
        Button(action: handleToggle) {
            ZStack {
                Circle()
                    .fill(segment == .completed ? CalendarTheme.farmGreen : Color.clear)
                Circle()
                    .stroke(segment == .completed ? Color.clear : CalendarTheme.mutedText.opacity(0.35), lineWidth: 2)
                if segment == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 26, height: 26)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func handleToggle() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onToggle()
    }

    // MARK: - Icon badge

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(item.accentColor.opacity(0.15))
                .frame(width: 40, height: 40)
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(item.accentColor)
        }
    }

    // MARK: - Title / subtitle

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(segment == .completed ? CalendarTheme.mutedText : Theme.primaryText)
                .strikethrough(segment == .completed)
                .lineLimit(1)
            Text(subtitleText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(CalendarTheme.mutedText)
                .lineLimit(1)
        }
    }

    private var subtitleText: String {
        if segment == .completed, let completedAt = item.completedAt {
            return String(format: L("notif.completedOn"), LocalizedDate.dayMonthString(completedAt))
        }
        return item.subtitle
    }

    // MARK: - Trailing status pill

    @ViewBuilder
    private var trailingBadge: some View {
        switch segment {
        case .upcoming:  pill(text: upcomingPillText, color: CalendarTheme.farmGreen)
        case .overdue:   pill(text: overduePillText, color: Theme.expense)
        case .completed: EmptyView()
        }
    }

    private func pill(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color)
            .clipShape(Capsule())
            .fixedSize()
    }

    private var upcomingPillText: String {
        switch daysBetween(Date(), item.date) {
        case 0:  return L("home.pill.today")
        case 1:  return L("home.pill.tomorrow")
        case let days: return String(format: L("home.pill.daysLeft"), LocalizedDate.localizedNumber(days))
        }
    }

    private var overduePillText: String {
        let daysOverdue = daysBetween(item.date, Date())
        if daysOverdue <= 0 {
            return L("notif.pill.overdueToday")
        }
        return String(format: L("notif.pill.overdueDays"), LocalizedDate.localizedNumber(daysOverdue))
    }

    /// Whole calendar days from `from` to `to`, clamped to >= 0.
    private func daysBetween(_ from: Date, _ to: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: from)
        let end = calendar.startOfDay(for: to)
        return max(calendar.dateComponents([.day], from: start, to: end).day ?? 0, 0)
    }

    // MARK: - Swipe actions

    private var swipeActions: [SwipeAction] {
        guard segment != .completed else { return [] }
        return [
            SwipeAction(title: L("notif.swipe.done"), icon: "checkmark", color: CalendarTheme.farmGreen, action: handleToggle),
            SwipeAction(title: L("common.delete"), icon: "trash", color: Theme.expense) {
                confirmingDelete = true
            }
        ]
    }
}

struct NotificationRow_Previews: PreviewProvider {
    static var previews: some View {
        let activity = FarmActivity(title: "ស្រោចទឹក", date: Date(), category: .watering)
        var completedActivity = activity
        completedActivity.isCompleted = true
        completedActivity.completedAt = Date()

        return VStack(spacing: 12) {
            NotificationRow(item: .activity(activity), segment: .upcoming, onToggle: {}, onTap: {}, onDelete: {})
            NotificationRow(item: .activity(activity), segment: .overdue, onToggle: {}, onTap: {}, onDelete: {})
            NotificationRow(item: .activity(completedActivity), segment: .completed, onToggle: {}, onTap: {}, onDelete: {})
        }
        .padding()
        .background(Color(red: 0xF3 / 255, green: 0xF8 / 255, blue: 0xF1 / 255))
        .previewLayout(.sizeThatFits)
    }
}
