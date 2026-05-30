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
    case add
    case edit(Reminder)
}

/// Shared form for creating / editing a reminder.
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
        case .add:
            _editingID = State(initialValue: nil)
            _title = State(initialValue: "")
            _dueDate = State(initialValue: Date())
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
            Form {
                Section {
                    TextField(L("common.title"), text: $title)
                    DatePicker(L("common.time"), selection: $dueDate)
                    Picker(L("calendar.repeat"), selection: $repeatType) {
                        ForEach(RepeatType.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    TextField(L("common.note"), text: $note)
                }
                if editingID != nil {
                    Section { Toggle(L("common.completed"), isOn: $isCompleted) }
                }
            }
            .navigationTitle(editingID == nil ? L("calendar.addReminder") : L("calendar.editReminder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("common.save")) { save() }.disabled(!isValid)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
        AddEditReminderView(mode: .add) { _ in }
    }
}
