import SwiftUI

/// Full-screen onboarding screen shown once at launch, before the main
/// `TabView` — owned and switched by `RootView` (see `App/RootView.swift`)
/// so it is never nested inside the tab bar. Stays on screen until the user
/// taps the start button; `onStart` is called exactly once, at that point.
struct AppWelcomeView: View {
    let onStart: () -> Void

    @State private var logoAppeared = false

    // MARK: - Palette

    private let ringGreen          = Color(red: 0x66 / 255, green: 0xBB / 255, blue: 0x6A / 255)
    private let buttonStart        = Color(red: 0x43 / 255, green: 0xA0 / 255, blue: 0x47 / 255)
    private let buttonEnd          = Color(red: 0x2E / 255, green: 0x7D / 255, blue: 0x32 / 255)
    private let overlayBottomGreen = Color(red: 0x0B / 255, green: 0x3D / 255, blue: 0x1A / 255)
    private let textShadow         = Color.black.opacity(0.35)

    // Text card palette
    private let cardTitleGreen    = Color(red: 0x1B / 255, green: 0x5E / 255, blue: 0x20 / 255)
    private let cardSubtitleGreen = Color(red: 0x2E / 255, green: 0x7D / 255, blue: 0x32 / 255)
    private let cardTaglineColor  = Color(red: 0x37 / 255, green: 0x54 / 255, blue: 0x3A / 255)

    // MARK: - Logo sizing

    /// ~120pt white disc; the ring and the inner glyph are scaled off it so
    /// the drawing keeps the same proportions it always had.
    private let logoDiscSize: CGFloat = 120
    private var logoRingSize: CGFloat { logoDiscSize + 8 }
    private var logoGlyphSize: CGFloat { logoDiscSize * 0.657 }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                background(in: geo)
            }
            .ignoresSafeArea()

            // Deliberately NOT `.ignoresSafeArea()` here: left to the
            // system's default safe-area-respecting layout so the logo and
            // button clear the Dynamic Island / home indicator on every
            // device without a hardcoded offset. Only ONE `Spacer` in this
            // stack — a second one above the logo would be just as
            // flexible as this one and split the leftover height evenly
            // between them, dragging the logo back down toward the middle
            // instead of letting it sit right under the safe area.
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    logo
                    textCard
                }
                .padding(.top, 24)

                Spacer()

                VStack(spacing: 8) {
                    startButton
                    caption
                }
                .padding(.bottom, Theme.Spacing.s)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Background

    /// The rice field / farmer photo ("onboarding_bg"), full-bleed behind
    /// everything, darkened by two gradient washes so the white logo/text
    /// and the button stay readable without hiding the photo itself: a
    /// black-to-clear wash behind the top block, and a clear-to-dark-green
    /// wash behind the bottom block. The middle of the photo (where the
    /// farmer's hand/tablet are) is left untouched.
    private func background(in geo: GeometryProxy) -> some View {
        ZStack {
            fieldPhoto
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()

            VStack(spacing: 0) {
                LinearGradient(colors: [Color.black.opacity(0.4), Color.black.opacity(0)],
                                startPoint: .top, endPoint: .bottom)
                    .frame(height: geo.size.height * 0.4)
                Spacer(minLength: 0)
            }

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                LinearGradient(colors: [overlayBottomGreen.opacity(0), overlayBottomGreen.opacity(0.85)],
                                startPoint: .top, endPoint: .bottom)
                    .frame(height: geo.size.height * 0.35)
            }
        }
        .frame(width: geo.size.width, height: geo.size.height)
    }

    /// Falls back to a plain green gradient if "onboarding_bg" is ever
    /// missing from the asset catalog, so the layout still reads correctly.
    private var fieldPhoto: some View {
        Group {
            if UIImage(named: "onboarding_bg") != nil {
                Image("onboarding_bg")
                    .resizable()
                    .scaledToFill()
            } else {
                TwoStopGradient(start: ringGreen, end: buttonEnd, axis: .vertical)
            }
        }
    }

    // MARK: - Logo

    /// A white circle (~120pt) with a thin bright-green ring around it,
    /// holding the calendar logo. Scales in from 0.8 and fades in once on
    /// appear (no looping).
    private var logo: some View {
        ZStack {
            Circle()
                .stroke(ringGreen, lineWidth: 4)
                .frame(width: logoRingSize, height: logoRingSize)

            Circle()
                .fill(Color.white)
                .frame(width: logoDiscSize, height: logoDiscSize)
                .shadow(color: Color.black.opacity(0.22), radius: 12, x: 0, y: 6)

            CalendarLogoView(size: logoGlyphSize)
        }
        .scaleEffect(logoAppeared ? 1 : 0.8)
        .opacity(logoAppeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                logoAppeared = true
            }
        }
    }

    // MARK: - Text card

    /// Title/subtitle/tagline sit on a light "glass" card over the photo —
    /// a blurred, mostly-opaque white panel — so the Khmer lines stay
    /// readable against a bright photo without needing a text shadow.
    private var textCard: some View {
        VStack(spacing: 8) {
            trackedTitle

            Capsule()
                .fill(ringGreen)
                .frame(width: 40, height: 3)

            Text(L("appWelcome.splashSubtitle"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(cardSubtitleGreen)
                .lineSpacing(6)
                .minimumScaleFactor(0.8)

            Text(L("appWelcome.splashTagline"))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(cardTaglineColor)
                .lineSpacing(6)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            ZStack {
                BlurView(style: .systemUltraThinMaterialLight)
                Color.white.opacity(0.9)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 24)
    }

    /// "SMART CALENDAR", manually letter-spaced (SwiftUI's `.tracking()` /
    /// `.kerning()` modifiers need iOS 16, which this app's iOS 14 target
    /// can't use) by laying out each character with a small fixed gap.
    private var trackedTitle: some View {
        HStack(spacing: 1.5) {
            ForEach(Array(L("appWelcome.splashTitle").enumerated()), id: \.offset) { _, character in
                Text(String(character))
            }
        }
        .font(.system(size: 32, weight: .heavy, design: .rounded))
        .foregroundColor(cardTitleGreen)
    }

    // MARK: - Start button

    private var startButton: some View {
        Button(action: handleStart) {
            HStack(spacing: 8) {
                Text(L("appWelcome.start"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                TwoStopGradient(start: buttonStart, end: buttonEnd, axis: .horizontal)
            )
            .clipShape(Capsule())
            .shadow(color: buttonEnd.opacity(0.4), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(StartButtonStyle())
        .padding(.horizontal, 24)
    }

    private var caption: some View {
        Text(L("appWelcome.startCaption"))
            .font(.system(size: 13, weight: .regular, design: .rounded))
            .foregroundColor(Color.white.opacity(0.9))
            .shadow(color: textShadow, radius: 4, x: 0, y: 1)
    }

    private func handleStart() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onStart()
    }
}

/// Scales the button down slightly while pressed — plain (non-`value:`)
/// `.animation()` on purpose, since the `value:`-based overload needs iOS 15.
private struct StartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15))
    }
}

struct AppWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AppWelcomeView(onStart: {})
                .previewDevice("iPhone SE (3rd generation)")
            AppWelcomeView(onStart: {})
                .previewDevice("iPhone 14 Pro")
        }
    }
}
