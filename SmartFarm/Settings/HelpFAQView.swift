import SwiftUI

struct FAQItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let question: String
    let answer: String
}

struct HelpFAQView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedItemID: UUID?

    private let primaryText = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let secondaryText = Color(red: 0.22, green: 0.26, blue: 0.32) // #374151
    private let pageBackground = Color(red: 0.92, green: 0.96, blue: 0.91) // #EAF4E7
    private let brandGreen = Color(red: 0.18, green: 0.49, blue: 0.20) // #2E7D32
    private let darkGreen = Color(red: 0.11, green: 0.42, blue: 0.18) // #1B6B2F

    private var faqItems: [FAQItem] {
        [
            FAQItem(
                icon: "plus.circle.fill",
                iconColor: Color(red: 0.15, green: 0.39, blue: 0.93), // #2563EB
                question: L("settings.faq.addTransaction"),
                answer: L("settings.faq.addTransactionAnswer")
            ),
            FAQItem(
                icon: "chart.bar.fill",
                iconColor: Color(red: 0.85, green: 0.47, blue: 0.02), // #D97706
                question: L("settings.faq.viewReports"),
                answer: L("settings.faq.viewReportsAnswer")
            ),
            FAQItem(
                icon: "globe",
                iconColor: Color(red: 0.40, green: 0.22, blue: 0.72), // #6B37B8
                question: L("settings.faq.changeLanguage"),
                answer: L("settings.faq.changeLanguageAnswer")
            ),
            FAQItem(
                icon: "arrow.down.doc.fill",
                iconColor: Color(red: 0.11, green: 0.42, blue: 0.18), // #1B6B2F
                question: L("settings.faq.backupData"),
                answer: L("settings.faq.backupDataAnswer")
            ),
            FAQItem(
                icon: "list.bullet.rectangle",
                iconColor: Color(red: 0.59, green: 0.27, blue: 0.00), // #964B00
                question: L("settings.faq.categories"),
                answer: L("settings.faq.categoriesAnswer")
            )
        ]
    }

    var body: some View {
        ZStack(alignment: .top) {
            pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header
                customHeader

                // FAQ list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(faqItems) { item in
                            faqRow(item: item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }

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
            Text(L("settings.helpFAQ"))
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(primaryText)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    private func faqRow(item: FAQItem) -> some View {
        let isExpanded = selectedItemID == item.id

        return VStack(spacing: 0) {
            // Question row
            HStack(spacing: 14) {
                // Icon box
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.iconColor)
                    Image(systemName: item.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 38, height: 38)

                // Question text
                Text(item.question)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isExpanded ? darkGreen : brandGreen)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(16)
            .contentShape(Rectangle())

            // Answer (if expanded)
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color(red: 0.89, green: 0.89, blue: 0.89))
                    Text(item.answer)
                        .font(.system(size: 15))
                        .foregroundColor(secondaryText)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isExpanded ? darkGreen : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedItemID == item.id {
                    selectedItemID = nil
                } else {
                    selectedItemID = item.id
                }
            }
        }
    }
}
