import SwiftUI

/// Settings tab — language & currency preferences plus entry points to
/// Reports and Backup & Restore.
struct SettingsView: View {
    let environment: AppEnvironment

    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        NavigationView {
            List {
                Section(header: Text(L("settings.preferences"))) {
                    Picker(L("settings.language"), selection: $localization.language) {
                        ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0) }
                    }
                    Picker(L("settings.displayCurrency"), selection: $settings.displayCurrency) {
                        ForEach(Currency.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                }

                Section(header: Text(L("settings.data"))) {
                    NavigationLink {
                        ReportsView(repository: environment.transactionRepository)
                    } label: {
                        Label(L("settings.reports"), systemImage: "chart.bar.doc.horizontal")
                    }

                    NavigationLink {
                        BackupView(environment: environment)
                    } label: {
                        Label(L("settings.backup"), systemImage: "externaldrive")
                    }
                }

                Section(header: Text(L("settings.about"))) {
                    HStack {
                        Text(L("common.version"))
                        Spacer()
                        Text("1.0").foregroundColor(Theme.secondaryText)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(L("tab.settings"))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
