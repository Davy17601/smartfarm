import SwiftUI

extension RepeatType {
    var displayName: String {
        switch self {
        case .none:    return L("repeat.none")
        case .daily:   return L("repeat.daily")
        case .weekly:  return L("repeat.weekly")
        case .monthly: return L("repeat.monthly")
        }
    }
}

enum ReminderFormMode {
    case add(Date)
    case edit(Reminder)
}

/// Shared form for creating / editing a reminder. Built from `FarmCard`
/// sections on `Theme.background` (matching the Welcome screen and Calendar
/// tab) with the app's green accent, instead of a native `Form` on the
/// app-wide blue `AccentColor` — a plain `Form`'s grouped background and
/// picker chrome can't be restyled per-screen, so this stays local to this
/// file, no other screen is affected.
struct AddEditReminderView: View {
    let mode: ReminderFormMode
    let onSave: (Reminder) -> Void

    @Environment(\.presentationMode) private var presentationMode

    @State private var editingID: UUID?
    @State private var title: String
    @State private var dueDate: Date
    @State private var note: String
    @State private var repeatType: RepeatType
    @State private var isCompleted: Bool

    init(mode: ReminderFormMode, onSave: @escaping (Reminder) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add(let date):
            _editingID = State(initialValue: nil)
            _title = State(initialValue: "")
            _dueDate = State(initialValue: date)
            _note = State(initialValue: "")
            _repeatType = State(initialValue: .none)
            _isCompleted = State(initialValue: false)
        case .edit(let r):
            _editingID = State(initialValue: r.id)
            _title = State(initialValue: r.title)
            _dueDate = State(initialValue: r.dueDate)
            _note = State(initialValue: r.note)
            _repeatType = State(initialValue: r.repeatType)
            _isCompleted = State(initialValue: r.isCompleted)
        }
    }

    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.m) {
                    FarmCard {
                        TextField(L("common.title"), text: $title)
                        Divider()
                        DatePicker(L("common.time"), selection: $dueDate)
                            .datePickerStyle(CompactDatePickerStyle())
                        Divider()
                        repeatRow
                        Divider()
                        TextField(L("common.note"), text: $note)
                    }
                    if editingID != nil {
                        FarmCard {
                            Toggle(L("common.completed"), isOn: $isCompleted)
                        }
                    }
                }
                .padding(Theme.Spacing.m)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(editingID == nil ? L("calendar.addReminder") : L("calendar.editReminder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: save) {
                        Text(L("common.save")).fontWeight(.bold)
                    }
                    .foregroundColor(Theme.brand)
                    .disabled(!isValid)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(Theme.brand)
    }

    /// Custom stand-in for a plain `Picker` row: a native `Picker`'s collapsed
    /// preview renders its chevron in a fixed system gray regardless of
    /// `.foregroundColor` or `.accentColor`, so it can't show the app's green
    /// here. `Menu` keeps the same tap-to-choose behavior with a green chevron.
    private var repeatRow: some View {
        Menu {
            ForEach(RepeatType.allCases, id: \.self) { option in
                Button {
                    repeatType = option
                } label: {
                    Text(option.displayName)
                }
            }
        } label: {
            HStack {
                Text(L("calendar.repeat")).foregroundColor(Theme.primaryText)
                Spacer()
                Text(repeatType.displayName).foregroundColor(Theme.secondaryText)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundColor(Theme.brand)
            }
        }
    }

    private func save() {
        let reminder = Reminder(
            id: editingID ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            dueDate: dueDate,
            note: note,
            isCompleted: isCompleted,
            repeatType: repeatType
        )
        onSave(reminder)
        dismiss()
    }

    private func dismiss() { presentationMode.wrappedValue.dismiss() }
}

struct AddEditReminderView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditReminderView(mode: .add(Date())) { _ in }
    }
}
