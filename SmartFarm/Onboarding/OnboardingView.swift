//
//  OnboardingView.swift
//  SmartFarm
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.7, blue: 0.4),
                    Color(red: 0.2, green: 0.5, blue: 0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)

                // Logo - using leaf SF Symbol as agriculture icon (matches Dashboard)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.bottom, 24)

                // App Title - Welcome message in Khmer
                Text("ស្វាគមន៍ Farm របស់អ្នក")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.2))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)

                // Subtitle in Khmer
                Text("តាមដាន | គ្រប់គ្រង | វិភាគប្រាក់ចំណេញ")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)

                // Description text
                Text("ជួយអ្នកគ្រប់គ្រងហិរញ្ញវត្ថុកសិដ្ឋានបានយ៉ាងងាយស្រួល")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // Start button
                Button(action: {
                    showOnboarding = false
                }) {
                    Text("ចាប់ផ្ដើម")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Color(red: 0.1, green: 0.5, blue: 0.2)
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(showOnboarding: .constant(true))
    }
}
