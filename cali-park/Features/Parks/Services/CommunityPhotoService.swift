import Foundation
import Combine

// MARK: - CommunityPhotoServiceProtocol
/// Protocol defining CRUD operations for park community photos.
protocol CommunityPhotoServiceProtocol {
    /// Load all photos for given park.
    func fetchPhotos(for parkID: UUID) async throws -> [CommunityPhoto]

    /// Persist (upload) a new photo.
    func uploadPhoto(_ photo: CommunityPhoto) async throws -> CommunityPhoto

    /// Delete photo with provided identifier.
    func deletePhoto(id: UUID) async throws
}

// MARK: - In-Memory Stub Implementation
/// Simple in-memory storage used during UI-first phase.
/// Replace with network implementation once backend is ready.
@MainActor
final class InMemoryCommunityPhotoService: CommunityPhotoServiceProtocol {

    // Singleton keeps photos alive across views during preview / runtime.
    static let shared = InMemoryCommunityPhotoService()

    private init() {
        storage = CommunityPhoto.mock
    }

    // Private store
    private var storage: [CommunityPhoto]

    // MARK: - API
    func fetchPhotos(for parkID: UUID) async throws -> [CommunityPhoto] {
        // Simulate slight latency
        try await Task.sleep(nanoseconds: 300_000_000)
        let subset = storage.filter { $0.parkID == parkID }
        if subset.isEmpty {
            // Inject default mock photos for this park so UI isn't empty during demo
            let added = CommunityPhoto.mock.prefix(3).map { base in
                CommunityPhoto(parkID: parkID,
                               imageURL: base.imageURL,
                               uploaderName: base.uploaderName,
                               uploadDate: base.uploadDate)
            }
            storage.append(contentsOf: added)
            return added
        }
        return subset
    }

    func uploadPhoto(_ photo: CommunityPhoto) async throws -> CommunityPhoto {
        try await Task.sleep(nanoseconds: 500_000_000)
        storage.insert(photo, at: 0)
        return photo
    }

    func deletePhoto(id: UUID) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
        storage.removeAll { $0.id == id }
    }
} 