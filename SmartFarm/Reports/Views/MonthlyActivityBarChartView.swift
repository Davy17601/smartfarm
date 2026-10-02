import SwiftUI

/// Monthly farm-activity-count bar chart drawn with `GeometryReader` + `Rectangle`
/// (Swift Charts is iOS 16+ and not allowed). Bars rise from a bottom baseline,
/// mirroring the visual style of `MonthlyBarChartView`.
struct MonthlyActivityBarChartView: View {
    let counts: [MonthlyActivityCount]

    private var maxCount: Int {
        max(counts.map { $0.count }.max() ?? 0, 1)
    }

    var body: some View {
        if counts.isEmpty {
            Text(L("reports.noData")).foregroundColor(Theme.secondaryText)
        } else {
            VStack(spacing: Theme.Spacing.s) {
                GeometryReader { geo in
                    HStack(alignment: .bottom, spacing: Theme.Spacing.s) {
                        ForEach(counts) { item in
                            barColumn(for: item, maxHeight: geo.size.height)
                        }
                    }
                    .frame(height: geo.size.height)
                }
                labels
            }
        }
    }

    private func barColumn(for item: MonthlyActivityCount, maxHeight: CGFloat) -> some View {
        let ratio = CGFloat(item.count) / CGFloat(maxCount)
        let barHeight = max(ratio * maxHeight, item.count == 0 ? 0 : 2)
        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            Rectangle()
                .fill(Theme.brand)
                .frame(height: barHeight)
                .cornerRadius(3)
        }
        .frame(maxWidth: .infinity)
    }

    private var labels: some View {
        HStack(spacing: Theme.Spacing.s) {
            ForEach(counts) { item in
                Text(item.label)
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct MonthlyActivityBarChartView_Previews: PreviewProvider {
    static var previews: some View {
        MonthlyActivityBarChartView(counts: [
            MonthlyActivityCount(monthStart: Date(), label: "មករា", count: 3),
            MonthlyActivityCount(monthStart: Date(), label: "កុម្ភៈ", count: 7),
            MonthlyActivityCount(monthStart: Date(), label: "មីនា", count: 2)
        ])
        .frame(height: 220)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
