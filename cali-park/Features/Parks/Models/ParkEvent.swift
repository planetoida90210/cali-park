import Foundation

// MARK: - ParkEvent Model
/// Enhanced event model ready for backend integration while keeping backward-compat fields for existing UI.
struct ParkEvent: Identifiable, Codable, Equatable, Hashable {
    // MARK: Stored properties
    let id: UUID
    let parkID: UUID
    var title: String

    // Dates
    var date: Date                // start date (legacy name – keep for now)
    var endDate: Date?            // optional end date
    var location: String?

    // Capacity & attendance
    var attendeeCount: Int        // current sign-ups
    var capacity: Int?

    // Participants preview (first few avatars)
    var participants: [User]

    // RSVP state for current user
    var isAttending: Bool
    var calendarEventIdentifier: String?

    // Metadata
    var lastUpdated: Date

    // MARK: Computed helpers
    var isFull: Bool {
        if let capacity { attendeeCount >= capacity } else { false }
    }

    var formattedDate: String {
        Self.dateFormatter.string(from: date)
    }

    // Aliases for upcoming refactor
    var startDate: Date { date }
    var attendeesCount: Int { attendeeCount }

    // MARK: Init
    init(id: UUID = UUID(),
         parkID: UUID,
         title: String,
         date: Date,
         endDate: Date? = nil,
         location: String? = nil,
         attendeeCount: Int = 0,
         capacity: Int? = nil,
         participants: [User] = [],
         isAttending: Bool = false,
         calendarEventIdentifier: String? = nil,
         lastUpdated: Date = Date()) {
        self.id = id
        self.parkID = parkID
        self.title = title
        self.date = date
        self.endDate = endDate
        self.location = location
        self.attendeeCount = attendeeCount
        self.capacity = capacity
        self.participants = participants
        self.isAttending = isAttending
        self.calendarEventIdentifier = calendarEventIdentifier
        self.lastUpdated = lastUpdated
    }

    // MARK: Private
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
}

// MARK: - Mock Data
extension ParkEvent {
    /// Example stub events used by previews & initial data loads.
    static var mock: [ParkEvent] {
        guard let firstPark = Park.mock.first else { return [] }
        let now = Date()
        return [
            ParkEvent(
                parkID: firstPark.id,
                title: "Poranny trening siłowy",
                date: Calendar.current.date(byAdding: .day, value: 2, to: now) ?? now,
                attendeeCount: 8,
                capacity: 15,
                participants: [.mock, .mock]
            ),
            ParkEvent(
                parkID: firstPark.id,
                title: "Mobility & Stretching",
                date: Calendar.current.date(byAdding: .day, value: 5, to: now) ?? now,
                attendeeCount: 3,
                capacity: 10,
                participants: [.mock]
            )
        ]
    }

    /// Returns events matching concrete park id.
    static func events(for parkID: UUID) -> [ParkEvent] {
        mock.filter { $0.parkID == parkID }
    }
} 