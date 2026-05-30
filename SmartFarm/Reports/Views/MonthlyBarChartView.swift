import SwiftUI

/// Monthly profit/loss bar chart drawn with `GeometryReader` + `Rectangle`
/// (Swift Charts is iOS 16+ and not allowed). Bars rise from a centre baseline:
/// green above for profit, red below for loss.
struct MonthlyBarChartView: View {
    let totals: [MonthlyTotal]
    let currency: Currency

    private var maxMagnitude: Double {
        max(totals.map { abs($0.profit) }.max() ?? 0, 1)
    }

    var body: some View {
        if totals.isEmpty {
            Text(L("reports.noData")).foregroundColor(Theme.secondaryText)
        } else {
            VStack(spacing: Theme.Spacing.s) {
                GeometryReader { geo in
                    let halfHeight = geo.size.height / 2
                    HStack(alignment: .center, spacing: Theme.Spacing.s) {
                        ForEach(totals) { total in
                            barColumn(for: total, halfHeight: halfHeight)
                        }
                    }
                    .frame(height: geo.size.height)
                }
                labels
            }
        }
    }

    private func barColumn(for total: MonthlyTotal, halfHeight: CGFloat) -> some View {
        let ratio = CGFloat(abs(total.profit) / maxMagnitude)
        let barHeight = max(ratio * halfHeight, total.profit == 0 ? 0 : 2)
        let isProfit = total.profit >= 0
        return VStack(spacing: 0) {
            // top half (profit grows upward from the baseline)
            VStack {
                Spacer(minLength: 0)
                if isProfit {
                    Rectangle()
                        .fill(Theme.income)
                        .frame(height: barHeight)
                        .cornerRadius(3)
                }
            }
            .frame(height: halfHeight)

            // bottom half (loss grows downward from the baseline)
            VStack {
                if !isProfit {
                    Rectangle()
                        .fill(Theme.expense)
                        .frame(height: barHeight)
                        .cornerRadius(3)
                }
                Spacer(minLength: 0)
            }
            .frame(height: halfHeight)
        }
        .frame(maxWidth: .infinity)
    }

    private var labels: some View {
        HStack(spacing: Theme.Spacing.s) {
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
