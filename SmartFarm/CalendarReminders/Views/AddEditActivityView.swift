import SwiftUI

enum ActivityFormMode {
    case add(Date)
    case edit(FarmActivity)
}

/// Shared form for creating / editing a farm activity.
struct AddEditActivityView: View {
    let mode: ActivityFormMode
    let onSave: (FarmActivity) -> Void

    @Environment(\.presentationMode) private var presentationMode

    @State private var editingID: UUID?
    @State private var title: String
    @State private var date: Date
    @State private var note: String
    @State private var isCompleted: Bool

    init(mode: ActivityFormMode, onSave: @escaping (FarmActivity) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add(let date):
            _editingID = State(initialValue: nil)
            _title = State(initialValue: "")
            _date = State(initialValue: date)
            _note = State(initialValue: "")
            _isCompleted = State(initialValue: false)
        case .edit(let a):
            _editingID = State(initialValue: a.id)
            _title = State(initialValue: a.title)
            _date = State(initialValue: a.date)
            _note = State(initialValue: a.note)
            _isCompleted = State(initialValue: a.isCompleted)
        }
    }

    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(L("common.title"), text: $title)
                    DatePicker(L("common.time"), selection: $date)
                    TextField(L("common.note"), text: $note)
                }
                if editingID != nil {
                    Section { Toggle(L("common.completed"), isOn: $isCompleted) }
                }
            }
            .navigationTitle(editingID == nil ? L("calendar.addActivity") : L("calendar.editActivity"))
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
        let activity = FarmActivity(
            id: editingID ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            date: date,
            note: note,
            isCompleted: isCompleted
        )
        onSave(activity)
        dismiss()
    }

    private func dismiss() { presentationMode.wrappedValue.dismiss() }
}

struct AddEditActivityView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditActivityView(mode: .add(Date())) { _ in }
    }
}
