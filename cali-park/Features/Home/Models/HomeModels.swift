import Foundation
import SwiftUI

// Model danych dla użytkownika
struct UserProfile {
    var name: String
    var weeklyPullUps: Int
    var weeklyProgress: Double // 0.0 - 1.0
}

// Model dla wyzwania dnia
struct DailyChallenge {
    var title: String
    var description: String
    var completed: Bool
    var resetTime: Date
}

// Model dla parków kalisteniki
struct CalisthenicsSpot {
    var id: UUID = UUID()
    var name: String
    var distance: Double // w km
    var latitude: Double
    var longitude: Double
    var difficultyLevel: DifficultyLevel
    var facilities: [Facility]
    
    enum DifficultyLevel: String, CaseIterable {
        case beginner = "Dla początkujących"
        case intermediate = "Średni poziom"
        case advanced = "Zaawansowany"
    }
    
    enum Facility: String, CaseIterable {
        case pullUpBars = "Drążki"
        case parallelBars = "Poręcze"
        case monkey = "Małpi gaj"
        case horizontalLadder = "Drabinka pozioma"
        case rings = "Kółka gimnastyczne"
    }
}

// Model dla postów społeczności
struct CommunityPost {
    var id: UUID = UUID()
    var author: String
    var authorAvatar: String // URL do avatara
    var content: String
    var image: String? // URL do zdjęcia
    var likes: Int
    var comments: Int
    var timeAgo: String
}

// Model dla osiągnięć
struct Achievement {
    var id: UUID = UUID()
    var title: String
    var description: String
    var progress: Double // 0.0 - 1.0
    var currentValue: Int
    var targetValue: Int
    var iconName: String
}

// Mock dane
struct MockData {
    static let userProfile = UserProfile(
        name: "Michał",
        weeklyPullUps: 42,
        weeklyProgress: 0.7
    )
    
    static let dailyChallenge = DailyChallenge(
        title: "30 podciągnięć",
        description: "3 serie w ciągu dnia",
        completed: false,
        resetTime: Calendar.current.date(bySettingHour: 5, minute: 0, second: 0, of: Date()) ?? Date()
    )
    
    static let nearbySpots = [
        CalisthenicsSpot(
            name: "Park Kalisteniki Powiśle",
            distance: 0.8,
            latitude: 52.2373,
            longitude: 21.0252,
            difficultyLevel: .intermediate,
            facilities: [.pullUpBars, .parallelBars, .monkey]
        ),
        CalisthenicsSpot(
            name: "Street Workout Park Mokotów",
            distance: 1.2,
            latitude: 52.1985,
            longitude: 21.0107,
            difficultyLevel: .advanced,
            facilities: [.pullUpBars, .parallelBars, .rings, .horizontalLadder]
        ),
        CalisthenicsSpot(
            name: "Siłownia plenerowa Ursynów",
            distance: 2.5,
            latitude: 52.1574,
            longitude: 21.0059,
            difficultyLevel: .beginner,
            facilities: [.pullUpBars, .parallelBars]
        )
    ]
    
    static let communityHighlight = CommunityPost(
        author: "Adam Nowak",
        authorAvatar: "person.circle.fill",
        content: "Dzisiaj pierwszy muscle-up! Miesiące treningu w końcu się opłaciły 💪",
        image: "muscle-up",
        likes: 27,
        comments: 8,
        timeAgo: "2 godziny temu"
    )
    
    static let currentAchievement = Achievement(
        title: "Mistrz podciągnięć",
        description: "Wykonaj 100 podciągnięć w ciągu tygodnia",
        progress: 0.82,
        currentValue: 82,
        targetValue: 100,
        iconName: "figure.gymnastics"
    )
} 