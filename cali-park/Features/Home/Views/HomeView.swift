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
                    
                    // Hero + Progress (moduł 1)
                    HeroProgressView(userProfile: userProfile)
                    
                    // Wyzwanie dnia (moduł 2)
                    DailyChallengeView(challenge: dailyChallenge)
                    
                    // Szybkie akcje - CTA
                    QuickActionsView()
                    
                    // Mini-mapa (zwijana)
                    CollapsibleCard(title: "Najbliższe parki", icon: "map.fill") {
                        MiniMapView(nearbySpots: nearbySpots)
                            .padding(.bottom, 8)
                    }
                    
                    // Community highlight (zwijana)
                    CollapsibleCard(title: "Aktywność społeczności", icon: "person.3.fill") {
                        CommunityHighlightView(post: communityHighlight)
                            .padding(.bottom, 8)
                    }
                    
                    // Tracker osiągnięć (zwijany)
                    CollapsibleCard(title: "Twoje osiągnięcia", icon: "trophy.fill") {
                        AchievementTrackerView(achievement: currentAchievement)
                            .padding(.bottom, 8)
                    }
                    
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