import SwiftUI

struct MainTabView: View {
    let environment: AppEnvironment
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            NavigationStack {
                ParksView(environment: environment)
            }
            .tabItem { Label("Siłownie", systemImage: "mappin.and.ellipse") }
            .tag(1)

            ExerciseLibraryView()
                .tabItem { Label("Ćwiczenia", systemImage: "dumbbell.fill") }
                .tag(2)

            CommunityView()
                .tabItem { Label("Społeczność", systemImage: "person.3.fill") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Profil", systemImage: "person.fill") }
                .tag(4)
        }
        .tint(Color.accent)
    }
}

// MARK: - Preview
#Preview {
    MainTabView(environment: .preview)
        .preferredColorScheme(.dark)
}
