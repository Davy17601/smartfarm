import SwiftUI

/// Monthly income/expense/profit chart with bars and line overlay.
/// Bars (income green, expense red) grow upward from bottom baseline.
/// Profit is shown as an orange line connecting points.
struct MonthlyBarChartView: View {
    let totals: [MonthlyTotal]
    let currency: Currency
    @State private var animationProgress: CGFloat = 0

    private var maxValue: Double {
        let allValues = totals.flatMap { [max($0.income, 0), max($0.expense, 0), max(abs($0.profit), 0)] }
        return max(allValues.max() ?? 0, 1)
    }

    var body: some View {
        if totals.isEmpty {
            Text(L("reports.noData")).foregroundColor(Theme.secondaryText)
        } else {
            VStack(spacing: 0) {
                // Chart with Y-axis
                HStack(alignment: .bottom, spacing: 0) {
                    // Y-axis labels
                    yAxisLabels
                        .frame(width: 50)

                    // Chart area with bars and profit line
                    ZStack(alignment: .bottom) {
                        // Income & Expense bars
                        GeometryReader { geo in
                            HStack(alignment: .bottom, spacing: Theme.Spacing.m) {
                                ForEach(totals) { total in
                                    monthBarGroup(for: total, height: geo.size.height)
                                }
                            }
                            .frame(height: geo.size.height)
                        }

                        // Profit line overlay
                        GeometryReader { geo in
                            profitLine(height: geo.size.height, width: geo.size.width)
                        }
                    }
                    .frame(height: 160)
                }
                .padding(.top, Theme.Spacing.l)

                // Month labels
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: 50) // Match Y-axis width

                    HStack(spacing: Theme.Spacing.m) {
                        ForEach(totals) { total in
                            Text(total.label)
                                .font(Theme.Fonts.caption)
                                .foregroundColor(Theme.secondaryText)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.top, Theme.Spacing.s)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            }
            .onChange(of: totals.count) { _ in
                animationProgress = 0
                withAnimation(.easeOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            }
        }
    }

    private func monthBarGroup(for total: MonthlyTotal, height: CGFloat) -> some View {
        HStack(spacing: 3) {
            // Income bar (green)
            barView(value: total.income, color: Theme.income, height: height)

            // Expense bar (red)
            barView(value: total.expense, color: Theme.expense, height: height)
        }
        .frame(maxWidth: .infinity)
    }

    private func barView(value: Double, color: Color, height: CGFloat) -> some View {
        let ratio = CGFloat(max(value, 0) / maxValue)
        let barHeight = ratio * height * animationProgress

        return VStack {
            Spacer(minLength: 0)
            Rectangle()
                .fill(color)
                .frame(width: 10, height: max(barHeight, value > 0 ? 2 : 0))
                .cornerRadius(3)
        }
        .frame(height: height)
    }

    private func profitLine(height: CGFloat, width: CGFloat) -> some View {
        let barGroupWidth = width / CGFloat(totals.count)
        let points = totals.enumerated().map { index, total -> CGPoint in
            let x = (CGFloat(index) + 0.5) * barGroupWidth
            let ratio = CGFloat(max(total.profit, 0) / maxValue)
            let y = height - (ratio * height * animationProgress)
            return CGPoint(x: x, y: y)
        }

        return Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(Color.orange, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
    }

    private var yAxisLabels: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(0..<5) { i in
                if i == 0 {
                    Spacer()
                }
                Text(formatYAxisValue(at: 4 - i))
                    .font(.system(size: 10))
                    .foregroundColor(Theme.secondaryText)
                if i < 4 {
                    Spacer()
                }
            }
        }
    }

    private func formatYAxisValue(at index: Int) -> String {
        let value = maxValue * Double(index) / 4.0
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }

    private var labels: some View {
        HStack(spacing: Theme.Spacing.m) {
            ForEach(totals) { total in
                Text(total.label)
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct MonthlyBarChartView_Previews: PreviewProvider {
    static var previews: some View {
        MonthlyBarChartView(totals: [
            MonthlyTotal(monthStart: Date(), label: "មករា", income: 500, expense: 200),
            MonthlyTotal(monthStart: Date(), label: "កុម្ភៈ", income: 300, expense: 600),
            MonthlyTotal(monthStart: Date(), label: "មីនា", income: 900, expense: 100)
        ], currency: .khr)
        .frame(height: 220)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Income/Expense Only Chart (no profit line)

/// Monthly income/expense chart without profit line.
/// Used in the Income/Expense tab of Reports.
struct ReportsIncomeExpenseChartView: View {
    let totals: [MonthlyTotal]
    let currency: Currency
    @State private var animationProgress: CGFloat = 0

    private var maxValue: Double {
        let allValues = totals.flatMap { [max($0.income, 0), max($0.expense, 0)] }
        return max(allValues.max() ?? 0, 1)
    }

    var body: some View {
        if totals.isEmpty {
            Text(L("reports.noData")).foregroundColor(Theme.secondaryText)
        } else {
            VStack(spacing: 0) {
                // Chart with Y-axis
                HStack(alignment: .bottom, spacing: 0) {
                    // Y-axis labels
                    yAxisLabels
                        .frame(width: 50)

                    // Chart area with bars only (no profit line)
                    GeometryReader { geo in
                        HStack(alignment: .bottom, spacing: Theme.Spacing.m) {
                            ForEach(totals) { total in
                                monthBarGroup(for: total, height: geo.size.height)
                            }
                        }
                        .frame(height: geo.size.height)
                    }
                    .frame(height: 160)
                }
                .padding(.top, Theme.Spacing.l)

                // Month labels
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: 50) // Match Y-axis width

                    HStack(spacing: Theme.Spacing.m) {
                        ForEach(totals) { total in
                            Text(total.label)
                                .font(Theme.Fonts.caption)
                                .foregroundColor(Theme.secondaryText)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.top, Theme.Spacing.s)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            }
            .onChange(of: totals.count) { _ in
                animationProgress = 0
                withAnimation(.easeOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            }
        }
    }

    private func monthBarGroup(for total: MonthlyTotal, height: CGFloat) -> some View {
        HStack(spacing: 3) {
            // Income bar (green)
            barView(value: total.income, color: Theme.income, height: height)

            // Expense bar (red)
            barView(value: total.expense, color: Theme.expense, height: height)
        }
        .frame(maxWidth: .infinity)
    }

    private func barView(value: Double, color: Color, height: CGFloat) -> some View {
        let ratio = CGFloat(max(value, 0) / maxValue)
        let barHeight = ratio * height * animationProgress

        return VStack {
            Spacer(minLength: 0)
            Rectangle()
                .fill(color)
                .frame(width: 10, height: max(barHeight, value > 0 ? 2 : 0))
                .cornerRadius(3)
        }
        .frame(height: height)
    }

    private var yAxisLabels: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(0..<5) { i in
                if i == 0 {
                    Spacer()
                }
                Text(formatYAxisValue(at: 4 - i))
                    .font(.system(size: 10))
                    .foregroundColor(Theme.secondaryText)
                if i < 4 {
                    Spacer()
                }
            }
        }
    }

    private func formatYAxisValue(at index: Int) -> String {
        let value = maxValue * Double(index) / 4.0
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}
