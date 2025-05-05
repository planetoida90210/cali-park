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
    
    // Czy pokazać własny uchwyt (hamburger); przy przestawianiu w List chcemy go ukryć
    var showGrabber: Bool = true
    // Callback dla rodzica – powiadamia o kliknięciu (np. aby przewinąć widok)
    var onToggle: ((String) -> Void)? = nil
    
    var body: some View {
        if let module = module {
            VStack(spacing: 0) {
                // Nagłówek modułu
                Button(action: {
                    if editMode?.wrappedValue.isEditing != true {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                            impactFeedback.impactOccurred()
                            // Powiadom o zmianie (przewinięcie do widoku)
                            onToggle?(moduleId)
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
                            if editMode?.wrappedValue.isEditing == true && showGrabber {
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