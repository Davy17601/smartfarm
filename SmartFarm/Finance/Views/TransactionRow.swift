import SwiftUI

/// A single transaction cell: category icon, title + meta, signed amount.
struct TransactionRow: View {
    let transaction: Transaction

    private var tint: Color {
        transaction.type == .income ? Theme.income : Theme.expense
    }

    private var signedAmount: String {
        let prefix = transaction.type == .income ? "+" : "−"
        return prefix + CurrencyFormatter.string(transaction.amount, currency: transaction.currency)
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: transaction.category.systemImage)
                .foregroundColor(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(Theme.Fonts.body)
                    .foregroundColor(Theme.primaryText)
                Text("\(transaction.category.displayName) · \(LocalizedDate.dayMonthString(transaction.date))")
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.secondaryText)
            }

            Spacer()

            Text(signedAmount)
                .font(Theme.Fonts.body.monospacedDigit())
                .foregroundColor(tint)
        }
        .padding(.vertical, 4)
    }
}

struct TransactionRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TransactionRow(transaction: Transaction(title: "លក់ស្រូវ", amount: 1_500_000,
                                                     type: .income, category: .sales))
            TransactionRow(transaction: Transaction(title: "ទិញជី", amount: 200_000,
                                                     type: .expense, category: .fertilizer))
        }
    }
}
