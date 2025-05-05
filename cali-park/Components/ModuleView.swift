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
                        
                        Text("22°C")
                            .font(.title3.bold())
                            .foregroundColor(.textPrimary)
                    }
                }
                
                Spacer()
                
                // Najbliższe parki
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Najbliższy park")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    
                    Text("Park Skaryszewski (1,2 km)")
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                }
            }
            
            // Lista pobliskich parków
            VStack(spacing: 12) {
                parkRow(name: "Park Skaryszewski", distance: "1,2 km", busy: "Średnio zatłoczony")
                parkRow(name: "Park Praski", distance: "2,5 km", busy: "Mało zatłoczony")
            }
            
            Button(action: {
                // Akcja otworzenia mapy
            }) {
                Text("Pokaż na mapie")
                    .font(.buttonMedium)
                    .foregroundColor(.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.glassBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accent, lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(Color.componentBackground)
        .cornerRadius(12)
    }
    
    private func parkRow(name: String, distance: String, busy: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.bodyMedium)
                    .foregroundColor(.textPrimary)
                
                Text(busy)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Text(distance)
                .font(.bodyMedium)
                .foregroundColor(.accent)
        }
        .padding(.vertical, 4)
    }
}

struct StreakModuleContent: View {
    var body: some View {
        VStack(spacing: 16) {
            // Aktualny streak
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("14 dni")
                        .font(.title3.bold())
                        .foregroundColor(.textPrimary)
                    
                    Text("aktualny streak")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Rekord: 21 dni")
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                    
                    Text("Zbliżasz się!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // Kalendarz
            VStack(spacing: 8) {
                Text("Lipiec 2023")
                    .font(.footnote)
                    .foregroundColor(.textSecondary)
                
                // Calendar grid - just a placeholder
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                    ForEach(1..<32, id: \.self) { day in
                        ZStack {
                            Circle()
                                .fill(day % 3 == 0 ? Color.accent.opacity(0.3) : Color.clear)
                                .frame(width: 28, height: 28)
                            
                            Text("\(day)")
                                .font(.caption)
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.componentBackground)
        .cornerRadius(12)
    }
}

struct LeaderboardModuleContent: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Ranking znajomych")
                    .font(.bodyLarge)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("Ten tydzień")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            VStack(spacing: 10) {
                leaderboardRow(rank: 1, name: "Maciek S.", points: 240, isCurrentUser: false)
                leaderboardRow(rank: 2, name: "Michał D.", points: 180, isCurrentUser: true)
                leaderboardRow(rank: 3, name: "Kuba W.", points: 120, isCurrentUser: false)
            }
            
            Button(action: {
                // Akcja pokazania pełnego rankingu
            }) {
                Text("Zobacz pełny ranking")
                    .font(.footnote)
                    .foregroundColor(.accent)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.componentBackground)
        .cornerRadius(12)
    }
    
    private func leaderboardRow(rank: Int, name: String, points: Int, isCurrentUser: Bool) -> some View {
        HStack {
            Text("\(rank)")
                .font(.system(.body, design: .rounded).bold())
                .foregroundColor(rank <= 3 ? .accent : .textSecondary)
                .frame(width: 24)
            
            Circle()
                .fill(isCurrentUser ? Color.accent.opacity(0.3) : Color.componentBackground)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.footnote.bold())
                        .foregroundColor(isCurrentUser ? .accent : .textSecondary)
                )
            
            Text(name)
                .font(.bodyMedium)
                .foregroundColor(isCurrentUser ? .accent : .textPrimary)
            
            Spacer()
            
            Text("\(points) p")
                .font(.bodyMedium.bold())
                .foregroundColor(isCurrentUser ? .accent : .textPrimary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isCurrentUser ? Color.accent.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

struct FeedModuleContent: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Aktywność znajomych")
                    .font(.bodyLarge)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                feedItem(
                    avatar: "M",
                    name: "Maciek S.",
                    action: "zaliczył nowy rekord: 15 podciągnięć",
                    time: "1 godz. temu"
                )
                
                feedItem(
                    avatar: "K",
                    name: "Kuba W.",
                    action: "ukończył trening Pull",
                    time: "3 godz. temu"
                )
            }
        }
        .padding()
        .background(Color.componentBackground)
        .cornerRadius(12)
    }
    
    private func feedItem(avatar: String, name: String, action: String, time: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.accent.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(avatar)
                            .font(.footnote.bold())
                            .foregroundColor(.accent)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.bodyMedium.bold())
                        .foregroundColor(.textPrimary)
                    
                    Text(action)
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            
            Divider()
                .background(Color.divider)
        }
    }
}

struct AchievementsModuleContent: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Osiągnięcia")
                    .font(.bodyLarge)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("12/30")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            // Ostatnio zdobyte
            VStack(alignment: .leading, spacing: 8) {
                Text("Ostatnio zdobyte")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                HStack(spacing: 12) {
                    achievementBadge(icon: "star.fill", color: .orange)
                    achievementBadge(icon: "flame.fill", color: .red)
                    achievementBadge(icon: "bolt.fill", color: .yellow)
                }
            }
            
            // Następne do zdobycia
            VStack(alignment: .leading, spacing: 8) {
                Text("Blisko zdobycia")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                HStack {
                    Circle()
                        .stroke(Color.accent, lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .overlay(
                            VStack {
                                Image(systemName: "figure.gymnastics")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                
                                Text("80%")
                                    .font(.caption2)
                                    .foregroundColor(.textSecondary)
                            }
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mistrz Kalisteniki")
                            .font(.bodyMedium)
                            .foregroundColor(.textPrimary)
                        
                        Text("Wykonaj 100 treningów")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(8)
                .background(Color.glassBackground)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.componentBackground)
        .cornerRadius(12)
    }
    
    private func achievementBadge(icon: String, color: Color) -> some View {
        Circle()
            .fill(color.opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: icon)
                    .foregroundColor(color)
            )
    }
}

// MARK: - Preview

struct ModuleView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.appBackground.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 0) {
                    ModuleView(moduleId: "log")
                    ModuleView(moduleId: "next")
                    ModuleView(moduleId: "parks")
                }
            }
        }
        .preferredColorScheme(.dark)
        .environmentObject(ModulePreferences())
    }
} 