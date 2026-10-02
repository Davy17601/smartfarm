import SwiftUI

struct CalendarTabContainerView: View {
    let activityRepository: FarmActivityRepositoryProtocol
    let reminderRepository: ReminderRepositoryProtocol

    var body: some View {
        CalendarTabView(activityRepository: activityRepository,
                         reminderRepository: reminderRepository)
    }
}

struct CalendarTabContainerView_Previews: PreviewProvider {
    static var previews: some View {
        let environment = AppEnvironment(persistence: .preview)
        CalendarTabContainerView(activityRepository: environment.activityRepository,
                                  reminderRepository: environment.reminderRepository)
    }
}
