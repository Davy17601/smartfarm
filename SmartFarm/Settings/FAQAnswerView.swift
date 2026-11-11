import SwiftUI

/// Displays a single FAQ answer with the question icon, title, and detailed answer text
struct FAQAnswerView: View {
    @Environment(\.presentationMode) var presentationMode

    let question: String
    let answer: String
    let icon: String
    let iconColor: Color

    private let pageBackground = Color(red: 0.92, green: 0.96, blue: 0.91) // #EAF4E7
    private let darkGreen = Color(red: 0.11, green: 0.42, blue: 0.18) // #1B6B2F
    private let brandGreen = Color(red: 0.18, green: 0.49, blue: 0.20) // #2E7D32
    private let primaryText = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let secondaryText = Color(red: 0.29, green: 0.34, blue: 0.39) // #4B5563

    var body: some View {
        ZStack(alignment: .top) {
            pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header
                customHeader

                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon circle
                        ZStack {
                            Circle()
                                .fill(iconColor)
                                .frame(width: 80, height: 80)
                            Image(systemName: icon)
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 8)

                        // Answer card
                        VStack(alignment: .leading, spacing: 16) {
                            Text(question)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(darkGreen)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(answer)
                                .font(.system(size: 16))
                                .foregroundColor(secondaryText)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
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
            Text(L("settings.helpFAQ"))
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(primaryText)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }
}
