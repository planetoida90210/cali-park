import SwiftUI

struct ModuleView: View {
    // Identyfikator modułu
    let moduleId: String
    
    // Obsługa rozwijania/zwijania
    @State private var isExpanded: Bool = false
    
    // Tryb edycji
    @Environment(\.editMode) private var editMode
    @EnvironmentObject private var modulePreferences: ModulePreferences
    
    // Namespace for matched geometry effect
    @Namespace private var animation
    
    // Pobranie definicji modułu
    private var module: ModuleDefinition? {
        ModuleDefinition.getModule(byId: moduleId)
    }
    
    // Impact feedback generator
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        if let module = module {
            VStack(spacing: 0) {
                // Nagłówek modułu
                Button(action: {
                    if editMode?.wrappedValue.isEditing != true {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                            impactFeedback.impactOccurred()
                        }
                    }
                }) {
                    HStack {
                        // Main content
                        HStack {
                            // Ikona modułu
                            Image(systemName: module.iconName)
                                .foregroundColor(.accent)
                                .font(.title3)
                                .padding(.leading, editMode?.wrappedValue.isEditing == true ? 20 : 0) // Dodajemy padding dla ikony gdy jesteśmy w trybie edycji
                            
                            Text(module.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            // W trybie edycji - przycisk grabber
                            if editMode?.wrappedValue.isEditing == true {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.textSecondary)
                                    .font(.bodyMedium)
                            } else {
                                // Standardowo - ikona rozwijania/zwijania
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.textSecondary)
                                    .font(.bodyMedium)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .overlay(
                        // Delete button (only in edit mode)
                        Group {
                            if editMode?.wrappedValue.isEditing == true {
                                Button(action: {
                                    withAnimation {
                                        modulePreferences.toggleModule(moduleId)
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 24, height: 24)
                                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                                        
                                        Image(systemName: "minus")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .position(x: 12, y: 12)
                                .zIndex(1) // Upewniamy się, że przycisk usunięcia jest zawsze na wierzchu
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color.glassBackground.blur(radius: 30))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.cardBorderStart, Color.cardBorderEnd]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .matchedGeometryEffect(id: "moduleCard_\(moduleId)", in: animation, isSource: true)
                
                // Zawartość modułu (rozwinięta)
                if isExpanded && editMode?.wrappedValue.isEditing != true {
                    moduleContent
                        .padding(.top, 8)
                        .matchedGeometryEffect(id: "moduleContent_\(moduleId)", in: animation, isSource: false)
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 16)
            .padding(.top, editMode?.wrappedValue.isEditing == true ? 10 : 0) // Dodajemy dodatkowy padding na górze w trybie edycji
            .background(Color.appBackground)
            .editModeStyle()
        }
    }
    
    // Zawartość modułu w zależności od jego typu
    @ViewBuilder
    private var moduleContent: some View {
        switch moduleId {
        case "log":
            QuickLogModuleContent()
        case "next":
            NextWorkoutModuleContent()
        case "parks":
            ParksModuleContent()
        case "streak":
            StreakModuleContent()
        case "friends":
            LeaderboardModuleContent()
        case "feed":
            FeedModuleContent()
        case "achievements":
            AchievementsModuleContent()
        default:
            EmptyView()
        }
    }
}

// MARK: - Przykładowe implementacje zawartości modułów

struct QuickLogModuleContent: View {
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        VStack(spacing: 12) {
            // Przycisk "Dodaj serię"
            Button(action: {
                impactFeedback.impactOccurred()
                // Akcja dodawania serii
            }) {
                HStack {
                    Image(systemName: "plus")
                        .foregroundColor(.black)
                    
                    Text("Dodaj serię")
                        .font(.buttonMedium)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accent)
                .cornerRadius(8)
            }
            
            // Ostatni zapis
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ostatni zapis")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                    
                    Text("10 podciągnięć • Wczoraj, 18:30")
                        .font(.bodyLarge)
                        .foregroundColor(.textPrimary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.glassBackground)
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Color.glassBackground.blur(radius: 30))
        .cornerRadius(12)
    }
}

// Placeholder dla pozostałych modułów
struct NextWorkoutModuleContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.accent)
                
                Text("Trening Push")
                    .font(.bodyLarge)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("Dziś, 19:00")
                    .font(.bodyMedium)
                    .foregroundColor(.accent)
            }
            
            Button(action: {
                // Akcja rozpoczęcia treningu
            }) {
                Text("Rozpocznij teraz")
                    .font(.buttonMedium)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accent)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.componentBackground)
        .cornerRadius(12)
    }
}

struct ParksModuleContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Pogoda
                VStack(alignment: .leading, spacing: 4) {
                    Text("Warszawa")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.yellow)
                        
                        Text("14°C")
                            .font(.bodyLarge)
                            .foregroundColor(.textPrimary)
                    }
                }
                
                Spacer()
                
                // Najbliższy park
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Najbliższy park")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    
                    Text("200 m")
                        .font(.bodyLarge)
                        .foregroundColor(.accent)
                }
            }
            
            Divider()
                .background(Color.textSecondary.opacity(0.3))
            
            // Nazwa parku i nawigacja
            HStack {
                Text("Park Syrenki")
                    .font(.bodyLarge)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: {
                    // Akcja nawigowania
                }) {
                    Text("Nawiguj")
                        .font(.bodyMedium)
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accent)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.componentBackground)
        .cornerRadius(12)
    }
}

// Placeholder dla pozostałych modułów
struct StreakModuleContent: View {
    var body: some View {
        Text("Kalendarz streak - zawartość")
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.componentBackground)
            .cornerRadius(12)
    }
}

struct LeaderboardModuleContent: View {
    var body: some View {
        Text("Leaderboard - zawartość")
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.componentBackground)
            .cornerRadius(12)
    }
}

struct FeedModuleContent: View {
    var body: some View {
        Text("Feed - zawartość")
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.componentBackground)
            .cornerRadius(12)
    }
}

struct AchievementsModuleContent: View {
    var body: some View {
        Text("Osiągnięcia - zawartość")
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.componentBackground)
            .cornerRadius(12)
    }
}

struct ModuleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            ModuleView(moduleId: "log")
            ModuleView(moduleId: "parks")
            ModuleView(moduleId: "next")
        }
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
        .environmentObject(ModulePreferences())
    }
} 