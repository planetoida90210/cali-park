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
    /// Visibility scope of the photo (public for everyone or friends only)
    var visibility: Visibility = .public

    /// Optional short text describing the photo (max 140 chars, validated on backend later).
    var caption: String = "" {
        didSet { caption = String(caption.prefix(140)) }
    }

    /// Total number of likes received from all users.
    var likes: Int = 0 {
        didSet { likes = max(0, likes) }
    }

    /// Convenience flag – did current (authenticated) user like this photo? Will be replaced by user-specific backend data later.
    var isLikedByMe: Bool = false

    /// Short, human-readable date (e.g. "maj ‘25")
    var formattedDate: String {
        Self.dateFormatter.string(from: uploadDate)
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "LLL yy" // e.g. "Mar 24"
        return df
    }()

    // MARK: - Visibility
    enum Visibility: String, Codable, CaseIterable, Hashable {
        case `public` = "public"
        case friendsOnly = "friends"
    }

    // MARK: Init
    init(id: UUID = UUID(),
         parkID: UUID,
         imageURL: URL,
         uploaderName: String,
         uploadDate: Date = .now,
         visibility: Visibility = .public,
         caption: String = "",
         likes: Int = 0,
         isLikedByMe: Bool = false) {
        self.id = id
        self.parkID = parkID
        self.imageURL = imageURL
        self.uploaderName = uploaderName
        self.uploadDate = uploadDate
        self.visibility = visibility
        self.caption = caption
        self.likes = likes
        self.isLikedByMe = isLikedByMe
    }
}

// MARK: - Mock Data
extension CommunityPhoto {
    /// Sample photos from Unsplash for previews.
    static var mock: [CommunityPhoto] {
        guard let firstPark = Park.mock.first else { return [] }
        let urls = [
            "https://plus.unsplash.com/premium_photo-1664301516343-d6f9ede0af39?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTd8fHBhcmslMjBneW18ZW58MHx8MHx8fDA%3D",
            "https://images.unsplash.com/photo-1690746044071-57ae2ee063c7?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8cGFyayUyMGd5bXxlbnwwfHwwfHx8MA%3D%3D",
            "https://images.unsplash.com/photo-1738862438096-ee2f8dc20b45?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MjB8fHBhcmslMjBneW18ZW58MHx8MHx8fDA%3D"
        ].compactMap { URL(string: $0) }

        return urls.enumerated().map { index, url in
            CommunityPhoto(
                parkID: firstPark.id,
                imageURL: url,
                uploaderName: "Użytkownik \(index + 1)",
                uploadDate: Calendar.current.date(byAdding: .day, value: -index * 3, to: .now) ?? .now,
                visibility: .public,
                caption: index % 2 == 0 ? "Świetna sesja na świeżym powietrzu! #workout" : "",
                likes: Int.random(in: 0...42)
            )
        }
    }

    /// Photos associated with a single park (for previews/views).
    static func photos(for parkID: UUID) -> [CommunityPhoto] {
        mock.filter { $0.parkID == parkID }
    }
} 