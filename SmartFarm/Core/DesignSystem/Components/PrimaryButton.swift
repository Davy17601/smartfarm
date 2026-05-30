import SwiftUI

/// Full-width primary action button in the brand color.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.s) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                }
                Text(title).font(Theme.Fonts.heading)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.m)
            .background(Theme.brand)
            .foregroundColor(.white)
            .cornerRadius(Theme.Radius.button)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryButton(title: "បន្ថែម", systemImage: "plus") {}
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
