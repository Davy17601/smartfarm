import SwiftUI

/// Calendar tab — redesigned with its own green identity (`CalendarTheme`),
/// scoped to this screen only. Custom header (replaces the system nav bar),
/// month grid, a "today's tasks" summary card, and a combined
/// activity/reminder agenda list below it.
struct CalendarTabView: View {
    @StateObject private var viewModel: CalendarViewModel
    @EnvironmentObject private var settings: AppSettings

    @State private var addingChoice = false
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
            ZStack {
                backgroundLayer

                ScrollView {
                    VStack(spacing: Theme.Spacing.m) {
                        header

                        MonthCalendarGridView(selectedDate: $viewModel.selectedDate,
                                              activities: viewModel.activities,
                                              calendar: weekGridCalendar)
                            .padding(Theme.Spacing.m)
                            .background(Theme.cardBackground)
                            .cornerRadius(Theme.Radius.card)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)

                        todaySummaryCard
                        scheduleSection
                        viewAllButton
                    }
                    .padding(Theme.Spacing.m)
                }
            }
            .navigationBarHidden(true)
            .onAppear { viewModel.reload() }
            .actionSheet(isPresented: $addingChoice) {
                ActionSheet(title: Text(L("calendar.addChoice.title")), buttons: [
                    .default(Text(L("calendar.addActivity"))) { addingActivity = true },
                    .default(Text(L("calendar.addReminder"))) { addingReminder = true },
                    .cancel()
                ])
            }
            .sheet(isPresented: $addingActivity) {
                AddEditActivityView(mode: .add(viewModel.selectedDate)) { viewModel.addActivity($0) }
            }
            .sheet(isPresented: $addingReminder) {
                AddEditReminderView(mode: .add(viewModel.selectedDate)) { viewModel.addReminder($0) }
            }
            .sheet(item: $editingActivity) { activity in
                AddEditActivityView(mode: .edit(activity)) { viewModel.updateActivity($0) }
            }
            .sheet(item: $editingReminder) { reminder in
                AddEditReminderView(mode: .edit(reminder)) { viewModel.updateReminder($0) }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(CalendarTheme.deepGreen)
    }

    // MARK: - Background

    /// One continuous full-content photo behind the header, month grid, and
    /// schedule — mirrors `DashboardView`'s background treatment: a single
    /// `GeometryReader`-sized image (no seams) with a white wash to keep it
    /// soft, bleeding only into the top safe area so it stops above the tab
    /// bar instead of showing through it.
    private var backgroundLayer: some View {
        GeometryReader { geo in
            ZStack {
                Image("cartoon-lifestyle-summertime-scene")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .opacity(0.9)
                    .clipped()

                Color.white.opacity(0.4)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Header

    /// Custom in-body header (app icon, "SmartFarm" title + tagline, and a
    /// bell with an unread-style dot when there's something due today) —
    /// tapping the bell pushes the notifications list.
    private var header: some View {
        HStack(spacing: Theme.Spacing.s) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: [CalendarTheme.deepGreen, CalendarTheme.deepGreenLight],
                                      startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 44, height: 44)
                .overlay(headerCalendarLeafIcon)

            VStack(alignment: .leading, spacing: 2) {
                Text("SmartFarm")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(CalendarTheme.deepGreen)
                Text(L("calendar.header.tagline"))
                    .font(.system(size: 12))
                    .foregroundColor(Theme.secondaryText)
            }

            Spacer()

            NavigationLink(destination: AgendaListView(title: L("notifications.title"),
                                                        items: notificationItems,
                                                        viewModel: viewModel)) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(CalendarTheme.deepGreen)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(CalendarTheme.lightGreenTint))
                    if hasTodayItems {
                        Circle()
                            .fill(Theme.expense)
                            .frame(width: 9, height: 9)
                            .offset(x: 1, y: -1)
                    }
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    /// Upcoming (not yet completed) activities + reminders, sorted by date —
    /// backs the bell icon's notifications list.
    private var notificationItems: [AgendaItem] {
        let now = Date()
        let activities = viewModel.activities
            .filter { !$0.isCompleted && $0.date >= now }
            .map(AgendaItem.activity)
        let reminders = viewModel.reminders
            .filter { !$0.isCompleted && $0.dueDate >= now }
            .map(AgendaItem.reminder)
        return (activities + reminders).sorted { $0.date < $1.date }
    }

    /// A calendar glyph with a small circular leaf badge overlapping its
    /// bottom-right corner — the same composition used on `AppWelcomeView`'s
    /// icon badge, scaled down to this header's 44x44 size for visual
    /// consistency across the app.
    private var headerCalendarLeafIcon: some View {
        Image(systemName: "calendar")
            .font(.system(size: 24, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .overlay(headerLeafBadge, alignment: .bottomTrailing)
    }

    private var headerLeafBadge: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 16, height: 16)
            .overlay(
                Image(systemName: "leaf.fill")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundColor(CalendarTheme.deepGreen)
            )
            .overlay(
                Circle().stroke(CalendarTheme.deepGreen, lineWidth: 1)
            )
            .offset(x: -3, y: -3)
    }

    /// A `Calendar` whose `firstWeekday` follows the user's "week starts on"
    /// preference, used to control which day leads each row of the date grid.
    private var weekGridCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = settings.weekStartDay.rawValue
        // `Calendar.current` follows the device's system locale, not the
        // in-app language — without this, weekday symbols (and month names)
        // would stay in the device's language even when Khmer is selected.
        calendar.locale = LocalizationManager.shared.language.locale
        return calendar
    }

    // MARK: - Today's summary

    private var todaySummaryCard: some View {
        NavigationLink(destination: AgendaListView(title: L("calendar.todayTasks.title"),
                                                    items: todayAgendaItems,
                                                    viewModel: viewModel)) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle().fill(CalendarTheme.deepGreen).frame(width: 44, height: 44)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("calendar.todayTasks.title"))
                        .font(Theme.Fonts.heading)
                        .foregroundColor(CalendarTheme.deepGreen)
                    Text(String(format: L("calendar.todayTasks.count"), todayItemCount))
                        .font(Theme.Fonts.caption)
                        .foregroundColor(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(CalendarTheme.deepGreen.opacity(0.6))
            }
            .padding(Theme.Spacing.m)
            .background(CalendarTheme.lightGreenTint)
            .cornerRadius(Theme.Radius.card)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var todayItemCount: Int {
        let activityCount = viewModel.activities(on: Date()).filter { !$0.isCompleted }.count
        let reminderCount = viewModel.reminders.filter { !$0.isCompleted && Calendar.current.isDateInToday($0.dueDate) }.count
        return activityCount + reminderCount
    }

    private var hasTodayItems: Bool { todayItemCount > 0 }

    /// All of today's activities + reminders, regardless of completion —
    /// backs the "Today's tasks" pushed screen.
    private var todayAgendaItems: [AgendaItem] {
        let activities = viewModel.activities(on: Date()).map(AgendaItem.activity)
        let reminders = viewModel.reminders
            .filter { Calendar.current.isDateInToday($0.dueDate) }
            .map(AgendaItem.reminder)
        return (activities + reminders).sorted { $0.date < $1.date }
    }

    /// Every activity + reminder the app knows about, sorted by date —
    /// backs the "View full schedule" pushed screen.
    private var allAgendaItems: [AgendaItem] {
        (viewModel.activities.map(AgendaItem.activity) + viewModel.reminders.map(AgendaItem.reminder))
            .sorted { $0.date < $1.date }
    }

    // MARK: - Schedule (agenda) list

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Text(L("calendar.schedule.title"))
                    .font(Theme.Fonts.heading)
                    .foregroundColor(Theme.primaryText)
                Spacer()
                Button(action: { addingChoice = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(CalendarTheme.deepGreen)
                }
                .buttonStyle(BorderlessButtonStyle())
            }

            if scheduleItems.isEmpty {
                // A second, discoverable way (besides the "+" above) to start
                // adding something when there's nothing scheduled yet.
                Button(action: { addingChoice = true }) {
                    Text(L("calendar.noSchedule"))
                        .foregroundColor(Theme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Theme.Spacing.m)
                        .background(Theme.cardBackground)
                        .cornerRadius(Theme.Radius.card)
                }
                .buttonStyle(ScaleButtonStyle())
            } else {
                ForEach(scheduleItems) { item in
                    AgendaRow(item: item, onTap: { openEditor(for: item) }, onDelete: { delete(item) })
                }
            }
        }
    }

    /// Activities + reminders, not yet completed, sorted by date — the next 7 days.
    private var scheduleItems: [AgendaItem] {
        let now = Calendar.current.startOfDay(for: Date())
        let cutoff = Calendar.current.date(byAdding: .day, value: 7, to: now)
        let items = viewModel.activities
            .filter { !$0.isCompleted && $0.date >= now && (cutoff == nil || $0.date <= cutoff!) }
            .map(AgendaItem.activity)
        + viewModel.reminders
            .filter { !$0.isCompleted && $0.dueDate >= now && (cutoff == nil || $0.dueDate <= cutoff!) }
            .map(AgendaItem.reminder)
        return items.sorted { $0.date < $1.date }
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

    // MARK: - View full schedule

    private var viewAllButton: some View {
        NavigationLink(destination: AgendaListView(title: L("calendar.viewFullSchedule"),
                                                    items: allAgendaItems,
                                                    viewModel: viewModel)) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "calendar")
                Text(L("calendar.viewFullSchedule"))
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(Theme.Fonts.body.weight(.semibold))
            .foregroundColor(CalendarTheme.deepGreen)
            .padding(Theme.Spacing.m)
            .frame(maxWidth: .infinity)
            .background(CalendarTheme.lightGreenTint)
            .cornerRadius(Theme.Radius.card)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct CalendarTabView_Previews: PreviewProvider {
    static var previews: some View {
        let environment = AppEnvironment(persistence: .preview)
        CalendarTabView(activityRepository: environment.activityRepository,
                        reminderRepository: environment.reminderRepository)
    }
}
