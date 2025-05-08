import Foundation

// MARK: - CommunityPhoto Model
/// Represents a single photo uploaded by the community for given park.
struct CommunityPhoto: Identifiable, Codable, Equatable, Hashable {
    // MARK: Properties
    let id: UUID
    let parkID: UUID
    var imageURL: URL
    var uploaderName: String
    var uploadDate: Date

    /// Short, human-readable date (e.g. "maj ‘25")
    var formattedDate: String {
        Self.dateFormatter.string(from: uploadDate)
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "LLL yy" // e.g. "Mar 24"
        return df
    }()

    // MARK: Init
    init(id: UUID = UUID(),
         parkID: UUID,
         imageURL: URL,
         uploaderName: String,
         uploadDate: Date = .now) {
        self.id = id
        self.parkID = parkID
        self.imageURL = imageURL
        self.uploaderName = uploaderName
        self.uploadDate = uploadDate
    }
}

// MARK: - Mock Data
extension CommunityPhoto {
    /// Sample photos from Unsplash for previews.
    static var mock: [CommunityPhoto] {
        guard let firstPark = Park.mock.first else { return [] }
        let urls = [
            "https://images.unsplash.com/photo-1542762933-9e297eae0fe6",
            "https://images.unsplash.com/photo-1518611012118-f3c3da4432b6",
            "https://images.unsplash.com/photo-1526406915894-99ae31c872b6"
        ].compactMap { URL(string: $0) }

        return urls.enumerated().map { index, url in
            CommunityPhoto(
                parkID: firstPark.id,
                imageURL: url,
                uploaderName: "Użytkownik \(index + 1)",
                uploadDate: Calendar.current.date(byAdding: .day, value: -index * 3, to: .now) ?? .now
            )
        }
    }

    /// Photos associated with a single park (for previews/views).
    static func photos(for parkID: UUID) -> [CommunityPhoto] {
        mock.filter { $0.parkID == parkID }
    }
} 