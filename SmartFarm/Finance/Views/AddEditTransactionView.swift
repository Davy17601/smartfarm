import SwiftUI

/// Whether the form is creating a new transaction or editing an existing one.
enum TransactionFormMode {
    case add
    case edit(Transaction)
}

/// Repeat frequency for transactions
enum RepeatFrequency: String, CaseIterable {
    case once = "ម្តង"
    case daily = "រាល់ថ្ងៃ"
    case weekly = "រាល់សប្ដាហ៍"
    case monthly = "រាល់ខែ"
}

/// Shared form for creating and editing a transaction.
/// Presented as a sheet; calls `onSave` with the resulting transaction.
struct AddEditTransactionView: View {
    let mode: TransactionFormMode
    let onSave: (Transaction) -> Void

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var settings: AppSettings

    @State private var editingID: UUID?
    @State private var title: String
    @State private var amountText: String
    @State private var type: TransactionType
    @State private var category: String
    @State private var currency: Currency
    @State private var date: Date
    @State private var note: String
    @State private var repeatFrequency: RepeatFrequency = .once

    @State private var showDatePicker = false
    @State private var showRepeatPicker = false

    private let dashboardGreen = Color(red: 0.13, green: 0.55, blue: 0.13)

    init(mode: TransactionFormMode, initialType: TransactionType = .expense, onSave: @escaping (Transaction) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add:
            _editingID = State(initialValue: nil)
            _title = State(initialValue: "")
            _amountText = State(initialValue: "")
            _type = State(initialValue: initialType)
            _category = State(initialValue: "")
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
        amount > 0
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header
                customHeader

                // Scrollable content
                ScrollView {
                    VStack(spacing: 20) {
                        // Tab toggle for Income/Expense
                        typeToggle
                            .padding(.horizontal, 16)
                            .padding(.top, 20)

                        // Category field (free-text input)
                        categoryFieldSection

                        // Amount field
                        fieldSection(
                            label: "ចំនួនទឹកប្រាក់",
                            icon: nil,
                            iconColor: nil,
                            value: amountText.isEmpty ? "0" : amountText,
                            showChevron: true,
                            isEditable: true,
                            action: { }
                        )

                        // Date field
                        fieldSection(
                            label: "កាលបរិច្ឆេទ",
                            icon: "calendar",
                            iconColor: Theme.primaryText,
                            value: formattedDate(date),
                            showChevron: false,
                            action: { showDatePicker = true }
                        )

                        // Repeat field
                        fieldSection(
                            label: "កម្រិត/ជំពូក",
                            icon: "calendar",
                            iconColor: Theme.primaryText,
                            value: repeatFrequency.rawValue,
                            showChevron: true,
                            action: { showRepeatPicker = true }
                        )

                        // Note field (multi-line)
                        noteSection

                        // Spacer to push save button down
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 100)
                }

                // Save button at bottom
                saveButton
            }
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
        .sheet(isPresented: $showRepeatPicker) {
            repeatPickerSheet
        }
    }

    // MARK: - Custom Header

    private var customHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Text("បញ្ចូលប្រតិបត្តិការ")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.primaryText)

            Spacer()

            // Invisible spacer to balance the layout
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    // MARK: - Type Toggle

    private var typeToggle: some View {
        HStack(spacing: 4) {
            // Income button
            Button(action: { type = .income }) {
                Text("ចំណូល")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(type == .income ? .white : Theme.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(type == .income ? dashboardGreen : Color.clear)
                    .cornerRadius(20)
            }

            // Expense button
            Button(action: { type = .expense }) {
                Text("ចំណាយ")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(type == .expense ? .white : Theme.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(type == .expense ? dashboardGreen : Color.clear)
                    .cornerRadius(20)
            }
        }
        .padding(4)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    // MARK: - Category Field Section (Free-text input)

    private var categoryFieldSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ប្រភេទ")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.secondaryText)
                .padding(.horizontal, 16)

            HStack {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16))
                    .foregroundColor(type == .income ? dashboardGreen : .red)

                TextField("បញ្ចូលប្រភេទ", text: $category)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.primaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Field Section

    private func fieldSection(label: String, icon: String?, iconColor: Color?, value: String, showChevron: Bool, isEditable: Bool = false, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.secondaryText)
                .padding(.horizontal, 16)

            if isEditable {
                HStack {
                    TextField("0", text: $amountText)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.primaryText)
                        .keyboardType(.decimalPad)

                    if showChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.secondaryText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 16)
            } else {
                Button(action: action) {
                    HStack {
                        if let icon = icon, let iconColor = iconColor {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .foregroundColor(iconColor)
                        }

                        Text(value)
                            .font(.system(size: 16))
                            .foregroundColor(Theme.primaryText)

                        Spacer()

                        if showChevron {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.secondaryText)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("កំណត់ចំណាំ (ជម្រើស)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.secondaryText)
                .padding(.horizontal, 16)

            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("បញ្ចូលកំណត់ចំណាំ...")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.secondaryText.opacity(0.5))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                }

                TextEditor(text: $note)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.primaryText)
                    .frame(minHeight: 100)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: { save() }) {
            Text("រក្សាទុក")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isValid ? dashboardGreen : Color.gray.opacity(0.5))
                .cornerRadius(12)
        }
        .disabled(!isValid)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .background(Color.white)
    }

    // MARK: - Picker Sheets

    private var datePickerSheet: some View {
        NavigationView {
            VStack {
                DatePicker("កាលបរិច្ឆេទ", selection: $date, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                Spacer()
            }
            .navigationTitle("កាលបរិច្ឆេទ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showDatePicker = false
                    }
                }
            }
        }
    }

    private var repeatPickerSheet: some View {
        NavigationView {
            List {
                ForEach(RepeatFrequency.allCases, id: \.self) { freq in
                    Button(action: {
                        repeatFrequency = freq
                        showRepeatPicker = false
                    }) {
                        HStack {
                            Text(freq.rawValue)
                                .foregroundColor(Theme.primaryText)
                            Spacer()
                            if repeatFrequency == freq {
                                Image(systemName: "checkmark")
                                    .foregroundColor(dashboardGreen)
                            }
                        }
                    }
                }
            }
            .navigationTitle("កម្រិត/ជំពូក")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showRepeatPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.language.locale
        formatter.setLocalizedDateFormatFromTemplate("dd MMMM yyyy")
        let dateString = formatter.string(from: date)

        // Convert to Khmer numerals if in Khmer locale
        if LocalizationManager.shared.language == .khmer {
            let arabicToKhmer: [Character: Character] = [
                "0": "០", "1": "១", "2": "២", "3": "៣", "4": "៤",
                "5": "៥", "6": "៦", "7": "៧", "8": "៨", "9": "៩"
            ]
            return String(dateString.map { arabicToKhmer[$0] ?? $0 })
        }
        return dateString
    }

    private func save() {
        let transaction = Transaction(
            id: editingID ?? UUID(),
            title: title.isEmpty ? (category.isEmpty ? "ប្រតិបត្តិការ" : category) : title,
            amount: amount,
            type: type,
            category: category,
            currency: currency,
            date: date,
            note: note
        )
        onSave(transaction)

        // Delay dismiss to ensure @Published state updates propagate before sheet closes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddEditTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditTransactionView(mode: .add) { _ in }
            .environmentObject(AppSettings.shared)
    }
}
