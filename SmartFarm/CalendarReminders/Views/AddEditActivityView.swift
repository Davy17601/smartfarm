import SwiftUI

enum ActivityFormMode {
    case add(Date)
    case edit(FarmActivity)
}

/// Shared form for creating / editing a farm activity. Built from `FarmCard`
/// sections on `Theme.background` (matching the Welcome screen and Calendar
/// tab) with the app's green accent, instead of a native `Form` on the
/// app-wide blue `AccentColor` — a plain `Form`'s grouped background and
/// picker chrome can't be restyled per-screen, so this stays local to this
/// file, no other screen is affected.
struct AddEditActivityView: View {
    let mode: ActivityFormMode
    let onSave: (FarmActivity) -> Void

    @Environment(\.presentationMode) private var presentationMode

    @State private var editingID: UUID?
    @State private var title: String
    @State private var date: Date
    @State private var note: String
    @State private var isCompleted: Bool
    @State private var category: FarmActivityCategory

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
            _category = State(initialValue: .watering)
        case .edit(let a):
            _editingID = State(initialValue: a.id)
            _title = State(initialValue: a.title)
            _date = State(initialValue: a.date)
            _note = State(initialValue: a.note)
            _isCompleted = State(initialValue: a.isCompleted)
            _category = State(initialValue: a.category)
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
                        DatePicker(L("common.time"), selection: $date)
                            .datePickerStyle(CompactDatePickerStyle())
                        Divider()
                        TextField(L("common.note"), text: $note)
                    }
                    FarmCard {
                        categoryRow
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
            .navigationTitle(editingID == nil ? L("calendar.addActivity") : L("calendar.editActivity"))
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
    /// preview renders its icon/chevron in a fixed system gray regardless of
    /// `.foregroundColor` or `.accentColor`, so it can't show the category's
    /// own color here. Building the row from `Menu` keeps tap-to-choose
    /// behavior while coloring the icon by the selected category (e.g. blue
    /// for watering) and the chevron in the app's green.
    private var categoryRow: some View {
        Menu {
            ForEach(FarmActivityCategory.allCases, id: \.self) { option in
                Button {
                    category = option
                } label: {
                    Label(option.displayName, systemImage: option.systemImage)
                }
            }
        } label: {
            HStack {
                Text(L("calendar.category")).foregroundColor(Theme.primaryText)
                Spacer()
                Image(systemName: category.systemImage).foregroundColor(category.color)
                Text(category.displayName).foregroundColor(Theme.secondaryText)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundColor(Theme.brand)
            }
        }
    }

    private func save() {
        let activity = FarmActivity(
            id: editingID ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            date: date,
            note: note,
            isCompleted: isCompleted,
            category: category
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
