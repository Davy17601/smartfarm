import Foundation

/// Formats amounts for KHR (no decimals, ៛ suffix) and USD ($ prefix, 2 decimals).
enum CurrencyFormatter {
    private static func decimalFormatter(maxFractionDigits: Int) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.maximumFractionDigits = maxFractionDigits
        f.minimumFractionDigits = 0
        return f
    }

    static func string(_ amount: Double, currency: Currency) -> String {
        switch currency {
        case .khr:
            let number = decimalFormatter(maxFractionDigits: 0)
                .string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
            return "\(number) ៛"
        case .usd:
            let number = decimalFormatter(maxFractionDigits: 2)
                .string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
            return "$\(number)"
        }
    }

    /// Signed variant used for profit/loss (prefixes `+` / `−`).
    static func signedString(_ amount: Double, currency: Currency) -> String {
        let sign = amount < 0 ? "−" : "+"
        return sign + string(abs(amount), currency: currency)
    }
}
