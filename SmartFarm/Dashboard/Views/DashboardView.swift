import SwiftUI

/// Home tab: today's schedule and the upcoming week of farm activities & reminders.
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @Binding private var selectedTab: Int

    @State private var addingActivity = false
    @State private var addingReminder = false

    init(environment: AppEnvironment, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: environment.makeDashboardViewModel())
        _selectedTab = selectedTab
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundLayer

                ScrollView {
                    VStack(spacing: Theme.Spacing.m) {
                        weekStrip
                        todaySection
                        quickActions
                        upcomingSection
                    }
                    .padding(Theme.Spacing.m)
                }
            }
            .navigationTitle(L("dashboard.title"))
            .onAppear { viewModel.reload() }
            .sheet(isPresented: $addingActivity) {
                AddEditActivityView(mode: .add(Date())) { viewModel.addActivity($0) }
            }
            .sheet(isPresented: $addingReminder) {
                AddEditReminderView(mode: .add(Date())) { viewModel.addReminder($0) }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Background

    /// One continuous full-screen photo, fixed behind the scrolling content
    /// (unlike the plain `Theme.background` fill every other screen uses) —
    /// every card floats on top of it, so this stays scoped to the
    /// Dashboard/Today tab only.
    private var backgroundLayer: some View {
        GeometryReader { geo in
            ZStack {
                Image("anime-rainbow-landscape")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .opacity(0.9)
                    .clipped()

                // Wash the image so its colors are muted behind the cards.
                Color.white.opacity(0.4)
            }
        }
        // Only bleed into the top safe area (status bar / nav bar); leave the
        // bottom safe area alone so the image stops above the tab bar instead
        // of showing through it.
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Week strip

    private var weekStrip: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        return TranslucentCard {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(days, id: \.self) { day in
                    let isToday = calendar.isDateInToday(day)
                    VStack(spacing: 4) {
                        Text(LocalizedDate.weekdayAbbreviation(for: day, calendar: calendar))
                            .font(Theme.Fonts.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .foregroundColor(Theme.secondaryText)
                        Text("\(calendar.component(.day, from: day))")
                            .font(Theme.Fonts.heading)
                            .frame(width: 28, height: 28)
                            .background(isToday ? Theme.brand : Color.clear)
                            .foregroundColor(isToday ? .white : Theme.primaryText)
                            .clipShape(Circle())
                        Circle()
                            .fill(viewModel.hasSchedule(on: day) ? Theme.brand : Color.clear)
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedTab = 2 }
                }
            }
        }
    }

    // MARK: - Today

    private var todaySection: some View {
        let items = scheduleItems(activities: viewModel.todayActivities(), reminders: viewModel.todayReminders())
        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(L("dashboard.todaySchedule")) {
                Text(LocalizedDate.mediumString(Date()))
                    .font(Theme.Fonts.caption).foregroundColor(Theme.secondaryText)
            }
            if items.isEmpty {
                TranslucentCard {
                    // A second, discoverable way (besides the "+" leaf quick
                    // action below) to start adding something when nothing
                    // is scheduled for today.
                    Button(action: { addingActivity = true }) {
                        Text(L("dashboard.noScheduleToday"))
                            .foregroundColor(Theme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(DimOnPressButtonStyle())
                }
            } else {
                TranslucentCard {
                    ForEach(items) { item in
                        scheduleRow(item, timeString: LocalizedDate.timeString(item.date))
                        if item.id != items.last?.id { Divider() }
                    }
                }
            }
        }
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        HStack(spacing: Theme.Spacing.s) {
            quickAction(title: L("calendar.addActivity"), systemImage: "leaf.fill") { addingActivity = true }
            quickAction(title: L("calendar.addReminder"), systemImage: "bell.fill") { addingReminder = true }
        }
    }

    private func quickAction(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.s) {
                Image(systemName: systemImage).font(.title2)
                Text(title).font(Theme.Fonts.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.m)
            .background(Color.white.opacity(0.88))
            .foregroundColor(Theme.brand)
            .cornerRadius(Theme.Radius.card)
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Upcoming

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(L("dashboard.next7")) {
                Button(L("tab.calendar")) { selectedTab = 2 }
                    .font(Theme.Fonts.caption).foregroundColor(Theme.brand)
            }
            let items = scheduleItems(activities: viewModel.upcomingActivities(), reminders: viewModel.upcomingReminders())
            if items.isEmpty {
                TranslucentCard {
                    // Jumps to the Calendar tab, the same "view full
                    // schedule" destination the header button above links to.
                    Button(action: { selectedTab = 2 }) {
                        Text(L("dashboard.noSchedule"))
                            .foregroundColor(Theme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(DimOnPressButtonStyle())
                }
            } else {
                TranslucentCard {
                    ForEach(items) { item in
                        scheduleRow(item, timeString: LocalizedDate.dayMonthString(item.date))
                        if item.id != items.last?.id { Divider() }
                    }
                }
            }
        }
    }

    // MARK: - Shared row

    private func scheduleRow(_ item: ScheduleItem, timeString: String) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: item.icon).foregroundColor(item.tint).frame(width: 24)
            Text(item.title)
                .strikethrough(item.isCompleted)
                .foregroundColor(item.isCompleted ? Theme.secondaryText : Theme.primaryText)
            Spacer()
            Text(timeString)
                .font(Theme.Fonts.caption).foregroundColor(Theme.secondaryText)
        }
        .padding(.vertical, 4)
    }

    private func scheduleItems(activities: [FarmActivity], reminders: [Reminder]) -> [ScheduleItem] {
        (activities.map(ScheduleItem.activity) + reminders.map(ScheduleItem.reminder))
            .sorted { $0.date < $1.date }
    }
}

/// A semi-transparent white card, in place of `FarmCard`'s solid
/// `Theme.cardBackground` — this screen sits its content over a photo
/// background, so cards here need to stay legible without going fully
/// opaque. Scoped to the Dashboard/Today tab only; every other screen keeps
/// using `FarmCard`.
private struct TranslucentCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.m)
        .background(Color.white.opacity(0.88))
        .cornerRadius(Theme.Radius.card)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

/// Light tap feedback (slight dimming) for the tappable empty-state texts
/// above — same press-triggered, `ScaleButtonStyle`-style affordance used for
/// tappable empty states on the Calendar tab, but opacity-based since these
/// are plain text rows rather than icon/card buttons.
private struct DimOnPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// A farm activity or reminder, unified for display in the Dashboard's schedule lists.
private enum ScheduleItem: Identifiable {
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

    var icon: String {
        switch self {
        case .activity(let a): return a.category.systemImage
        case .reminder: return "bell.fill"
        }
    }

    var tint: Color {
        switch self {
        case .activity(let a): return a.category.color
        case .reminder: return Theme.brand
        }
    }

    var isCompleted: Bool {
        switch self {
        case .activity(let a): return a.isCompleted
        case .reminder(let r): return r.isCompleted
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(environment: AppEnvironment(persistence: .preview), selectedTab: .constant(0))
    }
}
