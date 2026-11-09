import SwiftUI

/// A rectangle with only the given corners rounded — SwiftUI's own
/// `RoundedRectangle` always rounds all four, and `UnevenRoundedRectangle`
/// needs iOS 16, so this wraps `UIBezierPath(roundedRect:byRoundingCorners:)`
/// (iOS 11+) to stay iOS 14-compatible. Used for panels whose top corners are
/// rounded but bottom corners are square — e.g. `AddEditActivityView`'s white
/// form panel overlapping its green header.
struct RoundedCorner: Shape {
    var radius: CGFloat = 12
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                                 cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct RoundedCorner_Previews: PreviewProvider {
    static var previews: some View {
        RoundedCorner(radius: 28, corners: [.topLeft, .topRight])
            .fill(Color.white)
            .frame(width: 200, height: 120)
            .background(Color.green)
            .previewLayout(.sizeThatFits)
    }
}
