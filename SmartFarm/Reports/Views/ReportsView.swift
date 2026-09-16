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

                // Category breakdown pie chart
                categoryPieChartCard

                PrimaryButton(title: L("reports.exportCSV"), systemImage: "tablecells") { exportCSV() }
                PrimaryButton(title: L("reports.exportPDF"), systemImage: "doc.richtext") { exportPDF() }
            }
            .padding(Theme.Spacing.m)
            .padding(.bottom, 60) // Extra padding to clear tab bar
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(L("reports.title"))
        .onAppear { viewModel.reload(currency: settings.displayCurrency) }
        .onChange(of: settings.displayCurrency) { viewModel.reload(currency: $0) }
        .sheet(isPresented: $showingShare) { ActivityShareSheet(items: shareItems) }
    }

    private var categoryPieChartCard: some View {
        let breakdown = viewModel.categoryBreakdown()
        let slices = breakdown.enumerated().map { index, item in
            PieSliceData(
                category: item.category,
                amount: item.amount,
                percentage: item.percentage,
                color: categoryColor(for: index)
            )
        }

        return Group {
            if !slices.isEmpty {
                FarmCard {
                    SectionHeader(L("reports.expenseByCategory"))
                    CategoryPieChartView(slices: slices, currency: viewModel.currency)
                        .padding(.top, Theme.Spacing.s)
                }
            }
        }
    }

    private func categoryColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .orange, .green, .purple, .pink, .yellow]
        return colors[index % colors.count]
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

// MARK: - Pie Chart Components

/// Data for a single pie slice
struct PieSliceData: Identifiable {
    let id = UUID()
    let category: TransactionCategory
    let amount: Double
    let percentage: Double
    let color: Color
}

/// Custom pie chart showing expense breakdown by category
struct CategoryPieChartView: View {
    let slices: [PieSliceData]
    let currency: Currency

    private let size: CGFloat = 200

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            // Pie chart
            ZStack {
                ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                    PieSlice(
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index)
                    )
                    .fill(slice.color)
                }
            }
            .frame(width: size, height: size)

            // Legend
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                ForEach(slices) { slice in
                    HStack(spacing: Theme.Spacing.s) {
                        Circle()
                            .fill(slice.color)
                            .frame(width: 12, height: 12)
                        Text(slice.category.displayName)
                            .font(Theme.Fonts.caption)
                            .foregroundColor(Theme.primaryText)
                        Spacer()
                        Text("\(Int(slice.percentage))%")
                            .font(Theme.Fonts.caption.weight(.medium))
                            .foregroundColor(Theme.secondaryText)
                        Text(CurrencyFormatter.string(slice.amount, currency: currency))
                            .font(Theme.Fonts.caption.monospacedDigit())
                            .foregroundColor(Theme.primaryText)
                    }
                }
            }
        }
    }

    private func startAngle(for index: Int) -> Angle {
        let previousPercentages = slices.prefix(index).reduce(0.0) { $0 + $1.percentage }
        return Angle(degrees: previousPercentages * 3.6 - 90)
    }

    private func endAngle(for index: Int) -> Angle {
        let percentagesUpTo = slices.prefix(index + 1).reduce(0.0) { $0 + $1.percentage }
        return Angle(degrees: percentagesUpTo * 3.6 - 90)
    }
}

/// A single slice of the pie
struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()

        return path
    }
}
