import SwiftUI
import UIKit

/// Wraps `UIActivityViewController` for SwiftUI (iOS 14 has no `ShareLink`).
/// Used to share exported CSV / PDF / JSON files.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
