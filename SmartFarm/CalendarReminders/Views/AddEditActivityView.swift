import SwiftUI

enum ActivityFormMode {
    case add(Date, FarmActivityCategory)
    case edit(FarmActivity)
}

/// Shared form for creating / editing a farm activity — green header bar
/// overlapped by a white rounded-top-corner panel, a circular photo (default
/// illustration driven by the selected category, or a picked library photo),
/// bordered icon fields, and one big gradient capsule save button pinned at
/// the bottom. Data model, save logic, and edit mode are unchanged from the
/// previous plain-`Form` layout — this is a UI-only redesign.
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
    @State private var photoData: Data?
    @State private var showingPhotoPicker = false

    // MARK: - Palette

    private let headerGreen  = Color(red: Double(0x2E) / 255.0, green: Double(0x7D) / 255.0, blue: Double(0x32) / 255.0)
    private let buttonEnd    = Color(red: Double(0x43) / 255.0, green: Double(0xA0) / 255.0, blue: Double(0x47) / 255.0)
    private let labelGreen   = Color(red: Double(0x1B) / 255.0, green: Double(0x5E) / 255.0, blue: Double(0x20) / 255.0)
    private let fieldBorder  = Color(red: Double(0xDD) / 255.0, green: Double(0xE5) / 255.0, blue: Double(0xDD) / 255.0)

    private let headerBlockHeight: CGFloat = 150
    private let panelTopInset: CGFloat = 108
    private let panelCornerRadius: CGFloat = 28

    init(mode: ActivityFormMode, onSave: @escaping (FarmActivity) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add(let date, let category):
            _editingID = State(initialValue: nil)
            _title = State(initialValue: "")
            _date = State(initialValue: date)
            _note = State(initialValue: "")
            _isCompleted = State(initialValue: false)
            _category = State(initialValue: category)
            _photoData = State(initialValue: nil)
        case .edit(let a):
            _editingID = State(initialValue: a.id)
            _title = State(initialValue: a.title)
            _date = State(initialValue: a.date)
            _note = State(initialValue: a.note)
            _isCompleted = State(initialValue: a.isCompleted)
            _category = State(initialValue: a.category)
            _photoData = State(initialValue: a.photoData)
        }
    }

    private var isEditing: Bool { editingID != nil }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            headerGreen
                .frame(height: headerBlockHeight)
                .ignoresSafeArea(edges: .top)

            headerBar

            VStack(spacing: 0) {
                Color.clear.frame(height: panelTopInset)

                ScrollView {
                    formBody
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                }
                .background(
                    RoundedCorner(radius: panelCornerRadius, corners: [.topLeft, .topRight])
                        .fill(Color.white)
                )
            }

            VStack {
                Spacer()
                saveButtonBar
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker { image in
                if let image = image {
                    photoData = image.jpegData(compressionQuality: 0.7)
                }
            }
        }
        .onAppear {
            // `TextEditor` paints its own opaque system background with no
            // public modifier to clear it pre-iOS 16 — this is the standard
            // iOS 14 workaround so the description field's white card +
            // border (drawn around it) shows through instead. `TextEditor`
            // is only used on this screen, so this has no effect elsewhere.
            UITextView.appearance().backgroundColor = .clear
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        ZStack {
            Text(isEditing ? L("calendar.editActivity") : L("calendar.addActivity"))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack {
                Button(action: dismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .frame(height: 44)
    }

    // MARK: - Form body

    private var formBody: some View {
        VStack(spacing: Theme.Spacing.m) {
            photoSection

            fieldGroup(label: L("activity.form.type")) {
                categoryField
            }

            VStack(alignment: .leading, spacing: 8) {
                fieldLabel(L("common.date"))
                dateField
                timeField
            }

            fieldGroup(label: L("activity.form.cropName")) {
                cropNameField
            }

            fieldGroup(label: L("activity.form.description")) {
                descriptionField
            }

            if isEditing {
                completedRow
            }

            // Keeps the last field clear of the fixed save button bar.
            Color.clear.frame(height: 72)
        }
    }

    private func fieldGroup<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(label)
            content()
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(labelGreen)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The bordered, icon-leading, 52pt-tall row shared by every single-line
    /// field (category, date, time, crop name).
    private func fieldContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            content()
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(fieldBorder, lineWidth: 1)
        )
    }

    // MARK: - Photo

    /// Circular 120pt photo — the picked library photo if there is one,
    /// otherwise a soft illustration keyed to the selected activity type
    /// (updates live as `category` changes), with a small green camera
    /// button over its bottom-right edge.
    private var photoSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Circle().fill(category.tintColor)
                        Image(systemName: category.systemImage)
                            .font(.system(size: 46, weight: .semibold))
                            .foregroundColor(category.color)
                    }
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 5)

            Button(action: { showingPhotoPicker = true }) {
                ZStack {
                    Circle().fill(headerGreen).frame(width: 34, height: 34)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
            .buttonStyle(ScaleButtonStyle())
            .offset(x: 2, y: 2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Category field

    private var categoryField: some View {
        Menu {
            ForEach(FarmActivityCategory.allCases, id: \.self) { option in
                Button {
                    category = option
                } label: {
                    Label(option.displayName, systemImage: option.systemImage)
                }
            }
        } label: {
            fieldContainer {
                Image(systemName: category.systemImage)
                    .foregroundColor(category.color)
                    .frame(width: 20)
                Text(category.displayName)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.primaryText)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(labelGreen.opacity(0.6))
            }
        }
    }

    // MARK: - Date / time fields

    /// A real `DatePicker` stretched invisibly over the custom-styled row so
    /// the row keeps our own Khmer-numeral formatted text while staying
    /// fully tappable and functional (the native compact picker underneath
    /// handles the actual date/time editing UI).
    private var dateField: some View {
        fieldContainer {
            Image(systemName: "calendar")
                .foregroundColor(labelGreen)
                .frame(width: 20)
            Text(LocalizedDate.dayMonthYearString(date))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Theme.primaryText)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(labelGreen.opacity(0.6))
        }
        .overlay(invisibleDatePicker(displayedComponents: .date))
    }

    private var timeField: some View {
        fieldContainer {
            Image(systemName: "clock")
                .foregroundColor(labelGreen)
                .frame(width: 20)
            Text(LocalizedDate.timeString(date))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Theme.primaryText)
            Spacer()
        }
        .overlay(invisibleDatePicker(displayedComponents: .hourAndMinute))
    }

    private func invisibleDatePicker(displayedComponents: DatePickerComponents) -> some View {
        DatePicker("", selection: $date, displayedComponents: displayedComponents)
            .labelsHidden()
            .datePickerStyle(CompactDatePickerStyle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .opacity(0.02)
    }

    // MARK: - Crop name

    private var cropNameField: some View {
        fieldContainer {
            Image(systemName: "leaf.fill")
                .foregroundColor(labelGreen)
                .frame(width: 20)
            TextField(L("activity.form.cropNamePlaceholder"), text: $title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
        }
    }

    // MARK: - Description

    private var descriptionField: some View {
        ZStack(alignment: .topLeading) {
            Image(systemName: "text.alignleft")
                .foregroundColor(labelGreen)
                .padding(.top, 14)
                .padding(.leading, 14)

            if note.isEmpty {
                Text(L("activity.form.descriptionPlaceholder"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.secondaryText.opacity(0.6))
                    .padding(.top, 14)
                    .padding(.leading, 40)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $note)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .lineSpacing(4)
                .padding(.leading, 28)
                .padding(.top, 6)
                .padding(.trailing, 6)
                .frame(height: 96)
        }
        .frame(height: 96)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(fieldBorder, lineWidth: 1)
        )
    }

    // MARK: - Completed toggle (edit mode only)

    private var completedRow: some View {
        fieldContainer {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? headerGreen : fieldBorder)
            Toggle(L("common.completed"), isOn: $isCompleted)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Theme.primaryText)
                .toggleStyle(SwitchToggleStyle(tint: headerGreen))
        }
    }

    // MARK: - Save button

    private var saveButtonBar: some View {
        Button(action: save) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                Text(L("common.save"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                TwoStopGradient(start: buttonEnd, end: headerGreen, axis: .horizontal)
            )
            .clipShape(Capsule())
            .shadow(color: headerGreen.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
    }

    // MARK: - Save

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let activity = FarmActivity(
            id: editingID ?? UUID(),
            // The crop-name field is optional — fall back to the activity
            // type's own name so there's always a sensible title to save.
            title: trimmedTitle.isEmpty ? category.displayName : trimmedTitle,
            date: date,
            note: note,
            isCompleted: isCompleted,
            category: category,
            photoData: photoData
        )
        onSave(activity)
        dismiss()
    }

    private func dismiss() { presentationMode.wrappedValue.dismiss() }
}

struct AddEditActivityView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditActivityView(mode: .add(Date(), .watering)) { _ in }
    }
}
