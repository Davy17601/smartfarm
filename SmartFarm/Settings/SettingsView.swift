import SwiftUI

/// Settings tab — green gradient header overlapped by a white rounded-top
/// panel (same composition as `AddEditActivityView`), holding an app-info
/// card plus three sectioned white cards (preferences / data / about). Same
/// settings and navigation destinations as before — this is a UI-only
/// redesign using this app's bright-green identity instead of the system
/// grouped-list style.
struct SettingsView: View {
    let environment: AppEnvironment

    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var settings: AppSettings

    // MARK: - Palette

    private let headerColor = Color(red: 0x2E / 255, green: 0x7D / 255, blue: 0x32 / 255)
    private let labelGreen  = Color(red: 0x1B / 255, green: 0x5E / 255, blue: 0x20 / 255)
    private let mutedGreen  = Color(red: 0x4E / 255, green: 0x6E / 255, blue: 0x50 / 255)
    private let panelBackground = Color(red: 0xF3 / 255, green: 0xF8 / 255, blue: 0xF1 / 255)
    private let dividerColor = Color(red: 0xE4 / 255, green: 0xEA / 255, blue: 0xE2 / 255)
    private let pillBackground = Color(red: 0xE8 / 255, green: 0xF5 / 255, blue: 0xE9 / 255)
    private let grayIcon = Color(red: 0x9E / 255, green: 0x9E / 255, blue: 0x9E / 255)

    private let headerBlockHeight: CGFloat = 130
    private let panelTopInset: CGFloat = 104
    private let panelCornerRadius: CGFloat = 28

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                panelBackground.ignoresSafeArea()

                Rectangle()
                    .fill(headerColor)
                    .frame(height: headerBlockHeight)
                    .ignoresSafeArea(edges: .top)
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

                headerTitleBar

                VStack(spacing: 0) {
                    Color.clear.frame(height: panelTopInset)

                    ScrollView {
                        content
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 110)
                    }
                    .background(
                        RoundedCorner(radius: panelCornerRadius, corners: [.topLeft, .topRight])
                            .fill(panelBackground)
                    )
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(headerColor)
    }

    // MARK: - Header

    private var headerTitleBar: some View {
        Text(L("tab.settings"))
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 10)
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 20) {
            appInfoCard

            section(title: L("settings.preferences")) {
                menuRow(icon: "globe", iconBackground: Theme.Category.blue,
                        title: L("settings.language"), value: localization.language.displayName) {
                    ForEach(AppLanguage.allCases) { option in
                        Button {
                            localization.language = option
                        } label: {
                            Label(option.displayName,
                                  systemImage: localization.language == option ? "checkmark.circle.fill" : "circle")
                        }
                    }
                }

                Divider().padding(.leading, 52)

                menuRow(icon: "calendar", iconBackground: Theme.Category.orange,
                        title: L("settings.weekStartDay"), value: settings.weekStartDay.displayName) {
                    ForEach(WeekStartDay.allCases) { option in
                        Button {
                            settings.weekStartDay = option
                        } label: {
                            Label(option.displayName,
                                  systemImage: settings.weekStartDay == option ? "checkmark.circle.fill" : "circle")
                        }
                    }
                }
            }

            section(title: L("settings.data")) {
                NavigationLink {
                    ReportsView(activityRepository: environment.activityRepository,
                                reminderRepository: environment.reminderRepository)
                } label: {
                    rowContent(icon: "chart.bar.fill", iconBackground: Theme.Category.green,
                               title: L("settings.reports"), value: nil)
                }

                Divider().padding(.leading, 52)

                NavigationLink {
                    BackupView(environment: environment)
                } label: {
                    rowContent(icon: "externaldrive.fill", iconBackground: Theme.Category.purple,
                               title: L("settings.backup"), value: nil)
                }
            }

            section(title: L("settings.about")) {
                NavigationLink {
                    AboutView()
                } label: {
                    rowContent(icon: "info.circle.fill", iconBackground: grayIcon,
                               title: L("common.version"), value: "1.0")
                }
            }
        }
    }

    // MARK: - App info card

    private var appInfoCard: some View {
        HStack(spacing: 14) {
            CalendarLogoView(size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(L("appWelcome.splashTitle"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(labelGreen)
                    .lineLimit(1)

                Text(L("appWelcome.splashSubtitle"))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(mutedGreen)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(L("common.version")) 1.0")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(labelGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(pillBackground))
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Section card

    private func section<Content: View>(title: String, @ViewBuilder rows: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(labelGreen)
                .lineSpacing(4)
                .padding(.leading, 4)

            VStack(spacing: 0) { rows() }
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                )
        }
    }

    // MARK: - Rows

    /// Icon + label + optional trailing value + chevron — the shared visual
    /// content of every row, used both for plain navigation rows and as the
    /// label of a `Menu` for the pickable rows below.
    private func rowContent(icon: String, iconBackground: Color, title: String, value: String?) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(iconBackground)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Theme.primaryText)
                .lineSpacing(4)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 8)

            if let value = value {
                Text(value)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.secondaryText)
                    .lineLimit(1)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.secondaryText.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .frame(height: 56)
        .contentShape(Rectangle())
    }

    /// A row that opens a `Menu` of options instead of pushing a screen —
    /// used for Language and Week-start, matching the same `Menu`-over-a-
    /// styled-row pattern already used by `AddEditActivityView`'s category
    /// field, so the row's own appearance (icon, value, chevron) stays fully
    /// under this screen's control.
    private func menuRow<MenuContent: View>(icon: String, iconBackground: Color, title: String, value: String,
                                             @ViewBuilder options: () -> MenuContent) -> some View {
        Menu {
            options()
        } label: {
            rowContent(icon: icon, iconBackground: iconBackground, title: title, value: value)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(environment: AppEnvironment(persistence: .preview))
            .environmentObject(LocalizationManager.shared)
            .environmentObject(AppSettings.shared)
    }
}
