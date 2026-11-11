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
            // `header` sits above the `ScrollView` in its own row (not inside
            // it) so the scroll content always starts right below the
            // header's actual laid-out height instead of guessing at one —
            // no overlap, and the month row is visible on first appearance.
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: Theme.Spacing.m) {
                        MonthCalendarGridView(selectedDate: $viewModel.selectedDate,
                                              activities: viewModel.activities,
                                              calendar: weekGridCalendar)
                            .padding(Theme.Spacing.m)
                            .farmCard()

                        selectedDayCard
                        scheduleSection
                        viewAllButton
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.top, Theme.Spacing.m)
                    // Keeps the last card clear of the floating bottom tab bar.
                    .padding(.bottom, 110)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundLayer)
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
                AddEditActivityView(mode: .add(defaultActivityDate, .watering)) { viewModel.addActivity($0) }
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

    /// Custom in-body header: a fixed green-gradient rounded-bottom bar,
    /// always laid out above the `ScrollView` in `body`'s `VStack` (so the
    /// scroll content starts right below it) — app icon, "SMART CALENDAR"
    /// title + today's date, and a bell with an overdue-count badge. Tapping
    /// the bell switches the bottom tab bar to the "ការជូនដំណឹង" tab
    /// (`AppEnvironment.selectedTab`) instead of pushing a second copy of
    /// that same list, so the tab bar's highlight always matches what's on
    /// screen.
    private var header: some View {
        HStack(spacing: Theme.Spacing.m) {
            CalendarLogoView(size: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(L("appWelcome.splashTitle"))
                    .font(.system(size: 20, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(.white)
                // Today's date (not a static tagline) — e.g. "ថ្ងៃច័ន្ទ ៩
                // វិច្ឆិកា ២០២៦" — `lineSpacing` + `fixedSize` so the full
                // Khmer string never gets clipped if it needs 2 lines.
                Text(LocalizedDate.headlineString(Date()))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: switchToNotificationsTab) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(CalendarTheme.farmGreen)
                        .frame(width: 40, height: 40)

                    if overdueCount > 0 {
                        Text(LocalizedDate.localizedNumber(min(overdueCount, 99)))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Theme.expense))
                            .offset(x: 6, y: -6)
                    }
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(headerBackground)
    }

    /// Flat, single-color `#2E7D32` bar — a plain `Rectangle` (no corner
    /// radius, no gradient, no decoration) bled into the top safe area
    /// (behind the status bar/Dynamic Island) via `ignoresSafeArea` — the
    /// only place that modifier is used in this header, so it never affects
    /// the header's own layout height — with a very subtle shadow
    /// separating it from the content sliding underneath it.
    private var headerBackground: some View {
        Rectangle()
            .fill(CalendarTheme.deepGreen)
            .ignoresSafeArea(edges: .top)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    /// Switches the shared tab selection to "ការជូនដំណឹង" with the same
    /// spring animation `CustomTabBar` (`MainTabView.swift`) uses for its own
    /// taps, so this behaves identically to tapping that tab directly.
    private func switchToNotificationsTab() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            environment.selectedTab = .notifications
        }
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

    /// Backs the header bell's red count badge — same "ហួសកំណត់" (overdue)
    /// set the Notifications tab's own badge counts, so both read the same number.
    private var overdueCount: Int { viewModel.overdueNotificationItems.count }

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
