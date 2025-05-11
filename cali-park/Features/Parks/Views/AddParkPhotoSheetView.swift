import SwiftUI
import PhotosUI

// MARK: - AddParkPhotoSheetView
struct AddParkPhotoSheetView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var photosVM: ParkPhotosViewModel

    // Selected image
    @State private var pickerItem: PhotosPickerItem?
    @State private var imageData: Data?

    // Visibility
    @State private var visibility: CommunityPhoto.Visibility = .public

    // Camera
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .cornerRadius(12)
                } else {
                    // Selection tiles
                    HStack(spacing: 16) {
                        // Camera Tile
                        Button {
                            showCamera = true
                        } label: {
                            SelectionTile(icon: "camera", title: "Aparat")
                        }

                        // Library Tile via PhotosPicker
                        PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                            SelectionTile(icon: "photo.on.rectangle", title: "Biblioteka")
                        }
                    }
                    .frame(maxHeight: 140)
                    .onChange(of: pickerItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                imageData = data
                            }
                        }
                    }
                }

                // Visibility picker appears once photo chosen
                if imageData != nil {
                    Picker("Widoczność", selection: $visibility) {
                        Text("Publiczne").tag(CommunityPhoto.Visibility.public)
                        Text("Tylko znajomi").tag(CommunityPhoto.Visibility.friendsOnly)
                    }
                    .pickerStyle(.segmented)
                }

                Spacer()

                if photosVM.isUploading {
                    ProgressView("Dodawanie...")
                        .progressViewStyle(.circular)
                }
            }
            .padding()
            .navigationTitle("Dodaj zdjęcie")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz") {
                        if let data = imageData {
                            Task {
                                await photosVM.add(imageData: data, visibility: visibility)
                                dismiss()
                            }
                        }
                    }
                    .disabled(imageData == nil || photosVM.isUploading)
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView { data in
                imageData = data
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AddParkPhotoSheetView()
        .environmentObject(ParkPhotosViewModel(parkID: Park.mock.first!.id))
        .preferredColorScheme(.dark)
}

// MARK: - SelectionTile
private struct SelectionTile: View {
    let icon: String
    let title: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 34))
            Text(title)
                .font(.caption)
        }
        .foregroundColor(.accent)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
} 