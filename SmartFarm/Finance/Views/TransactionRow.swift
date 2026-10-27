import SwiftUI

/// A single transaction cell: category icon, title + type label, signed amount + time.
struct TransactionRow: View {
    let transaction: Transaction

    // Darker, more saturated colors for better contrast
    private let strongGreen = Color(red: 0.08, green: 0.50, blue: 0.24) // #15803D
    private let strongRed = Color(red: 0.73, green: 0.11, blue: 0.11) // #B91C1C
    private let darkText = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let grayText = Color(red: 0.29, green: 0.34, blue: 0.39) // #4B5563

    private var categoryIcon: String {
        guard !transaction.category.isEmpty else { return "tag.fill" }
        // Try to match TransactionCategory enum cases
        if let category = TransactionCategory(rawValue: transaction.category) {
            return category.systemImage
        }
        return "tag.fill"
    }

    private var categoryColor: Color {
        // Use a softer color for the category icon based on transaction type
        transaction.type == .income ? Color.green : Color.red
    }

    private var typeLabel: String {
        transaction.type == .income ? L("finance.income") : L("finance.expense")
    }

    private var amountColor: Color {
        transaction.type == .income ? strongGreen : strongRed
    }

    private var signedAmount: String {
        let prefix = transaction.type == .income ? "+" : "-"
        return prefix + CurrencyFormatter.string(transaction.amount, currency: transaction.currency)
    }

    private var timeString: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: transaction.date)
        let minute = calendar.component(.minute, from: transaction.date)
        return String(format: "%02d:%02d", hour, minute)
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            // Left: Round colored icon for category
            Image(systemName: categoryIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(categoryColor)
                .clipShape(Circle())

            // Middle: Title (bold dark) + Type label (gray)
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(darkText)
                Text(typeLabel)
                    .font(.system(size: 13))
                    .foregroundColor(grayText)
            }

            Spacer()

            // Right: Amount (bold colored) + Time (gray)
            VStack(alignment: .trailing, spacing: 2) {
                Text(signedAmount)
                    .font(.system(size: 16, weight: .bold).monospacedDigit())
                    .foregroundColor(amountColor)
                Text(timeString)
                    .font(.system(size: 13))
                    .foregroundColor(grayText)
            }
        }
        .padding(.vertical, Theme.Spacing.s)
    }
}

struct TransactionRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TransactionRow(transaction: Transaction(title: "លក់ស្រូវ", amount: 1_500_000,
                                                     type: .income, category: "ការលក់"))
            TransactionRow(transaction: Transaction(title: "ទិញជី", amount: 200_000,
                                                     type: .expense, category: "ជី"))
        }
    }
}
