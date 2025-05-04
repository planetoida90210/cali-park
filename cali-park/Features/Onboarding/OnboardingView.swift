import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    @State private var currentPage = 0
    @State private var fitnessLevel = 1
    @State private var selectedGoals: [String] = []
    @State private var locationPermission = false
    
    private let goals = [
        "Zwiększenie siły", 
        "Budowa masy mięśniowej", 
        "Poprawa wytrzymałości", 
        "Redukcja tkanki tłuszczowej", 
        "Nauka nowych umiejętności",
        "Przygotowanie do zawodów"
    ]
    
    var body: some View {
        ZStack {
            Color.appBackground.edgesIgnoringSafeArea(.all)
            
            VStack {
                TabView(selection: $currentPage) {
                    // Welcome page
                    welcomeView
                        .tag(0)
                    
                    // Fitness level page
                    fitnessLevelView
                        .tag(1)
                    
                    // Goals page
                    goalsView
                        .tag(2)
                    
                    // Location permissions page
                    locationPermissionView
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Progress and navigation
                VStack {
                    // Page indicators
                    HStack {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(currentPage == index ? Color.accent : Color.gray.opacity(0.3))
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Navigation buttons
                    HStack {
                        if currentPage > 0 {
                            Button("Wróć") {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        
                        Spacer()
                        
                        Button(currentPage == 3 ? "Rozpocznij" : "Dalej") {
                            if currentPage < 3 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                // Complete onboarding
                                hasCompletedOnboarding = true
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding()
        }
    }
    
    // MARK: - Subviews
    
    private var welcomeView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "figure.gymnastics")
                .font(.system(size: 80))
                .foregroundColor(.accent)
            
            Text("Witaj w CaliPark")
                .font(.largeTitle)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Twoja podróż po świecie kalisteniki zaczyna się tutaj! Przygotujmy wszystko, aby dopasować aplikację do Twoich potrzeb.")
                .font(.bodyLarge)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    private var fitnessLevelView: some View {
        VStack(spacing: 30) {
            Text("Jaki jest Twój poziom zaawansowania?")
                .font(.title2)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                fitnessLevelCard(level: 1, title: "Początkujący", description: "Dopiero zaczynasz przygodę z kalisteniką")
                fitnessLevelCard(level: 2, title: "Średniozaawansowany", description: "Znasz podstawowe ćwiczenia i techniki")
                fitnessLevelCard(level: 3, title: "Zaawansowany", description: "Wykonujesz zaawansowane ćwiczenia i triki")
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func fitnessLevelCard(level: Int, title: String, description: String) -> some View {
        Button(action: {
            fitnessLevel = level
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.bodyLarge)
                        .foregroundColor(.textPrimary)
                    
                    Text(description)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                if fitnessLevel == level {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accent)
                        .font(.title3)
                }
            }
            .padding()
            .background(Color.componentBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(fitnessLevel == level ? Color.accent : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private var goalsView: some View {
        VStack(spacing: 20) {
            Text("Jakie są Twoje cele treningowe?")
                .font(.title2)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Wybierz wszystkie, które Cię interesują")
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(goals, id: \.self) { goal in
                        goalRow(goal: goal)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func goalRow(goal: String) -> some View {
        let isSelected = selectedGoals.contains(goal)
        
        return Button(action: {
            if isSelected {
                selectedGoals.removeAll { $0 == goal }
            } else {
                selectedGoals.append(goal)
            }
        }) {
            HStack {
                Text(goal)
                    .font(.bodyLarge)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .accent : .gray)
                    .font(.title3)
            }
            .padding()
            .background(Color.componentBackground)
            .cornerRadius(12)
        }
    }
    
    private var locationPermissionView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accent)
            
            Text("Dostęp do lokalizacji")
                .font(.title2)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Aby znaleźć siłownie kalisteniki w pobliżu, potrzebujemy dostępu do Twojej lokalizacji. Możesz zarządzać tym później w ustawieniach.")
                .font(.bodyLarge)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            Toggle("Zezwól na dostęp do lokalizacji", isOn: $locationPermission)
                .foregroundColor(.textPrimary)
                .padding()
                .background(Color.componentBackground)
                .cornerRadius(12)
                .toggleStyle(SwitchToggleStyle(tint: Color.accent))
            
            Spacer()
        }
        .padding()
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .preferredColorScheme(.dark)
    }
} 