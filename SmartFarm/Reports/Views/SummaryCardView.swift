//
//  SummaryCardView.swift
//  SmartFarm
//

import SwiftUI

struct SummaryCardView: View {
    var icon: String
    var label: String
    var amount: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(amount)
                .font(.title3).bold()
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

struct SummaryCardView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            SummaryCardView(icon: "arrow.down.circle.fill", label: "ចំណូល", amount: "1,500,000 ៛", color: .green)
            SummaryCardView(icon: "arrow.up.circle.fill", label: "ចំណាយ", amount: "800,000 ៛", color: .red)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
