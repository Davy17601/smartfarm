import SwiftUI

/// Compact metric card: icon + caption title + emphasized value.
/// Used on the Dashboard and the Finance summary row.
struct SummaryCardView: View {
    let title: String
    let value: String
    var systemImage: String = "circle.fill"
    var tint: Color = Theme.brand

    var body: some View {
        FarmCard {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: systemImage)
                    .foregroundColor(tint)
                Text(title)
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.secondaryText)
            }
            Text(value)
                .font(Theme.Fonts.amount)
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

struct SummaryCardView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            SummaryCardView(title: "ចំណូល", value: "1,500,000 ៛",
                            systemImage: "arrow.down.circle.fill", tint: Theme.income)
            SummaryCardView(title: "ចំណាយ", value: "200,000 ៛",
                            systemImage: "arrow.up.circle.fill", tint: Theme.expense)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
