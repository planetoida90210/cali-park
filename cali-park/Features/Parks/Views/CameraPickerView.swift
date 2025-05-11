import SwiftUI
import UIKit

// MARK: - CameraPickerView (UIKit wrapper)
/// Incydentalne użycie UIKit do przechwytywania zdjęcia aparatem.
/// Zwraca skompresowane JPEG Data poprzez callback `onImageCapture`.
struct CameraPickerView: UIViewControllerRepresentable {

    typealias UIViewControllerType = UIImagePickerController
    typealias Callback = (Data) -> Void

    @Environment(\.dismiss) private var dismiss
    let onImageCapture: Callback

    // MARK: - Coordinator
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.85) {
                parent.onImageCapture(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - UIViewControllerRepresentable
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Preview
#Preview {
    CameraPickerView { _ in }
} 