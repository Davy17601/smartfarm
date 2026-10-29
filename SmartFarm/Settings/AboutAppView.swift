import SwiftUI

struct AboutAppView: View {
    @Environment(\.presentationMode) var presentationMode

    private let primaryText = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let secondaryText = Color(red: 0.22, green: 0.26, blue: 0.32) // #374151
    private let pageBackground = Color(red: 0.92, green: 0.96, blue: 0.91) // #EAF4E7
    private let brandGreen = Color(red: 0.18, green: 0.49, blue: 0.20) // #2E7D32

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(L("common.version")) \(version) (\(build))"
    }

    var body: some View {
        ZStack(alignment: .top) {
            pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header
                customHeader

                VStack(spacing: 32) {
                    // App icon placeholder (leaf circle)
                    ZStack {
                        Circle()
                            .fill(brandGreen.opacity(0.1))
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundColor(brandGreen)
                    }
                    .frame(width: 100, height: 100)

                    // App name
                    Text("SmartFarm")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(primaryText)

                    // Version
                    Text(versionString)
                        .font(.system(size: 15))
                        .foregroundColor(secondaryText)

                    // Description
                    Text(L("settings.appDescription"))
                        .font(.system(size: 15))
                        .foregroundColor(secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 60)

                Spacer()
            }
        }
        .navigationBarHidden(true)
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
            Text(L("settings.aboutApp"))
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(primaryText)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }
}
