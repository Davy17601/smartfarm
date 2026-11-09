import SwiftUI

/// Calendar tab — redesigned with its own green identity (`CalendarTheme`),
/// scoped to this screen only. Custom header (replaces the system nav bar),
/// a month grid whose tapped date drives `selectedDayCard`'s inline
/// activity/reminder list below it, and a combined 7-day agenda list under that.
struct CalendarTabView: View {
    @StateObject private var viewModel: CalendarViewModel
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var environment: AppEnvironment

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
                            .farmCard()

                        selectedDayCard
                        scheduleSection
                        viewAllButton
                    }
                    .padding(Theme.Spacing.m)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.reload()
                // The tab's view model outlives any single day, so re-check the
                // current date on every appearance, not just at construction.
                viewModel.refreshForCurrentDate()
            }
            .actionSheet(isPresented: $addingChoice) {
                ActionSheet(title: Text(L("calendar.addChoice.title")), buttons: [
                    .default(Text(L("calendar.addActivity"))) { addingActivity = true },
                    .default(Text(L("calendar.addReminder"))) { addingReminder = true },
                    .cancel()
                ])
            }
            .sheet(isPresented: $addingActivity) {
                AddEditActivityView(mode: .add(defaultActivityDate)) { viewModel.addActivity($0) }
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
    /// `GeometryReader`-sized image (no seams), boosted saturation/contrast,
    /// and a green gradient wash (darker top/bottom, clearer in the middle)
    /// instead of a flat white tint, bleeding only into the top safe area so
    /// it stops above the tab bar instead of showing through it.
    private var backgroundLayer: some View {
        GeometryReader { geo in
            ZStack {
                Image("cartoon-lifestyle-summertime-scene")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .saturation(1.25)
                    .contrast(1.08)
                    .clipped()

                LinearGradient(
                    colors: [
                        CalendarTheme.farmGreen.opacity(0.55),
                        CalendarTheme.farmGreen.opacity(0.15),
                        Color.clear,
                        CalendarTheme.farmGreen.opacity(0.35)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Header

    /// Custom in-body header (app icon, "SMART CALENDAR" title + tagline —
    /// `appWelcome.splashTitle`, the same brand title the onboarding screen
    /// uses — and a bell with an unread-style dot when there's something due
    /// today) — tapping the bell switches the bottom tab bar to the
    /// "ការជូនដំណឹង" tab (`AppEnvironment.selectedTab`) instead of pushing a
    /// second copy of that same list, so the tab bar's highlight always
    /// matches what's on screen.
    private var header: some View {
        HStack(spacing: Theme.Spacing.s) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(CalendarTheme.farmGreen)
                .frame(width: 44, height: 44)
                .overlay(headerCalendarLeafIcon)

            VStack(alignment: .leading, spacing: 2) {
                Text(L("appWelcome.splashTitle"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
                Text(L("calendar.header.tagline"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            Button(action: switchToNotificationsTab) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(CalendarTheme.farmGreen)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white))
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

    /// Switches the shared tab selection to "ការជូនដំណឹង" with the same
    /// spring animation `CustomTabBar` (`MainTabView.swift`) uses for its own
    /// taps, so this behaves identically to tapping that tab directly.
    private func switchToNotificationsTab() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            environment.selectedTab = .notifications
        }
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

    // MARK: - Selected day's activities

    /// Replaces the old fixed "today" summary — this card always reflects
    /// whichever date is selected in `MonthCalendarGridView` above (tapping a
    /// day updates `viewModel.selectedDate`, which this reads directly), and
    /// lists that day's activities/reminders inline instead of pushing to a
    /// separate screen, so tapping one opens it for editing right away.
    private var selectedDayCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle().fill(CalendarTheme.deepGreen).frame(width: 44, height: 44)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDayTitle)
                        .font(Theme.Fonts.heading.weight(.bold))
                        .foregroundColor(CalendarTheme.deepGreen)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(String(format: L("calendar.todayTasks.count"), selectedDayItems.count))
                        .font(Theme.Fonts.caption.weight(.medium))
                        .foregroundColor(CalendarTheme.mutedText)
                }
                Spacer(minLength: 0)
            }

            if selectedDayItems.isEmpty {
                selectedDayEmptyState
            } else {
                VStack(spacing: Theme.Spacing.s) {
                    ForEach(selectedDayItems) { item in
                        AgendaRow(item: item, onTap: { openEditor(for: item) }, onDelete: { delete(item) })
                    }
                }
            }
        }
        .padding(Theme.Spacing.m)
        .farmCard()
    }

    private var selectedDayTitle: String {
        String(format: L("calendar.dayActivities.title"), LocalizedDate.dayMonthYearString(viewModel.selectedDate))
    }

    /// Activities + reminders saved on the selected date, regardless of
    /// completion, sorted by time.
    private var selectedDayItems: [AgendaItem] {
        let activities = viewModel.activities(on: viewModel.selectedDate).map(AgendaItem.activity)
        let reminders = viewModel.reminders
            .filter { Calendar.current.isDate($0.dueDate, inSameDayAs: viewModel.selectedDate) }
            .map(AgendaItem.reminder)
        return (activities + reminders).sorted { $0.date < $1.date }
    }

    private var selectedDayEmptyState: some View {
        VStack(spacing: 12) {
            Text(L("calendar.dayActivities.empty"))
                .font(Theme.Fonts.body.weight(.medium))
                .foregroundColor(CalendarTheme.mutedText)
                .multilineTextAlignment(.center)
            Button(action: { addingActivity = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text(L("calendar.addActivity"))
                        .font(Theme.Fonts.body.weight(.bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(CalendarTheme.farmGreen)
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    /// The default date+time an activity added for the selected day should
    /// start with: the actual current time if the selection is today (so a
    /// same-day activity doesn't default to a moment that's already past),
    /// otherwise 7:00 AM on the selected day.
    private var defaultActivityDate: Date {
        let calendar = Calendar.current
        let now = Date()
        if calendar.isDate(viewModel.selectedDate, inSameDayAs: now) {
            return now
        }
        var components = calendar.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
        components.hour = 7
        components.minute = 0
        return calendar.date(from: components) ?? viewModel.selectedDate
    }

    private var todayItemCount: Int {
        let activityCount = viewModel.activities(on: Date()).filter { !$0.isCompleted }.count
        let reminderCount = viewModel.reminders.filter { !$0.isCompleted && Calendar.current.isDateInToday($0.dueDate) }.count
        return activityCount + reminderCount
    }

    private var hasTodayItems: Bool { todayItemCount > 0 }

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
                    .font(Theme.Fonts.heading.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(CalendarTheme.farmGreenDark))
                Spacer()
                Button(action: { addingChoice = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
                }
                .buttonStyle(BorderlessButtonStyle())
            }

            if scheduleItems.isEmpty {
                // A second, discoverable way (besides the "+" above) to start
                // adding something when there's nothing scheduled yet.
                Button(action: { addingChoice = true }) {
                    Text(L("calendar.noSchedule"))
                        .font(Theme.Fonts.body.weight(.medium))
                        .foregroundColor(CalendarTheme.mutedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Theme.Spacing.m)
                        .farmCard()
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
            .foregroundColor(CalendarTheme.farmGreen)
            .padding(Theme.Spacing.m)
            .frame(maxWidth: .infinity)
            .farmCard()
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct CalendarTabView_Previews: PreviewProvider {
    static var previews: some View {
        let environment = AppEnvironment(persistence: .preview)
        CalendarTabView(activityRepository: environment.activityRepository,
                        reminderRepository: environment.reminderRepository)
            .environmentObject(environment)
    }
}
