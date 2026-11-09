import SwiftUI

/// The app's calendar-glyph logo: a white rounded card with a green gradient
/// header, two binder rings, today's day number, and a small sprout icon.
/// Used full-size on the onboarding screen and small (~44pt) in the Home
/// screen's header, so the drawing lives here once instead of being
/// duplicated between them. `size` is the card's width; it scales to a
/// slightly shorter height to match the original card's proportions.
struct CalendarLogoView: View {
    var size: CGFloat = 100

    private let headerStart = Color(red: 0x66 / 255, green: 0xBB / 255, blue: 0x6A / 255)
    private let headerEnd   = Color(red: 0x2E / 255, green: 0x7D / 255, blue: 0x32 / 255)
    private let binderGreen = Color(red: 0x1B / 255, green: 0x5E / 255, blue: 0x20 / 255)
    private let sproutGreen = Color(red: 0x43 / 255, green: 0xA0 / 255, blue: 0x47 / 255)
    private let dayGreen    = Color(red: 0x1B / 255, green: 0x5E / 255, blue: 0x20 / 255)

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: size * 0.24) {
                Capsule().fill(binderGreen).frame(width: size * 0.06, height: size * 0.16)
                Capsule().fill(binderGreen).frame(width: size * 0.06, height: size * 0.16)
            }
            .offset(y: size * 0.07)
            .zIndex(1)

            VStack(spacing: 0) {
                TwoStopGradient(start: headerStart, end: headerEnd, axis: .horizontal)
                    .frame(height: size * 0.26)

                ZStack(alignment: .topTrailing) {
                    Text(todayDayString)
                        .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                        .foregroundColor(dayGreen)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: max(size * 0.13, 8), weight: .semibold))
                        .foregroundColor(sproutGreen)
                        .padding(size * 0.06)
                }
                .background(Color.white)
            }
        }
        .frame(width: size, height: size * 0.9)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: size * 0.08, x: 0, y: size * 0.04)
    }

    private var todayDayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }
}

struct CalendarLogoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CalendarLogoView(size: 100)
            CalendarLogoView(size: 44)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
