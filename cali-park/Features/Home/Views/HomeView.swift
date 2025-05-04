import SwiftUI

struct HomeScreenView: View {
    @State private var userProfile: UserProfile = MockData.userProfile
    @State private var dailyChallenge: DailyChallenge = MockData.dailyChallenge
    @State private var nearbySpots: [CalisthenicsSpot] = MockData.nearbySpots
    @State private var communityHighlight: CommunityPost = MockData.communityHighlight
    @State private var currentAchievement: Achievement = MockData.currentAchievement
    @State private var scrollTarget: String? = nil
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
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
                        CollapsibleCard(id: "map", title: "Najbliższe parki", icon: "map.fill", scrollTarget: $scrollTarget) {
                            MiniMapView(nearbySpots: nearbySpots)
                                .padding(.bottom, 8)
                        }
                        
                        // Community highlight (zwijana)
                        CollapsibleCard(id: "community", title: "Aktywność społeczności", icon: "person.3.fill", scrollTarget: $scrollTarget) {
                            CommunityHighlightView(post: communityHighlight)
                                .padding(.bottom, 8)
                        }
                        
                        // Tracker osiągnięć (zwijany)
                        CollapsibleCard(id: "achievements", title: "Twoje osiągnięcia", icon: "trophy.fill", scrollTarget: $scrollTarget) {
                            AchievementTrackerView(achievement: currentAchievement)
                                .padding(.bottom, 8)
                        }
                        
                        // Dolny padding
                        Spacer()
                            .frame(height: 30)
                    }
                    .padding(.horizontal)
                }
                .onChange(of: scrollTarget) { target in
                    if let target = target {
                        withAnimation {
                            proxy.scrollTo(target, anchor: .top)
                        }
                    }
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