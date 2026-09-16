//
//  OnboardingView.swift
//  SmartFarm
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool

    var body: some View {
        ZStack {
            // Background image
            Image("onboarding_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)

                // Logo - rice emoji matching Dashboard greeting
                Text("🌾")
                    .font(.system(size: 80))
                    .padding(.bottom, 24)

                // App Title - Welcome message in Khmer with "Farm" highlighted
                (Text("ស្វាគមន៍ ")
                    .foregroundColor(.black)
                 + Text("Farm")
                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.2))
                 + Text(" របស់អ្នក")
                    .foregroundColor(.black))
                    .font(.system(size: 44, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)

                // Subtitle in Khmer
                Text("តាមដាន | គ្រប់គ្រង | វិភាគប្រាក់ចំណេញ")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)

                // Description text
                Text("ជួយអ្នកគ្រប់គ្រងហិរញ្ញវត្ថុកសិដ្ឋានបានយ៉ាងងាយស្រួល")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.black.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // Start button - pill-shaped with glassmorphism effect
                Button(action: {
                    showOnboarding = false
                }) {
                    Text("ចាប់ផ្ដើម")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 70)
                        .padding(.vertical, 16)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(Color(red: 0.1, green: 0.5, blue: 0.2))
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.15),
                                                Color.white.opacity(0.05)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
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
