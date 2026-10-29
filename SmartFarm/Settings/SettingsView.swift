import SwiftUI

/// Provides monthly income/expense data for the Settings chart
final class SettingsViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var monthlyTotals: [MonthlyTotal] = []

    private(set) var currency: Currency = .khr
    private let repository: TransactionRepositoryProtocol

    init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
    }

    func reload(currency: Currency) {
        self.currency = currency
        transactions = repository.fetchAll()
        monthlyTotals = computeMonthlyTotals(monthsBack: 6)
    }

    private func computeMonthlyTotals(monthsBack: Int) -> [MonthlyTotal] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.language.locale
        formatter.setLocalizedDateFormatFromTemplate("MMM")

        let now = Date()
        let inCurrency = transactions.filter { $0.currency == currency }

        return (0..<monthsBack).reversed().compactMap { offset -> MonthlyTotal? in
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: now),
                  let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start
            else { return nil }

            let monthTx = inCurrency.filter {
                calendar.isDate($0.date, equalTo: monthDate, toGranularity: .month)
            }
            let income = monthTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = monthTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            return MonthlyTotal(monthStart: monthStart,
                                label: formatter.string(from: monthDate),
                                income: income, expense: expense)
        }
    }
}

/// Settings tab — language & currency preferences plus entry points to
/// Reports and Backup & Restore.
struct SettingsView: View {
    let environment: AppEnvironment

    @EnvironmentObject private var coordinator: FinanceCoordinator
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var viewModel: SettingsViewModel
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("farmName") private var farmName = "SmartFarm"
    @AppStorage("farmVillage") private var farmVillage = "ភូមិ"
    @AppStorage("farmProvince") private var farmProvince = "ខេត្ត"

    // Colors
    private let primaryText = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let secondaryText = Color(red: 0.22, green: 0.26, blue: 0.32) // #374151
    private let pageBackground = Color(red: 0.92, green: 0.96, blue: 0.91) // #EAF4E7
    private let brandGreen = Color(red: 0.18, green: 0.49, blue: 0.20) // #2E7D32
    private let deepGreen = Color(red: 0.08, green: 0.32, blue: 0.18) // #14532D

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = StateObject(wrappedValue: SettingsViewModel(repository: environment.transactionRepository))
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                pageBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Landscape banner header
                        landscapeBanner

                        // Content below banner
                        VStack(spacing: 14) {
                            // Farm profile card
                            farmProfileCard

                            // General section
                            generalSection

                            // Data section
                            dataSection

                            // Help section
                            helpSection

                            // Footer
                            footerView
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Landscape Banner

    private var landscapeBanner: some View {
        ZStack(alignment: .topLeading) {
            // Background gradient only
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.75, green: 0.89, blue: 0.77), // #BFE3C4
                    Color(red: 0.92, green: 0.96, blue: 0.91)  // #EAF4E7 (page background)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            // Header content
            HStack(spacing: 12) {
                // Back button - goes to Reports tab
                Button(action: { coordinator.selectedTab = 2 }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(brandGreen)
                        .frame(width: 40, height: 40)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }

                // Title
                Text(L("tab.settings"))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(red: 0.08, green: 0.32, blue: 0.18)) // #14532D

                Spacer()
            }
            .padding(.top, 60)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(height: 116)
    }

    // MARK: - Farm Profile Card

    private var farmProfileCard: some View {
        NavigationLink(destination: FarmProfileEditView()) {
            HStack(spacing: 14) {
                // Rice icon in white circle
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        )
                    Text("🌾")
                        .font(.system(size: 32))
                }
                .frame(width: 60, height: 60)

                // Farm info
                VStack(alignment: .leading, spacing: 4) {
                    Text(farmName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(L("finance.subtitle"))
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("\(farmVillage) / \(farmProvince)")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.08, green: 0.32, blue: 0.18), // #14532D
                        Color(red: 0.11, green: 0.42, blue: 0.18)  // #1B6B2F
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Sections

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title with accent bar
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.11, green: 0.42, blue: 0.18)) // #1B6B2F
                    .frame(width: 4, height: 18)
                Text(L("settings.general"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.11, green: 0.42, blue: 0.18)) // #1B6B2F
            }
            .padding(.horizontal, 4)

            // Card
            VStack(spacing: 0) {
                // Language row
                NavigationLink(destination: LanguageSelectionView()) {
                    coloredSettingsRow(
                        icon: "globe",
                        iconColor: Color(red: 0.15, green: 0.39, blue: 0.92), // #2563EB blue
                        title: L("settings.language"),
                        value: localization.language.displayName
                    )
                }
                .buttonStyle(OpacityButtonStyle())

                Divider().padding(.leading, 70)

                // Currency row
                NavigationLink(destination: CurrencySelectionView()) {
                    coloredSettingsRow(
                        icon: "dollarsign.circle",
                        iconColor: Color(red: 0.85, green: 0.47, blue: 0.04), // #D97706 amber
                        title: L("settings.displayCurrency"),
                        value: settings.displayCurrency.displayName
                    )
                }
                .buttonStyle(OpacityButtonStyle())

                Divider().padding(.leading, 70)

                // Notifications row
                NavigationLink(destination: NotificationSettingsView()) {
                    coloredSettingsRow(
                        icon: "bell",
                        iconColor: Color(red: 0.86, green: 0.15, blue: 0.15), // #DC2626 red
                        title: L("settings.notifications"),
                        value: notificationsEnabled ? "ទទួល" : "បិទ"
                    )
                }
                .buttonStyle(OpacityButtonStyle())
            }
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title with accent bar
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.11, green: 0.42, blue: 0.18)) // #1B6B2F
                    .frame(width: 4, height: 18)
                Text(L("settings.data"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.11, green: 0.42, blue: 0.18)) // #1B6B2F
            }
            .padding(.horizontal, 4)

            // Card
            VStack(spacing: 0) {
                // Backup row
                NavigationLink(destination: BackupDataView(environment: environment)) {
                    coloredSettingsRow(
                        icon: "icloud.and.arrow.up",
                        iconColor: Color(red: 0.08, green: 0.50, blue: 0.24), // #15803D deep green
                        title: L("settings.backupData"),
                        value: nil
                    )
                }
                .buttonStyle(OpacityButtonStyle())

                Divider().padding(.leading, 70)

                // Reports row - navigates to Reports tab
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        coordinator.selectedTab = 2
                    }
                }) {
                    coloredSettingsRow(
                        icon: "chart.bar.fill",
                        iconColor: Color(red: 0.15, green: 0.39, blue: 0.92), // #2563EB blue
                        title: L("settings.reports"),
                        value: nil
                    )
                }
                .buttonStyle(OpacityButtonStyle())
            }
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
        }
    }

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title with accent bar
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.11, green: 0.42, blue: 0.18)) // #1B6B2F
                    .frame(width: 4, height: 18)
                Text(L("settings.help"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.11, green: 0.42, blue: 0.18)) // #1B6B2F
            }
            .padding(.horizontal, 4)

            // Card
            VStack(spacing: 0) {
                // Help & FAQ row
                NavigationLink(destination: HelpFAQView()) {
                    coloredSettingsRow(
                        icon: "questionmark.circle",
                        iconColor: Color(red: 0.49, green: 0.23, blue: 0.93), // #7C3AED purple
                        title: L("settings.helpFAQ"),
                        value: nil
                    )
                }
                .buttonStyle(OpacityButtonStyle())

                Divider().padding(.leading, 70)

                // About row
                NavigationLink(destination: AboutAppView()) {
                    coloredSettingsRow(
                        icon: "info.circle",
                        iconColor: Color(red: 0.06, green: 0.46, blue: 0.43), // #0F766E teal
                        title: L("settings.aboutApp"),
                        value: nil
                    )
                }
                .buttonStyle(OpacityButtonStyle())
            }
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
        }
    }

    // Footer
    private var footerView: some View {
        VStack(spacing: 8) {
            Text("SmartFarm · Small Farm, Big Future")
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.29, green: 0.34, blue: 0.39)) // #4B5563

            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                Text("v\(version)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.29, green: 0.34, blue: 0.39).opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Helper Views

    private func coloredSettingsRow(icon: String, iconColor: Color, title: String, value: String?) -> some View {
        HStack(spacing: 14) {
            // Colored icon box
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: 38, height: 38)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryText)

            Spacer()

            if let value = value {
                Text(value)
                    .font(.system(size: 15))
                    .foregroundColor(secondaryText)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(secondaryText)
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

// MARK: - Button Styles

struct OpacityButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Grouped Bar Chart Component

/// Grouped/paired bar chart showing income (green) vs expense (red) per month
/// Custom implementation for iOS 14 (Swift Charts requires iOS 16+)
struct IncomeExpenseBarChartView: View {
    let totals: [MonthlyTotal]
    let currency: Currency

    private var maxValue: Double {
        let allValues = totals.flatMap { [$0.income, $0.expense] }
        return max(allValues.max() ?? 0, 1)
    }

    var body: some View {
        if totals.isEmpty {
            Text(L("reports.noData")).foregroundColor(Theme.secondaryText)
        } else {
            VStack(spacing: Theme.Spacing.m) {
                // Title and Legend
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text(L("settings.chartTitle"))
                        .font(Theme.Fonts.heading)
                        .foregroundColor(Theme.primaryText)

                    HStack(spacing: Theme.Spacing.m) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Rectangle()
                                .fill(Color(red: 0.13, green: 0.55, blue: 0.13))
                                .frame(width: 16, height: 16)
                                .cornerRadius(3)
                            Text(L("finance.income"))
                                .font(Theme.Fonts.caption)
                                .foregroundColor(Theme.secondaryText)
                        }
                        HStack(spacing: Theme.Spacing.xs) {
                            Rectangle()
                                .fill(Color(red: 0.8, green: 0.1, blue: 0.1))
                                .frame(width: 16, height: 16)
                                .cornerRadius(3)
                            Text(L("finance.expense"))
                                .font(Theme.Fonts.caption)
                                .foregroundColor(Theme.secondaryText)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Chart
                HStack(alignment: .bottom, spacing: 0) {
                    // Y-axis labels
                    yAxisLabels
                        .frame(width: 40)

                    // Bars
                    GeometryReader { geo in
                        HStack(alignment: .bottom, spacing: Theme.Spacing.xs) {
                            ForEach(totals) { total in
                                barGroup(for: total, maxHeight: geo.size.height)
                            }
                        }
                    }
                }
                .frame(height: 200)

                // X-axis labels (month names)
                HStack(spacing: Theme.Spacing.xs) {
                    Spacer().frame(width: 40) // Offset for Y-axis
                    ForEach(totals) { total in
                        Text(total.label)
                            .font(Theme.Fonts.caption)
                            .foregroundColor(Theme.secondaryText)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var yAxisLabels: some View {
        VStack(alignment: .trailing) {
            ForEach(0..<5) { i in
                let value = maxValue * Double(4 - i) / 4
                Text(formatYAxisValue(value))
                    .font(.system(size: 10))
                    .foregroundColor(Theme.secondaryText)
                if i < 4 {
                    Spacer()
                }
            }
        }
    }

    private func formatYAxisValue(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }

    private func barGroup(for total: MonthlyTotal, maxHeight: CGFloat) -> some View {
        HStack(spacing: 2) {
            // Income bar (green)
            Rectangle()
                .fill(Color(red: 0.13, green: 0.55, blue: 0.13))
                .frame(height: barHeight(for: total.income, maxHeight: maxHeight))
                .cornerRadius(3)

            // Expense bar (red)
            Rectangle()
                .fill(Color(red: 0.8, green: 0.1, blue: 0.1))
                .frame(height: barHeight(for: total.expense, maxHeight: maxHeight))
                .cornerRadius(3)
        }
        .frame(maxWidth: .infinity)
    }

    private func barHeight(for value: Double, maxHeight: CGFloat) -> CGFloat {
        guard maxValue > 0 else { return 0 }
        return max(CGFloat(value / maxValue) * maxHeight, value > 0 ? 2 : 0)
    }
}
