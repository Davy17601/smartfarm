import SwiftUI

/// Reports screen: monthly farm-activity chart, completed/upcoming summary,
/// and CSV / PDF export. Pushed from the Settings tab.
struct ReportsView: View {
    @StateObject private var viewModel: ReportsViewModel
    @State private var shareItems: [Any] = []
    @State private var showingShare = false

    init(activityRepository: FarmActivityRepositoryProtocol,
         reminderRepository: ReminderRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: ReportsViewModel(
            activityRepository: activityRepository,
            reminderRepository: reminderRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.m) {
                FarmCard {
                    SectionHeader(L("reports.last6"))
                    MonthlyActivityBarChartView(counts: viewModel.monthlyActivityCounts)
                        .frame(height: 220)
                }

                FarmCard {
                    SectionHeader(L("reports.byCategory"))
                    categoryBreakdown
                }

                FarmCard {
                    SectionHeader(L("reports.summary"))
                    HStack(spacing: Theme.Spacing.s) {
                        SummaryCardView(title: L("reports.completedActivities"),
                                        value: "\(viewModel.completedActivitiesCount)",
                                        systemImage: "checkmark.circle.fill", tint: Theme.income)
                        SummaryCardView(title: L("reports.upcomingActivities"),
                                        value: "\(viewModel.upcomingActivitiesCount)",
                                        systemImage: "calendar", tint: Theme.brand)
                    }
                    HStack(spacing: Theme.Spacing.s) {
                        SummaryCardView(title: L("reports.completedReminders"),
                                        value: "\(viewModel.completedRemindersCount)",
                                        systemImage: "checkmark.circle.fill", tint: Theme.income)
                        SummaryCardView(title: L("reports.upcomingReminders"),
                                        value: "\(viewModel.upcomingRemindersCount)",
                                        systemImage: "bell.fill", tint: Theme.brand)
                    }
                }

                PrimaryButton(title: L("reports.exportCSV"), systemImage: "tablecells") { exportCSV() }
                PrimaryButton(title: L("reports.exportPDF"), systemImage: "doc.richtext") { exportPDF() }
            }
            .padding(Theme.Spacing.m)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(L("reports.title"))
        .onAppear { viewModel.reload() }
        .sheet(isPresented: $showingShare) { ActivityShareSheet(items: shareItems) }
    }

    private var categoryBreakdown: some View {
        VStack(spacing: Theme.Spacing.s) {
            ForEach(viewModel.activityCategoryCounts, id: \.category) { entry in
                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: entry.category.systemImage)
                        .foregroundColor(entry.category.color)
                        .frame(width: 22)
                    Text(entry.category.displayName)
                        .font(Theme.Fonts.body)
                        .foregroundColor(Theme.primaryText)
                    Spacer()
                    Text("\(entry.count)")
                        .font(Theme.Fonts.body.monospacedDigit())
                        .foregroundColor(Theme.secondaryText)
                }
            }
        }
    }

    private func exportCSV() {
        guard let url = ReportExporter.csvFile(activities: viewModel.activities,
                                               reminders: viewModel.reminders) else { return }
        present([url])
    }

    private func exportPDF() {
        guard let url = ReportExporter.pdfFile(
            activities: viewModel.activities,
            reminders: viewModel.reminders,
            monthlyActivityCounts: viewModel.monthlyActivityCounts
        ) else { return }
        present([url])
    }

    private func present(_ items: [Any]) {
        shareItems = items
        showingShare = true
    }
}
