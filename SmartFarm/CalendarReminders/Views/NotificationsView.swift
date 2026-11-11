import SwiftUI

/// Which group of records the Notifications tab's segmented control shows.
enum NotificationsSegment: Int, CaseIterable, Identifiable {
    case upcoming, overdue, completed

    var id: Int { rawValue }

    var titleKey: String {
        switch self {
        case .upcoming:  return "notifications.segment.upcoming"
        case .overdue:   return "notifications.segment.overdue"
        case .completed: return "notifications.segment.completed"
        }
    }
}

/// Redesigned "ការជូនដំណឹង" tab: upcoming / overdue / completed activities
/// and reminders in 3 segments. Each row (`NotificationRow`) has a checkbox
/// to mark done or undo, swipe actions, and a trailing status pill. Same
/// green-gradient-header-over-a-white-panel composition as `SettingsView`,
/// scoped to this screen only.
struct NotificationsView: View {
    @ObservedObject var viewModel: CalendarViewModel

    @State private var segment: NotificationsSegment = .upcoming
    @State private var editingActivity: FarmActivity?
    @State private var editingReminder: Reminder?

    // MARK: - Palette (matches `SettingsView`'s header)

    private let headerColor     = Color(red: 0x2E / 255, green: 0x7D / 255, blue: 0x32 / 255)
    private let panelBackground = Color(red: 0xF3 / 255, green: 0xF8 / 255, blue: 0xF1 / 255)

    private let headerBlockHeight: CGFloat = 130
    private let panelTopInset: CGFloat = 104
    private let panelCornerRadius: CGFloat = 28

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                panelBackground.ignoresSafeArea()

                Rectangle()
                    .fill(headerColor)
                    .frame(height: headerBlockHeight)
                    .ignoresSafeArea(edges: .top)
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

                headerTitleBar

                VStack(spacing: 0) {
                    Color.clear.frame(height: panelTopInset)

                    // The rounded white panel wraps only the tabs + list
                    // (not the clear spacer above) — matching `SettingsView`
                    // — so its top edge, and the tabs 16pt below it, land
                    // right under the header instead of the panel painting
                    // over the header and trapping the spacer's height as a
                    // blank gap inside itself.
                    VStack(spacing: 0) {
                        segmentedControl
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        ScrollView {
                            content
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .padding(.bottom, 110)
                        }
                    }
                    .background(
                        RoundedCorner(radius: panelCornerRadius, corners: [.topLeft, .topRight])
                            .fill(panelBackground)
                    )
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.reload()
                viewModel.refreshForCurrentDate()
            }
            .sheet(item: $editingActivity) { activity in
                AddEditActivityView(mode: .edit(activity)) { viewModel.updateActivity($0) }
            }
            .sheet(item: $editingReminder) { reminder in
                AddEditReminderView(mode: .edit(reminder)) { viewModel.updateReminder($0) }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(headerColor)
    }

    // MARK: - Header

    private var headerTitleBar: some View {
        Text(L("notifications.title"))
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 10)
    }

    // MARK: - Segmented control

    private var segmentedControl: some View {
        HStack(spacing: 6) {
            ForEach(NotificationsSegment.allCases) { candidate in
                segmentButton(candidate)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.white))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private func segmentButton(_ candidate: NotificationsSegment) -> some View {
        let isSelected = segment == candidate
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { segment = candidate }
        } label: {
            HStack(spacing: 5) {
                Text(L(candidate.titleKey))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                if candidate == .overdue, overdueCount > 0 {
                    Text(LocalizedDate.localizedNumber(min(overdueCount, 99)))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Theme.expense))
                }
            }
            .foregroundColor(isSelected ? .white : CalendarTheme.mutedText)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(isSelected ? CalendarTheme.deepGreen : Color.clear))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var overdueCount: Int { viewModel.overdueNotificationItems.count }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if items.isEmpty {
            emptyState
        } else {
            VStack(spacing: 12) {
                ForEach(items) { item in
                    NotificationRow(item: item, segment: segment,
                                     onToggle: { toggle(item) },
                                     onTap: { openEditor(for: item) },
                                     onDelete: { viewModel.deleteItem(item) })
                }
            }
        }
    }

    private var items: [AgendaItem] {
        switch segment {
        case .upcoming:  return viewModel.upcomingNotificationItems
        case .overdue:   return viewModel.overdueNotificationItems
        case .completed: return viewModel.completedNotificationItems
        }
    }

    /// Animates the row's move out of the current segment (a short fade +
    /// shrink) instead of it just vanishing/appearing instantly.
    private func toggle(_ item: AgendaItem) {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.toggleCompleted(item)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: emptyIcon)
                .font(.system(size: 30, weight: .medium))
                .foregroundColor(CalendarTheme.mutedText.opacity(0.6))
            Text(L(emptyMessageKey))
                .font(Theme.Fonts.body.weight(.medium))
                .foregroundColor(CalendarTheme.mutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .farmCard()
    }

    private var emptyIcon: String {
        switch segment {
        case .upcoming:  return "bell.fill"
        case .overdue:   return "checkmark.seal.fill"
        case .completed: return "tray.fill"
        }
    }

    private var emptyMessageKey: String {
        switch segment {
        case .upcoming:  return "notifications.empty.upcoming"
        case .overdue:   return "notifications.empty.overdue"
        case .completed: return "notifications.empty.completed"
        }
    }

    private func openEditor(for item: AgendaItem) {
        switch item {
        case .activity(let activity): editingActivity = activity
        case .reminder(let reminder): editingReminder = reminder
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        let environment = AppEnvironment(persistence: .preview)
        NotificationsView(viewModel: environment.makeCalendarViewModel())
    }
}
