import SwiftUI

/// Draws a 2-color gradient as a row/column of many thin solid rectangles
/// instead of a native `LinearGradient`.
///
/// This build's renderer has a confirmed color-interpolation bug: a true
/// `LinearGradient` between two distinct, fully-opaque colors comes out
/// desaturated toward a muddy olive/khaki tone — reproduced regardless of
/// how the colors are constructed (`Color(red:green:blue:)`, explicit
/// `.sRGB`, `UIColor`-bridged) or how many intermediate stops are added,
/// while solid fills and same-color-different-opacity fades always render
/// exactly as specified. Stepping through many solid rectangles sidesteps
/// the broken interpolation entirely. Horizontal/vertical only — every use
/// in this app is a header bar, button, or card gradient along one axis.
struct TwoStopGradient: View {
    let start: Color
    let end: Color
    var axis: Axis = .horizontal
    var steps: Int = 24

    var body: some View {
        let startRGB = start.rgbComponents
        let endRGB = end.rgbComponents
        let stripeColors: [Color] = (0..<steps).map { i in
            let t = steps > 1 ? Double(i) / Double(steps - 1) : 0
            return Color(red: startRGB.r + t * (endRGB.r - startRGB.r),
                         green: startRGB.g + t * (endRGB.g - startRGB.g),
                         blue: startRGB.b + t * (endRGB.b - startRGB.b))
        }
        Group {
            if axis == .horizontal {
                HStack(spacing: 0) {
                    ForEach(0..<steps, id: \.self) { Rectangle().fill(stripeColors[$0]) }
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(0..<steps, id: \.self) { Rectangle().fill(stripeColors[$0]) }
                }
            }
        }
    }
}

private extension Color {
    var rgbComponents: (r: Double, g: Double, b: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
}

struct TwoStopGradient_Previews: PreviewProvider {
    static var previews: some View {
        TwoStopGradient(start: Color(red: 0x66 / 255, green: 0xBB / 255, blue: 0x6A / 255),
                         end: Color(red: 0x2E / 255, green: 0x7D / 255, blue: 0x32 / 255))
            .frame(height: 60)
            .previewLayout(.sizeThatFits)
    }
}
