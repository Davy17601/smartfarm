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
                    completableRow(
                        title: reminder.title,
                        subtitle: reminder.note,
                        time: LocalizedDate.dateTimeString(reminder.dueDate),
                        isCompleted: reminder.isCompleted,
                        toggle: { viewModel.toggleReminderCompleted(reminder) },
                        edit: { editingReminder = reminder }
                    )
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
}
