import Foundation
import UIKit

/// Generates shareable CSV and PDF reports from transactions and writes them to
/// temporary files whose URLs can be handed to `ActivityShareSheet`.
enum ReportExporter {

    // MARK: - CSV

    static func csvString(_ transactions: [Transaction]) -> String {
        var rows = ["Date,Title,Type,Category,Currency,Amount,Note"]
        let formatter = ISO8601DateFormatter()
        for t in transactions {
            let fields = [
                formatter.string(from: t.date),
                escape(t.title),
                t.type.rawValue,
                t.category.rawValue,
                t.currency.rawValue,
                String(t.amount),
                escape(t.note)
            ]
            rows.append(fields.joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    static func csvFile(_ transactions: [Transaction]) -> URL? {
        write(csvString(transactions).data(using: .utf8), filename: "SmartFarm-Report.csv")
    }

    private static func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    // MARK: - PDF

    static func pdfFile(transactions: [Transaction],
                        monthlyTotals: [MonthlyTotal],
                        currency: Currency) -> URL? {
        let pageWidth: CGFloat = 612   // US Letter @ 72dpi
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )

        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin

            y = draw(L("reports.pdfTitle"), at: y, margin: margin,
                     font: .boldSystemFont(ofSize: 20))
            y += 8

            let income = transactions.filter { $0.type == .income && $0.currency == currency }
                .reduce(0) { $0 + $1.amount }
            let expense = transactions.filter { $0.type == .expense && $0.currency == currency }
                .reduce(0) { $0 + $1.amount }
            y = draw("\(L("reports.totalIncome")): \(CurrencyFormatter.string(income, currency: currency))",
                     at: y, margin: margin, font: .systemFont(ofSize: 13))
            y = draw("\(L("reports.totalExpense")): \(CurrencyFormatter.string(expense, currency: currency))",
                     at: y, margin: margin, font: .systemFont(ofSize: 13))
            y = draw("\(L("finance.profitLoss")): \(CurrencyFormatter.signedString(income - expense, currency: currency))",
                     at: y, margin: margin, font: .boldSystemFont(ofSize: 13))
            y += 12

            y = draw(L("reports.transactions"), at: y, margin: margin, font: .boldSystemFont(ofSize: 15))
            y += 4

            for t in transactions {
                if y > pageHeight - margin {
                    context.beginPage()
                    y = margin
                }
                let sign = t.type == .income ? "+" : "−"
                let line = "\(LocalizedDate.mediumString(t.date))  ·  \(t.title)  ·  \(sign)\(CurrencyFormatter.string(t.amount, currency: t.currency))"
                y = draw(line, at: y, margin: margin, font: .systemFont(ofSize: 11))
            }
        }

        return write(data, filename: "SmartFarm-Report.pdf")
    }

    @discardableResult
    private static func draw(_ text: String, at y: CGFloat, margin: CGFloat,
                             font: UIFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        (text as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: attributes)
        return y + size.height + 4
    }

    // MARK: - File helper

    private static func write(_ data: Data?, filename: String) -> URL? {
        guard let data = data else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            assertionFailure("Failed to write \(filename): \(error)")
            return nil
        }
    }
}
