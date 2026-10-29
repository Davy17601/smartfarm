import SwiftUI

struct BackupDataView: View {
    @Environment(\.presentationMode) var presentationMode
    let environment: AppEnvironment
    @AppStorage("lastBackupDate") private var lastBackupDate: Double = 0
    @State private var showingShareSheet = false
    @State private var backupFileURL: URL?
    @State private var showingDocumentPicker = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var pendingTransactions: [Transaction]?

    private let primaryText = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let secondaryText = Color(red: 0.22, green: 0.26, blue: 0.32) // #374151
    private let pageBackground = Color(red: 0.92, green: 0.96, blue: 0.91) // #EAF4E7
    private let brandGreen = Color(red: 0.18, green: 0.49, blue: 0.20) // #2E7D32
    private let darkGreen = Color(red: 0.11, green: 0.42, blue: 0.18) // #1B6B2F
    private let pressedGreen = Color(red: 0.08, green: 0.32, blue: 0.18) // #14532D

    var body: some View {
        ZStack(alignment: .top) {
            pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header
                customHeader

                VStack(spacing: 24) {
                    // Description
                    Text(L("settings.backupDescription"))
                        .font(.system(size: 15))
                        .foregroundColor(secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // Backup button
                    PrimaryActionButton(title: L("settings.backupNow"), action: performBackup)
                        .padding(.horizontal, 16)

                    // Last backup card
                    lastBackupCard
                        .padding(.horizontal, 16)

                    // Restore button
                    OutlinedActionButton(
                        title: L("settings.restore"),
                        icon: "icloud.and.arrow.down",
                        action: { showingDocumentPicker = true }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Restore hint
                    Text(L("settings.restoreHint"))
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.29, green: 0.34, blue: 0.39)) // #4B5563
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 4)
                }
                .padding(.top, 24)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingShareSheet) {
            if let url = backupFileURL {
                ActivityShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            JSONDocumentPicker(onPick: handlePickedFile)
        }
        .alert(isPresented: $showingAlert) {
            if let pending = pendingTransactions {
                return Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    primaryButton: .cancel(Text(L("common.cancel"))),
                    secondaryButton: .default(Text(L("settings.restore"))) {
                        performRestore(transactions: pending)
                    }
                )
            } else {
                return Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private var customHeader: some View {
        HStack(spacing: 12) {
            // Back button
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(brandGreen)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }

            // Title
            Text(L("settings.backupData"))
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(primaryText)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    private var lastBackupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("settings.lastBackup"))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(primaryText)

            Text(formattedLastBackupDate)
                .font(.system(size: 14))
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var formattedLastBackupDate: String {
        if lastBackupDate == 0 {
            return L("settings.noBackup")
        }
        let date = Date(timeIntervalSince1970: lastBackupDate)
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.language.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func performBackup() {
        // Fetch all transactions from repository
        let transactions = environment.transactionRepository.fetchAll()

        // Convert to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        guard let jsonData = try? encoder.encode(transactions) else { return }

        // Create temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "smartfarm_backup_\(Int(Date().timeIntervalSince1970)).json"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try jsonData.write(to: fileURL)
            backupFileURL = fileURL
            lastBackupDate = Date().timeIntervalSince1970
            showingShareSheet = true
        } catch {
            print("Backup failed: \(error)")
        }
    }

    private func handlePickedFile(_ url: URL) {
        // Access security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            showError(title: L("settings.invalidFileTitle"), message: L("settings.invalidFileMessage"))
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            // Read file data
            let data = try Data(contentsOf: url)

            // Decode JSON
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let transactions = try decoder.decode([Transaction].self, from: data)

            // Validate non-empty
            guard !transactions.isEmpty else {
                showError(title: L("settings.invalidFileTitle"), message: L("settings.invalidFileMessage"))
                return
            }

            // Show confirmation
            let message = String(format: L("settings.restoreConfirmMessage"), transactions.count)
            alertTitle = L("settings.restoreConfirmTitle")
            alertMessage = message
            pendingTransactions = transactions
            showingAlert = true
        } catch {
            showError(title: L("settings.invalidFileTitle"), message: L("settings.invalidFileMessage"))
        }
    }

    private func performRestore(transactions: [Transaction]) {
        let existingTransactions = environment.transactionRepository.fetchAll()
        var addedCount = 0
        var skippedCount = 0

        for transaction in transactions {
            // Check for duplicates
            let isDuplicate = existingTransactions.contains { existing in
                // Match by ID first
                if existing.id == transaction.id {
                    return true
                }
                // Match by all fields if no ID match
                return existing.date == transaction.date &&
                       existing.amount == transaction.amount &&
                       existing.type == transaction.type &&
                       existing.category == transaction.category &&
                       existing.title == transaction.title
            }

            if isDuplicate {
                skippedCount += 1
            } else {
                environment.transactionRepository.add(transaction)
                addedCount += 1
            }
        }

        // Show success message
        let message = String(format: L("settings.restoreSuccessMessage"), addedCount, skippedCount)
        showError(title: L("settings.restoreSuccessTitle"), message: message)
        pendingTransactions = nil
    }

    private func showError(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        pendingTransactions = nil
        showingAlert = true
    }
}

// Primary action button component
struct PrimaryActionButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false

    private let darkGreen = Color(red: 0.11, green: 0.42, blue: 0.18) // #1B6B2F
    private let pressedGreen = Color(red: 0.08, green: 0.32, blue: 0.18) // #14532D

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isPressed ? pressedGreen : darkGreen)
                .cornerRadius(14)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Outlined action button component
struct OutlinedActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    private let darkGreen = Color(red: 0.11, green: 0.42, blue: 0.18) // #1B6B2F

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(darkGreen)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(darkGreen, lineWidth: 2)
            )
            .cornerRadius(14)
        }
        .buttonStyle(PressableButtonStyle())
    }
}
