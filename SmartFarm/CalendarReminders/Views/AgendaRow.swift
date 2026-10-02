import SwiftUI

/// One agenda row — a scheduled activity or reminder shown as a tappable
/// card with a leading icon badge, title/subtitle, a Today/Later status
/// pill, and a trailing chevron. Shared by the Calendar tab's schedule
/// section, "Today's tasks", and "View full schedule" screens so they all
/// look and behave the same; tapping opens the item for editing, and a
/// context menu (long-press) offers delete.
struct AgendaRow: View {
    let item: AgendaItem
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle().fill(item.accentColor.opacity(0.15)).frame(width: 40, height: 40)
                    Image(systemName: item.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(item.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(Theme.Fonts.body.weight(.bold))
                        .foregroundColor(Theme.primaryText)
                        .lineLimit(1)
                    Text(item.subtitle)
                        .font(Theme.Fonts.caption)
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                statusPill

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.secondaryText.opacity(0.4))
            }
            .padding(Theme.Spacing.m)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.Radius.card)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(ScaleButtonStyle())
        .contextMenu {
            Button(action: onDelete) {
                Label(L("common.delete"), systemImage: "trash")
            }
        }
    }

    private var statusPill: some View {
        let isToday = Calendar.current.isDateInToday(item.date)
        return Text(isToday ? L("calendar.pill.today") : L("calendar.pill.later"))
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isToday ? CalendarTheme.todayPillBackground : CalendarTheme.upcomingPillBackground)
            .foregroundColor(isToday ? CalendarTheme.todayPillText : CalendarTheme.upcomingPillText)
            .cornerRadius(8)
    }
}
