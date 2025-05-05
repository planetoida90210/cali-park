import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Siłownie Tab – Parks Feature
            NavigationStack {
                ParksView()
            }
                .tabItem {
                    Label("Siłownie", systemImage: "mappin.and.ellipse")
                }
                .tag(1)
            
            // Exercise Library Tab
            ExerciseLibraryView()
                .tabItem {
                    Label("Ćwiczenia", systemImage: "dumbbell.fill")
                }
                .tag(2)
            
            // Community Tab
            CommunityView()
                .tabItem {
                    Label("Społeczność", systemImage: "person.3.fill")
                }
                .tag(3)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
                .tag(4)
        }
        .accentColor(Color.accent)
        .onAppear {
            // Set tab bar appearance for iOS 15+
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor(Color.componentBackground)
            
            // Set the bar items colors
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
            
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.accent)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(Color.accent)]
            
            // Apply the appearance
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
        .background(Color.appBackground)
    }
}

// Placeholder Views dla zakładek innych niż Home
struct GymCatalogView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Znajdź siłownie kalisteniki w pobliżu")
                        .font(.title3)
                        .foregroundColor(.textPrimary)
                    
                    // Map placeholder
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.componentBackground)
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "map.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.accent)
                        )
                    
                    // List of gyms placeholder
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.componentBackground)
                            .frame(height: 100)
                            .overlay(
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.accent)
                                    
                                    Text("Siłownia plenerowa \(index + 1)")
                                        .foregroundColor(.textPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.accent)
                                }
                                .padding()
                            )
                    }
                }
                .padding()
            }
            .background(Color.appBackground.edgesIgnoringSafeArea(.all))
            .navigationTitle("Katalog siłowni")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ExerciseLibraryView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Categories
                    Text("Kategorie ćwiczeń")
                        .font(.title3)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        ForEach(["Podstawowe", "Zaawansowane", "Ekspert"], id: \.self) { category in
                            Text(category)
                                .font(.bodyMedium)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.componentBackground)
                                .foregroundColor(.accent)
                                .cornerRadius(20)
                        }
                    }
                    
                    // Exercise list
                    ForEach(["Podciągnięcia", "Pompki", "Dipy", "Flagi", "Muscle-up"], id: \.self) { exercise in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.componentBackground)
                            .frame(height: 100)
                            .overlay(
                                HStack {
                                    Image(systemName: "figure.gymnastics")
                                        .font(.system(size: 30))
                                        .foregroundColor(.accent)
                                    
                                    VStack(alignment: .leading) {
                                        Text(exercise)
                                            .font(.bodyLarge)
                                            .foregroundColor(.textPrimary)
                                        
                                        Text("Grupa mięśniowa: Przykładowa")
                                            .font(.bodySmall)
                                            .foregroundColor(.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.accent)
                                }
                                .padding()
                            )
                    }
                }
                .padding()
            }
            .background(Color.appBackground.edgesIgnoringSafeArea(.all))
            .navigationTitle("Biblioteka ćwiczeń")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CommunityView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Aktywność społeczności")
                        .font(.title3)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Community posts
                    ForEach(0..<4) { index in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Circle()
                                    .fill(Color.componentBackground)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.accent)
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text("Użytkownik \(index + 1)")
                                        .font(.bodyLarge)
                                        .foregroundColor(.textPrimary)
                                    
                                    Text("2 godziny temu")
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Text("To jest przykładowy post użytkownika w społeczności CaliPark. Użytkownicy mogą dzielić się swoimi treningami i osiągnięciami.")
                                .font(.bodyMedium)
                                .foregroundColor(.textPrimary)
                            
                            // Actions
                            HStack {
                                HStack {
                                    Image(systemName: "heart")
                                        .foregroundColor(.accent)
                                    Text("24")
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Spacer()
                                
                                HStack {
                                    Image(systemName: "bubble.right")
                                        .foregroundColor(.accent)
                                    Text("8")
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Spacer()
                                
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.accent)
                                    Text("Udostępnij")
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(Color.componentBackground)
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
            .background(Color.appBackground.edgesIgnoringSafeArea(.all))
            .navigationTitle("Społeczność")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    VStack {
                        Circle()
                            .fill(Color.componentBackground)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.accent)
                            )
                        
                        Text("Użytkownik CaliPark")
                            .font(.title2)
                            .foregroundColor(.textPrimary)
                        
                        Text("Poziom zaawansowania: Średni")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Stats
                    HStack(spacing: 20) {
                        ForEach(["Treningi", "Znajomi", "Osiągnięcia"], id: \.self) { stat in
                            VStack {
                                Text("24")
                                    .font(.title2)
                                    .foregroundColor(.accent)
                                
                                Text(stat)
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.componentBackground)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Menu options
                    VStack(spacing: 0) {
                        ForEach(["Edytuj profil", "Moje treningi", "Historia", "Ustawienia", "Pomoc", "Wyloguj"], id: \.self) { option in
                            HStack {
                                Text(option)
                                    .font(.bodyLarge)
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.accent)
                            }
                            .padding()
                            .background(Color.componentBackground)
                            
                            if option != "Wyloguj" {
                                Divider()
                                    .background(Color.textSecondary.opacity(0.3))
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .cornerRadius(16)
                }
                .padding()
            }
            .background(Color.appBackground.edgesIgnoringSafeArea(.all))
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .preferredColorScheme(.dark)
    }
} 