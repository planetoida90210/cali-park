import SwiftUI

struct HomeScreenView: View {
    @State private var userProfile: UserProfile = MockData.userProfile
    @State private var dailyChallenge: DailyChallenge = MockData.dailyChallenge
    @State private var nearbySpots: [CalisthenicsSpot] = MockData.nearbySpots
    @State private var communityHighlight: CommunityPost = MockData.communityHighlight
    @State private var currentAchievement: Achievement = MockData.currentAchievement
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Górny padding
                    Spacer()
                        .frame(height: 10)
                    
                    // Hero + Progress
                    HeroProgressView(userProfile: userProfile)
                    
                    // Wyzwanie dnia
                    DailyChallengeView(challenge: dailyChallenge)
                    
                    // Szybkie akcje
                    QuickActionsView()
                    
                    // Mini-mapa
                    MiniMapView(nearbySpots: nearbySpots)
                    
                    // Community highlight
                    CommunityHighlightView(post: communityHighlight)
                    
                    // Tracker osiągnięć
                    AchievementTrackerView(achievement: currentAchievement)
                    
                    // Dolny padding
                    Spacer()
                        .frame(height: 30)
                }
                .padding(.horizontal)
            }
            .background(Color.appBackground.edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Akcja powiadomień
                    }) {
                        Image(systemName: "bell")
                            .font(.title3)
                            .foregroundColor(.textPrimary)
                    }
                }
            }
        }
    }
}

// Aliasowanie HomeScreenView jako HomeView dla zgodności z poprzednim nazwewnictwem
typealias HomeView = HomeScreenView

// Preview
struct HomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreenView()
            .preferredColorScheme(.dark)
    }
} 