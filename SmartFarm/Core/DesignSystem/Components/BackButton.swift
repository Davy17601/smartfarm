import SwiftUI

/// Consistent top-left back affordance for manually-presented screens (sheets)
/// that don't get a system back button automatically — mirrors the chevron
/// `NavigationView` draws for pushed screens, so every non-root screen in the
/// app reads the same way.
struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.brand)
        }
    }
}

struct BackButton_Previews: PreviewProvider {
    static var previews: some View {
        BackButton(action: {})
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
