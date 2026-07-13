import Foundation
import Combine

// MARK: - ParkPhotosViewModel
@MainActor
final class ParkPhotosViewModel: ObservableObject {

    // MARK: Published
    @Published private(set) var photos: [CommunityPhoto] = []
    @Published var errorMessage: String?
    @Published var isUploading: Bool = false
    @Published var lastAdded: CommunityPhoto?

    // Simple in-memory store of comments keyed by photo ID – prepared for backend swap.
    @Published private(set) var comments: [UUID: [PhotoComment]] = [:]

    // MARK: Dependencies
    private let service: CommunityPhotoServiceProtocol
    private let parkID: UUID

    // Handle for the in-flight load so a superseding request can cancel the
    // stale one (and teardown cancels it too) – avoids stale-overwrite once a
    // real backend replaces the stub.
    private var fetchTask: Task<Void, Never>?

    // MARK: Init
    init(parkID: UUID,
         service: CommunityPhotoServiceProtocol = InMemoryCommunityPhotoService()) {
        self.parkID = parkID
        self.service = service
        reload()
    }

    deinit {
        fetchTask?.cancel()
    }

    // MARK: - Intentions
    /// Cancels any in-flight load and starts a fresh one.
    func reload() {
        fetchTask?.cancel()
        fetchTask = Task { [weak self] in await self?.fetch() }
    }

    func fetch() async {
        do {
            let fetched = try await service.fetchPhotos(for: parkID)
            guard !Task.isCancelled else { return }
            photos = fetched
        } catch is CancellationError {
            // Superseded by a newer request – ignore.
        } catch {
            errorMessage = "Błąd pobierania zdjęć: \(error.localizedDescription)"
        }
    }

    func delete(_ photo: CommunityPhoto) {
        Task {
            do {
                try await service.deletePhoto(id: photo.id)
                photos.removeAll { $0.id == photo.id }
            } catch {
                errorMessage = "Nie udało się usunąć zdjęcia. Spróbuj ponownie."
            }
        }
    }

    // MARK: - Likes
    func toggleLike(for photo: CommunityPhoto) {
        guard let idx = photos.firstIndex(where: { $0.id == photo.id }) else { return }
        photos[idx].isLikedByMe.toggle()
        photos[idx].likes += photos[idx].isLikedByMe ? 1 : -1
        // TODO: send like/unlike to backend once available
    }

    // MARK: - Visibility
    func toggleVisibility(for photo: CommunityPhoto) {
        guard let idx = photos.firstIndex(where: { $0.id == photo.id }) else { return }
        photos[idx].visibility = (photos[idx].visibility == .public) ? .friendsOnly : .public
        // TODO: update visibility on backend
    }

    // MARK: - Comments (local only for now)
    func addComment(to photoID: UUID, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let comment = PhotoComment(id: UUID(), authorName: "Ty", text: trimmed, createdAt: .now)
        comments[photoID, default: []].append(comment)
        // TODO: upload comment to backend
    }

    // MARK: - Private
    private func upload(photo: CommunityPhoto) async {
        do {
            let uploaded = try await service.uploadPhoto(photo)
            photos.insert(uploaded, at: 0)
            lastAdded = uploaded
        } catch {
            errorMessage = "Nie udało się dodać zdjęcia. Spróbuj ponownie."
        }
    }

    // MARK: - Add real photo
    func add(imageData: Data, visibility: CommunityPhoto.Visibility) async {
        isUploading = true
        defer { isUploading = false }

        // Save to caches directory so AsyncImage can load it immediately
        let filename = UUID().uuidString + ".jpg"
        let fileURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        do {
            try imageData.write(to: fileURL, options: .atomic)
            let newPhoto = CommunityPhoto(
                parkID: parkID,
                imageURL: fileURL,
                uploaderName: "Ty",
                uploadDate: .now,
                visibility: visibility
            )
            // Optimistic insert
            photos.insert(newPhoto, at: 0)
            lastAdded = newPhoto
            _ = try await service.uploadPhoto(newPhoto) // stub delay
        } catch {
            errorMessage = "Nie udało się zapisać zdjęcia. Spróbuj ponownie."
        }
    }
}

// MARK: - PhotoComment Model (local-only UI phase)
struct PhotoComment: Identifiable, Equatable, Hashable {
    let id: UUID
    let authorName: String
    let text: String
    let createdAt: Date

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: .now)
    }
} 