import SwiftUI

struct MainTabView: View {
    let environment: AppEnvironment
    @State private var router = TabRouter()

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selection) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                HomeView(environment: environment)
            }

            Tab("Siłownie", systemImage: "mappin.and.ellipse", value: AppTab.parks) {
                NavigationStack {
                    ParksView(environment: environment)
                }
            }

            Tab("Ćwiczenia", systemImage: "dumbbell.fill", value: AppTab.exercises) {
                ExerciseLibraryView(environment: environment)
            }

            Tab("Skille", systemImage: "trophy.fill", value: AppTab.skills) {
                SkillPathsView(environment: environment)
            }

            Tab("Profil", systemImage: "person.fill", value: AppTab.profile) {
                ProfileView()
            }
        }
        .tint(Color.accent)
        // Lets deep views (the Home achievements module) switch tabs.
        .environment(router)
    }
}

// MARK: - Preview
#Preview {
    MainTabView(environment: .preview)
        .preferredColorScheme(.dark)
}
