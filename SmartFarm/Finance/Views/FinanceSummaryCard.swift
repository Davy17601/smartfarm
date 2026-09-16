//
//  FinanceSummaryCard.swift
//  SmartFarm
//
//  Finance-specific summary card with larger font for better readability
//

import SwiftUI

/// Finance summary card with increased font size for amounts
/// Similar to SummaryCardView but with .title2 instead of .title3 for values
struct FinanceSummaryCard: View {
    let title: String
    let value: String
    var systemImage: String = "circle.fill"
    var tint: Color = Theme.brand

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: systemImage)
                    .foregroundColor(tint)
                Text(title)
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.secondaryText)
            }
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
