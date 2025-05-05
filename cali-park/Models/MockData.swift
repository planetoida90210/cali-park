import Foundation

// Mock data for development and previews
enum MockDataProvider {
    static let userProfile = MockUserProfile(
        id: "user1",
        name: "Michał",
        weeklyPullUps: 57,
        weeklyGoal: 75,
        weeklyProgress: 0.76,
        level: 12
    )
    
    static let dailyChallenge = MockDailyChallenge(
        id: "challenge1",
        title: "30 podciągnięć w 3 seriach",
        description: "Wykonaj 30 podciągnięć nachwytów w maksymalnie 3 seriach.",
        completed: false,
        reward: "100 XP"
    )
}

// Mock models - renamed to avoid conflicts
struct MockUserProfile {
    let id: String
    let name: String
    let weeklyPullUps: Int
    let weeklyGoal: Int
    let weeklyProgress: Double
    let level: Int
}

struct MockDailyChallenge {
    let id: String
    let title: String
    let description: String
    let completed: Bool
    let reward: String
} 