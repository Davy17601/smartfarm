import SwiftUI

/// Settings tab — language & calendar preferences plus entry points to
/// Reports and Backup & Restore. Uses its own green accent (matching the
/// Welcome screen and Calendar tab's identity) instead of the app-wide blue
/// `AccentColor`, kept local to this file so no other screen is affected.
struct SettingsView: View {
    let environment: AppEnvironment

    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var settings: AppSettings

    private let deepGreen = Color(red: 0x2E / 255, green: 0x7D / 255, blue: 0x4F / 255)

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text(L("tab.settings"))
                    .font(.largeTitle.bold())
                    .foregroundColor(deepGreen)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.top, Theme.Spacing.m)
                    .padding(.bottom, Theme.Spacing.s)

                List {
                    Section(header: Text(L("settings.preferences"))) {
                        Picker(L("settings.language"), selection: $localization.language) {
                            ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0) }
                        }
                        Picker(L("settings.weekStartDay"), selection: $settings.weekStartDay) {
                            ForEach(WeekStartDay.allCases) { Text($0.displayName).tag($0) }
                        }
                    }

                    Section(header: Text(L("settings.data"))) {
                        NavigationLink {
                            ReportsView(activityRepository: environment.activityRepository,
                                       reminderRepository: environment.reminderRepository)
                        } label: {
                            Label {
                                Text(L("settings.reports"))
                            } icon: {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .foregroundColor(deepGreen)
                            }
                        }

                        NavigationLink {
                            BackupView(environment: environment)
                        } label: {
                            Label {
                                Text(L("settings.backup"))
                            } icon: {
                                Image(systemName: "externaldrive")
                                    .foregroundColor(Theme.Category.amber)
                            }
                        }
                    }

                    Section(header: Text(L("settings.about"))) {
                        NavigationLink {
                            AboutView()
                        } label: {
                            HStack {
                                Text(L("common.version"))
                                Spacer()
                                Text("1.0").foregroundColor(Theme.secondaryText)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(deepGreen)
    }
}
