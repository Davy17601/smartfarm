import SwiftUI

/// Reports screen: monthly profit/loss chart + CSV / PDF export.
/// Pushed from the Settings tab.
struct ReportsView: View {
    @StateObject private var viewModel: ReportsViewModel
    @EnvironmentObject private var settings: AppSettings
    @State private var shareItems: [Any] = []
    @State private var showingShare = false

    init(repository: TransactionRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: ReportsViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.m) {
                FarmCard {
                    SectionHeader(L("reports.last6"))
                    MonthlyBarChartView(totals: viewModel.monthlyTotals, currency: viewModel.currency)
                        .frame(height: 220)
                }

                PrimaryButton(title: L("reports.exportCSV"), systemImage: "tablecells") { exportCSV() }
                PrimaryButton(title: L("reports.exportPDF"), systemImage: "doc.richtext") { exportPDF() }
            }
            .padding(Theme.Spacing.m)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(L("reports.title"))
        .onAppear { viewModel.reload(currency: settings.displayCurrency) }
        .onChange(of: settings.displayCurrency) { viewModel.reload(currency: $0) }
        .sheet(isPresented: $showingShare) { ActivityShareSheet(items: shareItems) }
    }

    private func exportCSV() {
        guard let url = ReportExporter.csvFile(viewModel.transactions) else { return }
        present([url])
    }

    private func exportPDF() {
        guard let url = ReportExporter.pdfFile(
            transactions: viewModel.transactions,
            monthlyTotals: viewModel.monthlyTotals,
            currency: viewModel.currency
        ) else { return }
        present([url])
    }

    private func present(_ items: [Any]) {
        shareItems = items
        showingShare = true
    }
}
