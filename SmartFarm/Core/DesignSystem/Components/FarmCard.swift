import SwiftUI

/// A generic rounded card container used across the app.
struct FarmCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct FarmCard_Previews: PreviewProvider {
    static var previews: some View {
        FarmCard {
            Text("ចំណង​ជើង").font(Theme.Fonts.heading)
            Text("មាតិកា").foregroundColor(Theme.secondaryText)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
