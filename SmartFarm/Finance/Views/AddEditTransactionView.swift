import SwiftUI

/// Whether the form is creating a new transaction or editing an existing one.
enum TransactionFormMode {
    case add
    case edit(Transaction)
}

/// Shared form for creating and editing a transaction.
/// Presented as a sheet; calls `onSave` with the resulting transaction.
struct AddEditTransactionView: View {
    let mode: TransactionFormMode
    let onSave: (Transaction) -> Void

    @Environment(\.presentationMode) private var presentationMode

    @State private var editingID: UUID?
    @State private var title: String
    @State private var amountText: String
    @State private var type: TransactionType
    @State private var category: TransactionCategory
    @State private var currency: Currency
    @State private var date: Date
    @State private var note: String

    init(mode: TransactionFormMode, onSave: @escaping (Transaction) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add:
            _editingID = State(initialValue: nil)
            _title = State(initialValue: "")
            _amountText = State(initialValue: "")
            _type = State(initialValue: .expense)
            _category = State(initialValue: .other)
            _currency = State(initialValue: .khr)
            _date = State(initialValue: Date())
            _note = State(initialValue: "")
        case .edit(let t):
            _editingID = State(initialValue: t.id)
            _title = State(initialValue: t.title)
            _amountText = State(initialValue: String(t.amount))
            _type = State(initialValue: t.type)
            _category = State(initialValue: t.category)
            _currency = State(initialValue: t.currency)
            _date = State(initialValue: t.date)
            _note = State(initialValue: t.note)
        }
    }

    private var amount: Double { Double(amountText) ?? 0 }
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0
    }
    private var navTitle: String { editingID == nil ? L("finance.addTransaction") : L("common.edit") }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(L("common.title"), text: $title)
                    TextField(L("finance.amount"), text: $amountText)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Picker(L("finance.type"), selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Picker(L("finance.category"), selection: $category) {
                        ForEach(TransactionCategory.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }

                    Picker(L("finance.currency"), selection: $currency) {
                        ForEach(Currency.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                }

                Section {
                    DatePicker(L("common.date"), selection: $date, displayedComponents: .date)
                    TextField(L("common.note"), text: $note)
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("common.save")) { save() }
                        .disabled(!isValid)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func save() {
        let transaction = Transaction(
            id: editingID ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            amount: amount,
            type: type,
            category: category,
            currency: currency,
            date: date,
            note: note
        )
        onSave(transaction)
        dismiss()
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddEditTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditTransactionView(mode: .add) { _ in }
    }
}
