import SwiftUI

/// Standalone "ការជូនដំណឹង" tab — upcoming / overdue / completed activities
/// and reminders in 3 segments (`NotificationsView`), reached either as a
/// bottom tab or via the Calendar tab's bell icon (`AppEnvironment.selectedTab`,
/// not a push — see `CalendarTabView`), so there's a single page for this
/// list no matter which screen you reach it from. Owns its own
/// `CalendarViewModel`, same as `CalendarTabContainerView` and
/// `DashboardTabContainerView` each own their own.
struct NotificationsTabContainerView: View {
    @StateObject private var viewModel: CalendarViewModel

    init(activityRepository: FarmActivityRepositoryProtocol,
         reminderRepository: ReminderRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: CalendarViewModel(
            activityRepository: activityRepository,
            reminderRepository: reminderRepository
        ))
    }

    var body: some View {
        NotificationsView(viewModel: viewModel)
    }
}

struct NotificationsTabContainerView_Previews: PreviewProvider {
    static var previews: some View {
        let environment = AppEnvironment(persistence: .preview)
        NotificationsTabContainerView(activityRepository: environment.activityRepository,
                                       reminderRepository: environment.reminderRepository)
    }
}
