import SwiftUI

struct MainTabView: View {
    let environment: AppEnvironment
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                HomeView(environment: environment)
            }

            Tab("Siłownie", systemImage: "mappin.and.ellipse", value: 1) {
                NavigationStack {
                    ParksView(environment: environment)
                }
            }

            Tab("Ćwiczenia", systemImage: "dumbbell.fill", value: 2) {
                ExerciseLibraryView(environment: environment)
            }

            Tab("Skille", systemImage: "trophy.fill", value: 3) {
                SkillPathsView(environment: environment)
            }

            Tab("Profil", systemImage: "person.fill", value: 4) {
                ProfileView()
            }
        }
        .tint(Color.accent)
    }
}

// MARK: - Preview
#Preview {
    MainTabView(environment: .preview)
        .preferredColorScheme(.dark)
}
