import SwiftUI

struct CurrencySelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var settings: AppSettings

    private let primaryText = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let secondaryText = Color(red: 0.22, green: 0.26, blue: 0.32) // #374151
    private let pageBackground = Color(red: 0.92, green: 0.96, blue: 0.91) // #EAF4E7
    private let brandGreen = Color(red: 0.18, green: 0.49, blue: 0.20) // #2E7D32
    private let darkGreen = Color(red: 0.11, green: 0.42, blue: 0.18) // #1B6B2F
    private let selectedBg = Color(red: 0.84, green: 0.93, blue: 0.85) // #D5ECD8

    var body: some View {
        ZStack(alignment: .top) {
            pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header
                customHeader

                // Currency options
                VStack(spacing: 0) {
                    currencyOption(currency: .khr)

                    Divider()
                        .padding(.leading, 60)

                    currencyOption(currency: .usd)
                }
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.top, 24)

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
            Text(L("settings.displayCurrency"))
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(primaryText)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    private func currencyOption(currency: Currency) -> some View {
        let isSelected = settings.displayCurrency == currency

        return Button(action: {
            settings.displayCurrency = currency
        }) {
            HStack(spacing: 12) {
                // Currency name
                Text(currency.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)

                Spacer()

                // Radio/checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(isSelected ? darkGreen : secondaryText.opacity(0.3))
            }
            .padding(16)
            .background(isSelected ? selectedBg : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(isSelected ? darkGreen : Color.clear, lineWidth: isSelected ? 1 : 0)
            )
        }
        .buttonStyle(OpacityButtonStyle())
    }
}
