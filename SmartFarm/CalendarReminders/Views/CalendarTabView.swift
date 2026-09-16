import SwiftUI

struct CalendarTabView: View {
    @StateObject private var viewModel: CalendarViewModel

    @State private var addingActivity = false
    @State private var addingReminder = false
    @State private var editingActivity: FarmActivity?
    @State private var editingReminder: Reminder?

    init(activityRepository: FarmActivityRepositoryProtocol,
         reminderRepository: ReminderRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: CalendarViewModel(
            activityRepository: activityRepository,
            reminderRepository: reminderRepository
        ))
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                }

                activitiesSection
                remindersSection
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(L("tab.calendar"))
            .onAppear { viewModel.reload() }
            .sheet(isPresented: $addingActivity) {
                AddEditActivityView(mode: .add(viewModel.selectedDate)) { viewModel.addActivity($0) }
            }
            .sheet(isPresented: $addingReminder) {
                AddEditReminderView(mode: .add) { viewModel.addReminder($0) }
            }
            .sheet(item: $editingActivity) { activity in
                AddEditActivityView(mode: .edit(activity)) { viewModel.updateActivity($0) }
            }
            .sheet(item: $editingReminder) { reminder in
                AddEditReminderView(mode: .edit(reminder)) { viewModel.updateReminder($0) }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Activities

    private var activitiesSection: some View {
        let dayActivities = viewModel.activities(on: viewModel.selectedDate)
        return Section(header: HStack {
            Text("\(L("calendar.activities")) · \(LocalizedDate.dayMonthString(viewModel.selectedDate))")
            Spacer()
            Button { addingActivity = true } label: { Image(systemName: "plus") }
        }) {
            if dayActivities.isEmpty {
                Text(L("calendar.noActivities")).foregroundColor(Theme.secondaryText)
            } else {
                ForEach(dayActivities) { activity in
                    completableRow(
                        title: activity.title,
                        subtitle: activity.note,
                        time: LocalizedDate.dateTimeString(activity.date),
                        isCompleted: activity.isCompleted,
                        toggle: { viewModel.toggleActivityCompleted(activity) },
                        edit: { editingActivity = activity }
                    )
                }
                .onDelete { offsets in
                    offsets.map { dayActivities[$0] }.forEach(viewModel.deleteActivity)
                }
            }
        }
    }

    // MARK: - Reminders

    private var remindersSection: some View {
        Section(header: HStack {
            Text(L("calendar.upcomingReminders"))
            Spacer()
            Button { addingReminder = true } label: { Image(systemName: "plus") }
        }) {
            let upcoming = viewModel.upcomingReminders(within: 30)
            if upcoming.isEmpty {
                Text(L("calendar.noReminders")).foregroundColor(Theme.secondaryText)
            } else {
                ForEach(upcoming) { reminder in
                    reminderRow(reminder)
                }
                .onDelete { offsets in
                    offsets.map { upcoming[$0] }.forEach(viewModel.deleteReminder)
                }
            }
        }
    }

    // MARK: - Shared row

    private func completableRow(title: String, subtitle: String, time: String,
                                isCompleted: Bool, toggle: @escaping () -> Void,
                                edit: @escaping () -> Void) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Button(action: toggle) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? Theme.income : Theme.secondaryText)
            }
            .buttonStyle(BorderlessButtonStyle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .strikethrough(isCompleted)
                    .foregroundColor(isCompleted ? Theme.secondaryText : Theme.primaryText)
                if !subtitle.isEmpty {
                    Text(subtitle).font(Theme.Fonts.caption).foregroundColor(Theme.secondaryText)
                }
                Text(time).font(Theme.Fonts.caption).foregroundColor(Theme.secondaryText)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: edit)
    }

    private func reminderRow(_ reminder: Reminder) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Button {
                viewModel.toggleReminderCompleted(reminder)
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(reminder.isCompleted ? Theme.income : Theme.secondaryText)
            }
            .buttonStyle(BorderlessButtonStyle())

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .strikethrough(reminder.isCompleted)
                    .foregroundColor(reminder.isCompleted ? Theme.secondaryText : Theme.primaryText)
                if !reminder.note.isEmpty {
                    Text(reminder.note).font(Theme.Fonts.caption).foregroundColor(Theme.secondaryText)
                }
                Text(LocalizedDate.dateTimeString(reminder.dueDate))
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.secondaryText)
            }
            Spacer()

            if let badge = urgencyBadge(for: reminder.dueDate) {
                Text(badge)
                    .font(Theme.Fonts.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Spacing.s)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { editingReminder = reminder }
    }

    private func urgencyBadge(for date: Date) -> String? {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return L("dashboard.today")
        } else if calendar.isDateInTomorrow(date) {
            return L("dashboard.tomorrow")
        }
        return nil
    }
}
