import SwiftUI

/// Detail screen for a single transaction, reached via the `FinanceCoordinator`
/// deep link. Re-reads from the ViewModel so edits reflect immediately.
struct TransactionDetailView: View {
    @ObservedObject var viewModel: FinanceViewModel
    let transactionID: UUID

    @State private var showingEdit = false

    private var transaction: Transaction? { viewModel.transaction(for: transactionID) }

    var body: some View {
        Group {
            if let transaction = transaction {
                content(for: transaction)
            } else {
                Text(L("finance.transactionMissing"))
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .navigationTitle(L("common.details"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L("common.edit")) { showingEdit = true }
                    .disabled(transaction == nil)
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let transaction = transaction {
                AddEditTransactionView(mode: .edit(transaction)) { viewModel.update($0) }
            }
        }
    }

    private func content(for transaction: Transaction) -> some View {
        let tint = transaction.type == .income ? Theme.income : Theme.expense
        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                FarmCard {
                    Text(transaction.title).font(Theme.Fonts.title)
                    Text(CurrencyFormatter.string(transaction.amount, currency: transaction.currency))
                        .font(Theme.Fonts.amount)
                        .foregroundColor(tint)
                }

                FarmCard {
                    detailRow(L("finance.type"), transaction.type.displayName)
                    detailRow(L("finance.category"), transaction.category.displayName)
                    detailRow(L("finance.currency"), transaction.currency.displayName)
                    detailRow(L("common.date"), LocalizedDate.mediumString(transaction.date))
                    if !transaction.note.isEmpty {
                        detailRow(L("common.note"), transaction.note)
                    }
                }
            }
            .padding(Theme.Spacing.m)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).foregroundColor(Theme.secondaryText)
            Spacer()
            Text(value).foregroundColor(Theme.primaryText).multilineTextAlignment(.trailing)
        }
    }
}
