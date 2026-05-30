import SwiftUI

/// A consistent section title, optionally with a trailing accessory.
struct SectionHeader<Accessory: View>: View {
    let title: String
    private let accessory: Accessory

    init(_ title: String, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.accessory = accessory()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.Fonts.heading)
                .foregroundColor(Theme.primaryText)
            Spacer()
            accessory
        }
    }
}

extension SectionHeader where Accessory == EmptyView {
    init(_ title: String) {
        self.init(title) { EmptyView() }
    }
}

struct SectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            SectionHeader("ប្រតិបត្តិការថ្មីៗ")
            SectionHeader("សកម្មភាព") {
                Text("មើលទាំងអស់").font(Theme.Fonts.caption).foregroundColor(Theme.brand)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
