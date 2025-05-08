import Foundation

// MARK: - ParkEvent Model
/// Describes a community event related to a specific park (e.g. group training session).
/// Pure-UI phase – data comes from mock provider; later to be replaced by backend API.
struct ParkEvent: Identifiable, Codable, Equatable, Hashable {
    // MARK: Properties
    let id: UUID
    let parkID: UUID
    var title: String
    var date: Date
    var attendeeCount: Int
    var capacity: Int?

    // Computed helpers
    var isFull: Bool {
        if let capacity { return attendeeCount >= capacity } else { return false }
    }

    /// Formatted date (e.g. "12 mar, 18:30") – used directly in UI.
    var formattedDate: String {
        Self.dateFormatter.string(from: date)
    }

    // MARK: Private
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    // MARK: Init
    init(id: UUID = UUID(),
         parkID: UUID,
         title: String,
         date: Date,
         attendeeCount: Int = 0,
         capacity: Int? = nil) {
        self.id = id
        self.parkID = parkID
        self.title = title
        self.date = date
        self.attendeeCount = attendeeCount
        self.capacity = capacity
    }
}

// MARK: - Mock Data
extension ParkEvent {
    /// Quick access to a handful of upcoming events for previews.
    static var mock: [ParkEvent] {
        guard let firstPark = Park.mock.first else { return [] }
        let now = Date()
        return [
            ParkEvent(
                parkID: firstPark.id,
                title: "Poranny trening siłowy",
                date: Calendar.current.date(byAdding: .day, value: 2, to: now) ?? now,
                attendeeCount: 8,
                capacity: 15
            ),
            ParkEvent(
                parkID: firstPark.id,
                title: "Mobility & Stretching",
                date: Calendar.current.date(byAdding: .day, value: 5, to: now) ?? now,
                attendeeCount: 3,
                capacity: 10
            )
        ]
    }

    /// Filtered events matching a particular park.
    static func events(for parkID: UUID) -> [ParkEvent] {
        mock.filter { $0.parkID == parkID }
    }
} 