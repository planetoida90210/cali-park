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
            VStack(spacing: 20) {
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    if let imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .cornerRadius(12)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(uiColor: .secondarySystemBackground))
                                .frame(height: 220)
                            VStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 40))
                                Text("Wybierz zdjęcie")
                                    .font(.caption)
                            }
                            .foregroundColor(.textSecondary)
                        }
                    }
                }
                .onChange(of: pickerItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            imageData = data
                        }
                    }
                }

                Picker("Widoczność", selection: $visibility) {
                    Text("Publiczne").tag(CommunityPhoto.Visibility.public)
                    Text("Tylko znajomi").tag(CommunityPhoto.Visibility.friendsOnly)
                }
                .pickerStyle(.segmented)

                Spacer()

                Button {
                    showCamera = true
                } label: {
                    Label("Zrób zdjęcie", systemImage: "camera")
                        .font(.bodyMedium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accent.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(photosVM.isUploading)

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