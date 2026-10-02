import SwiftUI

/// Full-screen scrollable agenda list, pushed from the Calendar tab. Used for
/// both "Today's tasks" and "View full schedule" — they differ only in which
/// items are passed in and the navigation title, so this one view (and the
/// shared `AgendaRow` card style) covers both instead of two near-duplicates.
struct AgendaListView: View {
    let title: String
    let items: [AgendaItem]
    @ObservedObject var viewModel: CalendarViewModel

    @State private var editingActivity: FarmActivity?
    @State private var editingReminder: Reminder?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.s) {
                if items.isEmpty {
                    Text(L("calendar.noSchedule"))
                        .foregroundColor(Theme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Theme.Spacing.m)
                        .background(Theme.cardBackground)
                        .cornerRadius(Theme.Radius.card)
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
