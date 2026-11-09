import SwiftUI
import PhotosUI

/// Wraps `PHPickerViewController` for picking a single photo from the
/// library (iOS 14+) — unlike the older `UIImagePickerController` photo
/// source, this needs no photo-library permission prompt at all.
struct PhotoPicker: UIViewControllerRepresentable {
    let onPick: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (UIImage?) -> Void
        init(onPick: @escaping (UIImage?) -> Void) { self.onPick = onPick }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                onPick(nil)
                return
            }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.onPick(image as? UIImage)
                }
            }
        }
    }
}
