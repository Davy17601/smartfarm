# SmartFarm iOS App (កសិកម្ម ឆ្លាតវៃ)

កម្មវិធី SwiftUI MVVM សម្រាប់កសិករខ្នាតតូចនៅកម្ពុជា — តាមដានហិរញ្ញវត្ថុ សកម្មភាពកសិកម្ម និងកាលវិភាគក្នុងកន្លែងតែមួយ។

---

## គោលបំណង និងអត្ថប្រយោជន៍

### បញ្ហាដែលកសិករកម្ពុជាប្រឈមមុខ

កសិករខ្នាតតូចភាគច្រើននៅកម្ពុជាកំពុងប្រឈមមុខនឹងបញ្ហាទាំងនេះ៖

- **គ្មាន records ច្បាស់លាស់** — ចំណូល និងចំណាយត្រូវបានកត់ត្រានៅលើក្រដាស ឬចងចាំក្នុងក្បាល ដែលងាយបាត់បង់ និងមិនត្រឹមត្រូវ
- **មិនដឹង profit/loss ពិតប្រាកដ** — ពួកគេដាំដុះដោយមិនដឹងថាតើខែនេះ ឬរដូវកាលនេះចំណេញ ឬខាត
- **ភ្លេចកាលបរិច្ឆេទសំខាន់ៗ** — ការព្រងើយកន្តើយនឹងពេលវេលាបន្លិចទឹក បាច់ជី ឬច្រូតកាត់ ធ្វើឱ្យខូចទិន្នផល
- **គ្មានទិន្នន័យសម្រាប់ការសម្រេចចិត្ត** — ពួកគេសម្រេចចិត្តដោយផ្អែកលើអារម្មណ៍ មិនមែនផ្អែកលើ data ពិតប្រាកដ

---

### SmartFarm ដោះស្រាយបញ្ហាទាំងនេះដោយរបៀបណា?

#### Finance Tracker — ដឹងច្បាស់ថាលុយទៅណា
កសិករបញ្ចូល income (ប្រាក់ចូល) និង expense (ចំណាយ) រៀងរាល់ថ្ងៃ។ App គណនា profit/loss ស្វ័យប្រវត្តិ ហើយបង្ហាញ summary card ដែលងាយមើល។ គាំទ្ររូបិយប័ណ្ណ Riel (KHR) និង Dollar (USD) ព្រោះកម្ពុជាប្រើប្រាស់ទាំងពីរ។

#### Calendar & Reminders — មិនភ្លេចការងារសំខាន់
កសិករកំណត់ schedule សម្រាប់សកម្មភាពកសិកម្ម (ដាំ, បន្លិចទឹក, បាច់ជី, ច្រូតកាត់)។ App ផ្ញើ notification ជូនដំណឹង 1 ថ្ងៃមុន និងនៅថ្ងៃនោះ ដើម្បីឱ្យពួកគេត្រៀមខ្លួន — ទោះបីជា app បិទក្ដី។

#### Dashboard — រូបភាពទូទៅនៃ farm ទាំងមូល
Home screen បង្ហាញ summary cards ដែលសង្ខេបទិន្នន័យទាំងអស់ក្នុងកន្លែងតែមួយ — profit/loss ខែនេះ, reminders ខាងមុខ, transactions ចុងក្រោយ — ដើម្បីឱ្យកសិករឃើញស្ថានភាព farm ភ្លាមៗ។

#### Export & Reports — ចែករំលែក និងបង្ហាញទៅធនាគារ
Generate PDF report ឬ export CSV ដើម្បីចែករំលែកជាមួយ៖
- គ្រួសារ ដើម្បីពិភាក្សាផែនការហិរញ្ញវត្ថុ
- ធនាគារ ឬ microfinance ដើម្បីស្នើសុំ loan
- អ្នកជំនាញកសិកម្ម ដើម្បីទទួលដំបូន្មាន

#### Backup & Restore — ទិន្នន័យមិនបាត់
Export ទិន្នន័យទាំងអស់ជា JSON ទៅ iCloud Drive ឬ local storage។ បើ phone ខូច ឬចាំងទឹក អាច restore ទិន្នន័យឡើងវិញបានភ្លាមៗ ដោយគ្មានការបាត់បង់ records ណាមួយ។

---

### អត្ថប្រយោជន៍សំខាន់ៗ

| អត្ថប្រយោជន៍ | ការពន្យល់ |
|--------------|-----------|
| **Works Offline** | មិនត្រូវការ internet — ប្រើបានគ្រប់ទីកន្លែង រួមទាំងតំបន់ដាច់ស្រយាល |
| **ភាសាខ្មែរ** | UI ជាភាសាខ្មែរ ងាយយល់សម្រាប់អ្នកប្រើប្រាស់ក្នុងស្រុក |
| **KHR និង USD** | គាំទ្ររូបិយប័ណ្ណទាំងពីរ ស្របតាមការប្រើប្រាស់ជាក់ស្ដែងនៅកម្ពុជា |
| **Simple UI** | រចនាឡើងសម្រាប់អ្នកដែលមិនជំនាញបច្ចេកវិទ្យា |
| **Data Safety** | Backup ស្វ័យប្រវត្តិ ទិន្នន័យមិនបាត់ |
| **Free & Private** | គ្មាន subscription, គ្មាន cloud server, ទិន្នន័យនៅក្នុង device តែប៉ុណ្ណោះ |

---

## តម្រូវការ(Requirement)

| ធាតុ | តម្រូវការ | កំណត់ចំណាំ |
|------|-----------|------------|
**Macos** | 11.x (គ្រប់កំណែ) | Davy និង Monineath ប្រើ នៅលើ Virtual VM |
| **Xcode** | 13.x (គ្រប់កំណែ) | Davy និង Monineath ប្រើ Xcode 13 នៅលើ Virtual VM |
| **Swift** | 5.5 | កំណែលំនាំដើមរបស់ Xcode 13 |
| **iOS Deployment Target** | **14.0** | ប្រើបានជាមួយ Xcode 13.x គ្រប់កំណែ |
| **SwiftUI** | iOS 14+ APIs តែប៉ុណ្ណោះ | គ្មាន SwiftData, គ្មាន Swift Charts, ប្រើ CoreData Persistence |
| **Third-party dependencies** | គ្មាន | គ្មាន CocoaPods, គ្មាន SPM packages |

### APIs ដែលត្រូវប្រើ (Xcode 13 safe)
- `NavigationView` + `NavigationLink` — **មិន**ប្រើ `NavigationStack` (iOS 16+)
- `TabView` ជាមួយ `tabItem`
- `@StateObject`, `@ObservedObject`, `@EnvironmentObject`
- `@FetchRequest` សម្រាប់ CoreData
- `ToolbarItem` ជាមួយ `placement: .navigationBarTrailing / .navigationBarLeading`
- `UNUserNotificationCenter` សម្រាប់ local notifications
- `UIActivityViewController` បង្កប់ក្នុង `UIViewControllerRepresentable`
- `UIDocumentPickerViewController` បង្កប់ក្នុង `UIViewControllerRepresentable`
- `PDFKit` សម្រាប់បង្កើត PDF
- `GeometryReader` + `Rectangle` shapes សម្រាប់ charts
- `PreviewProvider` សម្រាប់ Xcode previews — **មិន**ប្រើ `#Preview {}` macro (Xcode 15+)

### APIs ដែលត្រូវជៀសវាង (មិនអាចប្រើបាននៅ Xcode 13)
- `NavigationStack`, `NavigationSplitView` — iOS 16+
- `.searchable()` modifier — ប្រើ custom `TextField` search bar ជំនួស
- `Charts` framework (Swift Charts) — iOS 16+
- `SwiftData`, `@Model` — iOS 17+
- `ShareLink` — iOS 16+, ប្រើ `UIActivityViewController` ជំនួស
- `@Observable` macro — iOS 17+
- `ContentUnavailableView` — iOS 17+
- `#Preview {}` macro — Xcode 15+

---

## ក្រុមការងារ

| តួនាទី | សមាជិក | ការទទួលខុសត្រូវ |
|--------|--------|----------------|
| **Project Supervisor** | Leader | Project Setup, Architecture |
| **Member** | Davy | Finance Tracker Module,  CoreData, Navigation, Dashboard |
| **Member** | Monineath | Calendar & Reminders Module, CoreData, UI, Export, Backup |

---

## ផែនការសាងសង់

### Leader — Project Setup & MVVM Architecture

- រៀបចំ Xcode project ជាមួយ folder structure សមស្រប និង iOS 14.0 deployment target
- MVVM ជាមួយ `ObservableObject` និង `@Published` properties
- បង្កើត data models ស្នូល: `Transaction`, `FarmActivity`
- បង្កើត `FarmManager` (main view model) ដើម្បីសម្របសម្រួលមុខងារទាំងអស់
- រៀបចំ project folders: `Models`, `ViewModels`, `Views`, `Utilities`
- Implement `FarmViewModel` ជាមួយ `@Published` arrays
- បង្កើត main tab view ជាមួយ 3 tabs: Finance, Calendar, Dashboard

### Davy និង Monineath — CoreData Persistence

- រៀបចំ `.xcdatamodeld` schema សម្រាប់ models ទាំងអស់
- កំណត់ `NSPersistentContainer` និង `NSManagedObjectContext`
- ប្រើ `@FetchRequest` សម្រាប់ UI updates ស្វ័យប្រវត្តិ
- CRUD operations មូលដ្ឋាន (Create, Read, Update, Delete) ជាមួយ CoreData
- បន្ថែម sample data នៅការចាប់ផ្ដើមដំបូងដោយប្រើ seed method
- ផ្ទៀងផ្ទាត់ថាទិន្នន័យនៅតែមានក្រោយពីចាប់ផ្ដើម app ឡើងវិញ

### Davy  — Navigation & Tab Coordination

- `NavigationView` និង `NavigationLink` សម្រាប់ tabs នីមួយៗ
- បង្កើត `NavigationCoordinator` ដោយប្រើ `@State` និង `@Binding`
- បញ្ជូនទិន្នន័យរវាងអេក្រង់ (ឧ. ពីបញ្ជីទៅ detail)
- បង្កើត list → detail navigation សម្រាប់ transactions
- បន្ថែមមុខងារ "Edit" ជាមួយ navigation ត្រឹមត្រូវ

### Davy — Dashboard & Cross-Module Integration

- បង្កើត dashboard tab ជាមួយ summary cards
- បង្ហាញ transactions ថ្មីៗ និងសកម្មភាពខាងមុខ
- បង្ហាញ profit/loss សរុបសម្រាប់ខែបច្ចុប្បន្ន
- បង្កើតប៊ូតុង "Quick Actions" សម្រាប់ការងារទូទៅ
- Home tab ជាមួយ 4–6 summary cards
- Navigation ពី card នីមួយៗទៅ tab ដែលពាក់ព័ន្ធ
- បង្ហាញ reminders ក្នុង 7 ថ្ងៃខាងមុខ

### Davy និង Monineath — Advanced UI & Animations

- បង្កើត custom `ViewModifier`s សម្រាប់រចនាប័ទ្មស៊ីសង្វាក់
- បង្កើត reusable components: `FarmCard`, `PrimaryButton`, `SectionHeader`
- បន្ថែម animations ស្រើបៗ: fade-in សម្រាប់ lists, scale សម្រាប់ buttons
- Implement pull-to-refresh និង loading states
- គាំទ្រ dark mode និង accessibility
- បង្កើតឯកសារ design system ជាមួយ colors, fonts, spacing

### Davy និង Monineath — Data Export & Reports

- Bar charts ប្រចាំខែ profit/loss ដោយប្រើ `GeometryReader` + `Rectangle` shapes (គ្មាន Swift Charts)
- Export ទិន្នន័យជា CSV ឬ PDF
- `UIActivityViewController` សម្រាប់ share reports
- Simple PDF generator ដោយប្រើ `PDFKit`

### Davy និង Monineath — Backup & Restore

- Export/import CoreData records ទាំងអស់ជា JSON,CSV,PDF
- `UIDocumentPickerViewController` បង្កប់ក្នុង `UIViewControllerRepresentable`
- ការរំឭក backup ប្រចាំសប្ដាហ៍ស្វ័យប្រវត្តិ
- iCloud Drive integration មូលដ្ឋាន

---

### Davy — Finance Tracker Module

- បញ្ជី transactions ជាមួយការច្រោះ (expense / income / all)
- ទម្រង់ "Add Transaction" ជាមួយ category picker
- ការគណនាក្នុងពេលជាក់ស្ដែង (total expenses, income, profit)
- ការធ្វើទ្រង់ទ្រាយរូបិយប័ណ្ណ: ការគាំទ្ររូបិយប័ណ្ណ Riel (KHR) និង Dollar (USD)
- Summary card បង្ហាញ balance បច្ចុប្បន្ន, total expenses, total income
- Category filtering: Seeds, Fertilizer, Labor, Tools, Sales

---

### Monineath — Calendar & Reminders Module

- Calendar view ជាមួយ `DatePicker` និងបញ្ជីសកម្មភាព
- `FarmActivity` model: date, type, notes
- សុំការអនុញ្ញាត notifications
- កំណត់ local notifications ជាមួយ `UNUserNotificationCenter` (1 ថ្ងៃមុន + នៅថ្ងៃនោះ)
- ដោះស្រាយការចុច notification ដើម្បីបើក activity ជាក់លាក់
- CRUD ពេញលេញ (Create, Read, Update, Delete) សម្រាប់ activities
- ធ្វើតេស្ត notifications ដំណើរការទោះបីជា app បិទក្ដី

---

## សង្ខេប Modules

| Module | ម្ចាស់ | មុខងារ |
|--------|--------|--------|
| **Project Setup & Architecture** | Leader | MVVM structure, folder setup, tab view |
| **CoreData Persistence** | Davy និង Monineath  | Schema, CRUD, seed data |
| **Navigation & Tab Coordination** | Davy និង Monineath | NavigationView, deep linking |
| **Finance Tracker** | Davy | Income/expense tracking, profit reports, categories |
| **Calendar & Reminders** | Monineath | Activity scheduling, local notifications |
| **Dashboard** | Davy និង Monineath  | Unified view of all farm data |
| **Reports & Charts** | Davy និង Monineath  | Visual profit/loss analysis |
| **Backup & Restore** | Davy និង Monineath  | Data safety and portability |

---
