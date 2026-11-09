import SwiftUI

/// Full-screen scrollable agenda list, pushed from the Calendar tab. Used for
/// "View full schedule" — and, with its own icon + message, as the
/// "ការជូនដំណឹង" tab's root — so this one view (and the shared `AgendaRow`
/// card style) covers both instead of near-duplicates.
struct AgendaListView: View {
    let title: String
    let items: [AgendaItem]
    @ObservedObject var viewModel: CalendarViewModel
    /// When set, the empty state shows this icon above `emptyStateMessage` in
    /// a centered card; when `nil` (the default), it's the old plain
    /// left-aligned text card, unchanged for "View full schedule".
    var emptyStateIcon: String?
    var emptyStateMessage: String = L("calendar.noSchedule")

    @State private var editingActivity: FarmActivity?
    @State private var editingReminder: Reminder?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.s) {
                if items.isEmpty {
                    emptyState
                } else {
                    ForEach(items) { item in
                        AgendaRow(item: item, onTap: { openEditor(for: item) }, onDelete: { delete(item) })
                    }
                }
            }
            .padding(Theme.Spacing.m)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingActivity) { activity in
            AddEditActivityView(mode: .edit(activity)) { viewModel.updateActivity($0) }
        }
        .sheet(item: $editingReminder) { reminder in
            AddEditReminderView(mode: .edit(reminder)) { viewModel.updateReminder($0) }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if let icon = emptyStateIcon {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(CalendarTheme.mutedText.opacity(0.6))
                Text(emptyStateMessage)
                    .font(Theme.Fonts.body.weight(.medium))
                    .foregroundColor(CalendarTheme.mutedText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .farmCard()
        } else {
            Text(emptyStateMessage)
                .font(Theme.Fonts.body.weight(.medium))
                .foregroundColor(CalendarTheme.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.m)
                .farmCard()
        }
    }

    private func openEditor(for item: AgendaItem) {
        switch item {
        case .activity(let activity): editingActivity = activity
        case .reminder(let reminder): editingReminder = reminder
        }
    }

    private func delete(_ item: AgendaItem) {
        switch item {
        case .activity(let activity): viewModel.deleteActivity(activity)
        case .reminder(let reminder): viewModel.deleteReminder(reminder)
        }
    }
}

struct AgendaListView_Previews: PreviewProvider {
    static var previews: some View {
        let environment = AppEnvironment(persistence: .preview)
        let vm = CalendarViewModel(activityRepository: environment.activityRepository,
                                    reminderRepository: environment.reminderRepository)
        NavigationView {
            AgendaListView(title: L("calendar.viewFullSchedule"), items: [], viewModel: vm)
        }
    }
}
