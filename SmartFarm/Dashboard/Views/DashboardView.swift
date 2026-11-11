import SwiftUI

/// Home tab — greeting header, today card, a 2×2 grid of shortcuts into the
/// rest of the app, and the upcoming (7-day) schedule. No Finance tile (the
/// app has no finance feature) and no Calendar tile (the today card above,
/// and the Calendar tab itself, already open it). Deeper stats live behind
/// the "ស្ថិតិ" grid tile (`ReportsView`) instead of on this screen.
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @Binding private var selectedTab: AppTab
    private let environment: AppEnvironment

    /// Owned by the container (`DashboardTabContainerView`) rather than
    /// private `@State` here, so a sheet opened from elsewhere could reuse
    /// it — kept from the previous layout's plumbing.
    @Binding private var addingActivity: Bool
    @State private var editingActivity: FarmActivity?
    @State private var editingReminder: Reminder?
    @State private var showingReports = false
    /// The category the quick-add sheet opens with — set by whichever
    /// entry point triggered it (the "បន្ថែមសកម្មភាព" card defaults to
    /// `.watering`, a quick chip sets its own type, the "បញ្ចូលដំណាំ" grid
    /// tile also goes through this same path) so there's one shared sheet
    /// instead of a separate one per entry point.
    @State private var quickAddCategory: FarmActivityCategory = .watering

    // MARK: - Palette
    //
    // All colors below are built as `Double(0x..) / 255.0` (explicit numerator
    // cast + float denominator) rather than from named assets, so this screen
    // never inherits `AppPrimary`/`AppPrimaryDeep` or any other catalog color.
    // `todayCardStart`/`todayCardEnd` are #66BB6A → #2E7D32 — no `.opacity()`,
    // `.saturation()`, `.blendMode()`, or dark overlay touches this gradient
    // anywhere in this file.

    private let pageBackground      = Color(red: Double(0xF3) / 255.0, green: Double(0xF8) / 255.0, blue: Double(0xF1) / 255.0)
    private let headerTitleGreen    = Color(red: Double(0x1B) / 255.0, green: Double(0x5E) / 255.0, blue: Double(0x20) / 255.0)
    private let headerSubtitleGreen = Color(red: Double(0x4E) / 255.0, green: Double(0x6E) / 255.0, blue: Double(0x50) / 255.0)
    private let todayCardStart      = Color(red: Double(0x66) / 255.0, green: Double(0xBB) / 255.0, blue: Double(0x6A) / 255.0)
    private let todayCardEnd        = Color(red: Double(0x2E) / 255.0, green: Double(0x7D) / 255.0, blue: Double(0x32) / 255.0)
    private let viewAllGreen        = Color(red: Double(0x2E) / 255.0, green: Double(0x7D) / 255.0, blue: Double(0x32) / 255.0)
    private let pillGreen           = Color(red: Double(0x2E) / 255.0, green: Double(0x7D) / 255.0, blue: Double(0x32) / 255.0)
    private let gridLabelColor      = Color(red: Double(0x1F) / 255.0, green: Double(0x3D) / 255.0, blue: Double(0x24) / 255.0)
    private let scheduleSubtextGray = Color(red: Double(0x7A) / 255.0, green: Double(0x8E) / 255.0, blue: Double(0x82) / 255.0)
    private let headerCardBackground = Color.white.opacity(0.94)

    init(environment: AppEnvironment, selectedTab: Binding<AppTab>, addingActivity: Binding<Bool>) {
        self.environment = environment
        _viewModel = StateObject(wrappedValue: environment.makeDashboardViewModel())
        _selectedTab = selectedTab
        _addingActivity = addingActivity
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundLayer

                // `header` sits above the `ScrollView` in its own row (not
                // inside it) so it — and its own white card background —
                // stay fixed on screen while only the cards below it scroll.
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, Theme.Spacing.m)
                        .padding(.bottom, Theme.Spacing.s)

                    ScrollView {
                        VStack(spacing: Theme.Spacing.m) {
                            todayCard
                            quickAddCard
                            quickAddChips
                            gridMenu
                            upcomingSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, Theme.Spacing.s)
                        // Keeps the last card clear of the floating bottom tab bar.
                        .padding(.bottom, 110)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Hidden push link — the "ស្ថិតិ" grid tile triggers this
                // instead of wrapping the whole tile in a `NavigationLink`,
                // so the tile keeps its own tap styling.
                NavigationLink(
                    destination: ReportsView(activityRepository: environment.activityRepository,
                                              reminderRepository: environment.reminderRepository),
                    isActive: $showingReports
                ) { EmptyView() }
                .hidden()
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.reload()
                viewModel.refreshForCurrentDate()
            }
            .sheet(isPresented: $addingActivity) {
                AddEditActivityView(mode: .add(Date(), quickAddCategory)) { viewModel.addActivity($0) }
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

    // MARK: - Background

    /// Top ~30% shows the onboarding photo fading into the page's light
    /// background, so the rest of the scrolling content stays clean and
    /// readable instead of sitting on a full-screen photo.
    private var backgroundLayer: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                pageBackground

                fieldPhoto
                    .frame(width: geo.size.width, height: geo.size.height * 0.32)
                    .clipped()

                LinearGradient(colors: [pageBackground.opacity(0), pageBackground],
                                startPoint: .top, endPoint: .bottom)
                    .frame(width: geo.size.width, height: geo.size.height * 0.32)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }

    private var fieldPhoto: some View {
        Group {
            if UIImage(named: "onboarding_bg") != nil {
                Image("onboarding_bg")
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(colors: [todayCardStart.opacity(0.6), pageBackground],
                                startPoint: .top, endPoint: .bottom)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Theme.Spacing.s) {
            CalendarLogoView(size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(L("home.greeting"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(headerTitleGreen)
                Text(L("home.greetingSubtitle"))
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(headerSubtitleGreen)
            }

            Spacer()

            Button(action: switchToNotificationsTab) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(todayCardEnd)
                        .frame(width: 40, height: 40)

                    if viewModel.overdueCount > 0 {
                        Text(LocalizedDate.localizedNumber(min(viewModel.overdueCount, 99)))
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
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.vertical, Theme.Spacing.s)
        .background(headerCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    /// Switches the shared tab selection to "ការជូនដំណឹង" — same spring
    /// animation `CalendarTabView`'s own header bell uses, so both behave
    /// identically.
    private func switchToNotificationsTab() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            selectedTab = .notifications
        }
    }

    // MARK: - Today card

    private var todayCard: some View {
        Button(action: { selectedTab = .calendar }) {
            ZStack(alignment: .trailing) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 120))
                    .foregroundColor(.white.opacity(0.2))
                    .rotationEffect(.degrees(-15))
                    .offset(x: 26, y: 14)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .semibold))
                            Text(L("home.todayCard.title"))
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.92))

                        Text(LocalizedDate.headlineString(Date()))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(Theme.Spacing.m)
            }
            .background(
                TwoStopGradient(start: todayCardStart, end: todayCardEnd, axis: .vertical)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: todayCardEnd.opacity(0.35), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Quick add

    /// Full-width "បន្ថែមសកម្មភាព" shortcut — opens the same
    /// `AddEditActivityView` sheet as the "បញ្ចូលដំណាំ" grid tile below
    /// (via the shared `addingActivity`/`quickAddCategory` state), dated
    /// today, defaulting to the "ស្រោចទឹក" type.
    private var quickAddCard: some View {
        Button(action: { startQuickAdd(category: .watering) }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(todayCardEnd).frame(width: 40, height: 40)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(L("home.quickAdd.title"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(headerTitleGreen)
                        .lineLimit(1)
                    Text(L("home.quickAdd.subtitle"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(headerSubtitleGreen)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(headerSubtitleGreen.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    /// One type per quick chip — the most common activity types, so logging
    /// routine work (watering, fertilizing, harvest, pest spray) is a single
    /// tap into a pre-filled form. "ដាំដុះ" (planting) has no chip since the
    /// "បញ្ចូលដំណាំ" grid tile already covers it.
    private struct QuickChip: Identifiable {
        let id: FarmActivityCategory
        let icon: String
        let label: String
    }

    private var quickAddChipsData: [QuickChip] {
        [
            QuickChip(id: .watering, icon: "drop.fill", label: FarmActivityCategory.watering.displayName),
            QuickChip(id: .fertilizing, icon: "cross.vial.fill", label: FarmActivityCategory.fertilizing.displayName),
            QuickChip(id: .harvest, icon: "shippingbox.fill", label: FarmActivityCategory.harvest.displayName),
            QuickChip(id: .care, icon: "ant.fill", label: L("home.quickChip.spray"))
        ]
    }

    private var quickAddChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(quickAddChipsData) { chip in
                    quickAddChipButton(chip)
                }
            }
        }
    }

    private func quickAddChipButton(_ chip: QuickChip) -> some View {
        Button(action: { startQuickAdd(category: chip.id) }) {
            HStack(spacing: 6) {
                Image(systemName: chip.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(chip.id.color)
                Text(chip.label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(gridLabelColor)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(chip.id.tintColor))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func startQuickAdd(category: FarmActivityCategory) {
        quickAddCategory = category
        addingActivity = true
    }

    // MARK: - Grid menu

    private var gridMenu: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(GridTile.all) { tile in
                gridTileButton(tile)
            }
        }
    }

    private func gridTileButton(_ tile: GridTile) -> some View {
        Button(action: { handleGridTap(tile.action) }) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    Image(systemName: tile.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(tile.iconColor)
                }
                Text(L(tile.labelKey))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(gridLabelColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(tile.background)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func handleGridTap(_ action: GridTile.Action) {
        switch action {
        case .addActivity:   startQuickAdd(category: .watering)
        case .notifications: selectedTab = .notifications
        case .reports:        showingReports = true
        case .settings:       selectedTab = .settings
        }
    }

    // MARK: - Upcoming schedule

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .foregroundColor(viewAllGreen)
                Text(L("home.upcoming.title"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(headerTitleGreen)
            }

            if scheduleEntries.isEmpty {
                emptyScheduleState
            } else {
                VStack(spacing: 10) {
                    ForEach(scheduleEntries.prefix(3)) { entry in
                        scheduleRow(entry)
                    }
                }
                viewAllRow
            }
        }
    }

    private var viewAllRow: some View {
        Button(action: { selectedTab = .calendar }) {
            HStack(spacing: 4) {
                Text(L("home.upcoming.viewAll"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(viewAllGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var emptyScheduleState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 30, weight: .medium))
                .foregroundColor(headerSubtitleGreen.opacity(0.6))
            Text(L("home.upcoming.empty"))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(scheduleSubtextGray)
            Button(action: { startQuickAdd(category: .watering) }) {
                Text(L("calendar.addActivity"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(todayCardEnd)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func scheduleRow(_ entry: ScheduleEntry) -> some View {
        Button(action: { openEditor(for: entry) }) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(entry.tintColor)
                        .frame(width: 44, height: 44)
                    Image(systemName: entry.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(entry.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text("\(LocalizedDate.dayMonthString(entry.date)) · \(LocalizedDate.timeString(entry.date))")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundColor(scheduleSubtextGray)
                }

                Spacer()

                pillBadge(for: entry.date)
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func pillBadge(for date: Date) -> some View {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfItem = calendar.startOfDay(for: date)
        let daysAway = max(calendar.dateComponents([.day], from: startOfToday, to: startOfItem).day ?? 0, 0)

        let text: String
        switch daysAway {
        case 0:  text = L("home.pill.today")
        case 1:  text = L("home.pill.tomorrow")
        default: text = String(format: L("home.pill.daysLeft"), LocalizedDate.localizedNumber(daysAway))
        }

        return Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(pillGreen)
            .clipShape(Capsule())
    }

    private func openEditor(for entry: ScheduleEntry) {
        switch entry {
        case .activity(let activity): editingActivity = activity
        case .reminder(let reminder): editingReminder = reminder
        }
    }

    private var scheduleEntries: [ScheduleEntry] {
        (viewModel.scheduleActivities().map(ScheduleEntry.activity) +
         viewModel.scheduleReminders().map(ScheduleEntry.reminder))
            .sorted { $0.date < $1.date }
    }
}

/// One shortcut tile in the Home screen's 2×2 grid menu. Finance has no
/// tile (the app has no finance feature) and Calendar has no tile (the
/// green today card above, and the Calendar tab itself, already open it).
/// "ការជូនដំណឹង" and "ការកំណត់" switch `selectedTab` (shared app-wide via
/// `AppEnvironment`) rather than opening anything of their own, so there's
/// never a second page duplicating a tab that already exists.
private struct GridTile: Identifiable {
    enum Action {
        case addActivity, notifications, reports, settings
    }

    let id: String
    let labelKey: String
    let icon: String
    let iconColor: Color
    let background: Color
    let action: Action

    // One shade deeper than before (Material's "200" tier instead of "100")
    // so each card reads as a distinct, more vivid pastel shape against the
    // near-white `pageBackground` (#F3F8F1) and the white icon circle on top
    // of it stands out more.
    private static let lightGreen   = Color(red: Double(0xA5) / 255.0, green: Double(0xD6) / 255.0, blue: Double(0xA7) / 255.0)
    private static let sageGreen    = Color(red: Double(0x80) / 255.0, green: Double(0xCB) / 255.0, blue: Double(0xC4) / 255.0)
    private static let lightOrange  = Color(red: Double(0xFF) / 255.0, green: Double(0xCC) / 255.0, blue: Double(0x80) / 255.0)
    private static let lightGrayBlue = Color(red: Double(0xB0) / 255.0, green: Double(0xBE) / 255.0, blue: Double(0xC5) / 255.0)

    static let all: [GridTile] = [
        GridTile(id: "addCrop", labelKey: "home.grid.addCrop", icon: "leaf.fill",
                 iconColor: Color(red: Double(0x2E) / 255.0, green: Double(0x7D) / 255.0, blue: Double(0x32) / 255.0),
                 background: lightGreen, action: .addActivity),
        GridTile(id: "notifications", labelKey: "notifications.title", icon: "bell.fill",
                 iconColor: Color(red: Double(0xF5) / 255.0, green: Double(0x7C) / 255.0, blue: Double(0x00) / 255.0),
                 background: lightOrange, action: .notifications),
        GridTile(id: "reports", labelKey: "home.grid.stats", icon: "chart.bar.fill",
                 iconColor: Color(red: Double(0x38) / 255.0, green: Double(0x8E) / 255.0, blue: Double(0x3C) / 255.0),
                 background: sageGreen, action: .reports),
        GridTile(id: "settings", labelKey: "tab.settings", icon: "gearshape.fill",
                 iconColor: Color(red: Double(0x60) / 255.0, green: Double(0x7D) / 255.0, blue: Double(0x8B) / 255.0),
                 background: lightGrayBlue, action: .settings)
    ]
}

/// A farm activity or reminder, unified for display in the Home screen's
/// upcoming-schedule list.
private enum ScheduleEntry: Identifiable {
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

    var accentColor: Color {
        switch self {
        case .activity(let a): return a.category.color
        case .reminder: return Theme.brand
        }
    }

    var tintColor: Color {
        switch self {
        case .activity(let a): return a.category.tintColor
        case .reminder: return Theme.reminderTint
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(environment: AppEnvironment(persistence: .preview), selectedTab: .constant(.home), addingActivity: .constant(false))
    }
}
