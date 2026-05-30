import SwiftUI
import UniformTypeIdentifiers

/// Backup & Restore screen: export all data to a JSON file (share sheet) and
/// restore from a picked JSON file. Pushed from the Settings tab.
struct BackupView: View {
    let environment: AppEnvironment

    @State private var shareItems: [Any] = []
    @State private var showingShare = false
    @State private var showingPicker = false
    @State private var message: String?

    private var service: BackupService { environment.makeBackupService() }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.m) {
                FarmCard {
                    Text(L("backup.description"))
                        .font(Theme.Fonts.body)
                        .foregroundColor(Theme.secondaryText)
                }

                PrimaryButton(title: L("backup.export"), systemImage: "square.and.arrow.up") {
                    exportBackup()
                }
                PrimaryButton(title: L("backup.restore"), systemImage: "square.and.arrow.down") {
                    showingPicker = true
                }

                if let message = message {
                    Text(message)
                        .font(Theme.Fonts.caption)
                        .foregroundColor(Theme.secondaryText)
                }
            }
            .padding(Theme.Spacing.m)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(L("settings.backup"))
        .sheet(isPresented: $showingShare) { ActivityShareSheet(items: shareItems) }
        .sheet(isPresented: $showingPicker) {
            DocumentPicker(contentTypes: [.json]) { url in
                let ok = service.restore(from: url)
                message = ok ? L("backup.restoreSuccess") : L("backup.restoreFailed")
            }
        }
    }

    private func exportBackup() {
        guard let url = service.exportFile() else {
            message = L("backup.exportFailed")
            return
        }
        shareItems = [url]
        showingShare = true
    }
}
