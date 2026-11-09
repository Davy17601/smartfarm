import SwiftUI

/// Wraps `UIVisualEffectView` so SwiftUI content can sit on a real system
/// blur. SwiftUI's own `.background(.material)` / `.ultraThinMaterial`
/// blur modifiers need iOS 15+, which this app's iOS 14 target can't use.
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct BlurView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.green
            BlurView(style: .systemUltraThinMaterialDark)
                .frame(width: 200, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .previewLayout(.sizeThatFits)
        .frame(width: 280, height: 180)
    }
}
