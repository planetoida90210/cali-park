import SwiftUI

struct FixedHeaderView: View {
    var userProfile: MockUserProfile
    var dailyChallenge: MockDailyChallenge
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Ring + Przywitanie
            VStack(spacing: 8) {
                // Przywitanie + Progress Ring
                HStack(alignment: .top) {
                    // Przywitanie
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Siema, \(userProfile.name)!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Text("\(userProfile.weeklyPullUps) podciągnięć w tym tygodniu")
                            .font(.bodyLarge)
                            .foregroundColor(.accent)
                    }
                    
                    Spacer()
                    
                    // Progress Ring
                    ZStack {
                        // Tło pierścienia
                        Circle()
                            .stroke(lineWidth: 8)
                            .opacity(0.3)
                            .foregroundColor(.componentBackground)
                        
                        // Wypełnienie pierścienia
                        Circle()
                            .trim(from: 0.0, to: CGFloat(userProfile.weeklyProgress))
                            .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                            .foregroundColor(.accent)
                            .rotationEffect(Angle(degrees: 270.0))
                        
                        // Procent
                        Text("\(Int(userProfile.weeklyProgress * 100))%")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.accent)
                    }
                    .frame(width: 60, height: 60)
                }
                
                // Przycisk "Start treningu"
                Button(action: {
                    // Akcja rozpoczęcia treningu
                }) {
                    HStack {
                        Text("Start treningu")
                            .font(.buttonLarge)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "play.fill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accent)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
            }
            
            // Mini wersja Daily Challenge
            HStack {
                // Ikona i tytuł
                Image(systemName: "flame.fill")
                    .foregroundColor(.accent)
                    .font(.title3)
                
                VStack(alignment: .leading) {
                    Text("Wyzwanie dnia")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                    
                    Text(dailyChallenge.title)
                        .font(.bodyLarge)
                        .foregroundColor(.textPrimary)
                }
                
                Spacer()
                
                // Przycisk zaliczenia
                Button(action: {
                    // Akcja zaliczenia wyzwania
                }) {
                    Text(dailyChallenge.completed ? "Zaliczone ✓" : "Zalicz")
                        .font(.bodyMedium)
                        .foregroundColor(dailyChallenge.completed ? .textSecondary : .black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(dailyChallenge.completed ? Color.componentBackground : Color.accent)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(dailyChallenge.completed ? Color.accent.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                }
                .disabled(dailyChallenge.completed)
            }
            .padding(16)
            .background(Color.componentBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct FixedHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        FixedHeaderView(
            userProfile: MockDataProvider.userProfile,
            dailyChallenge: MockDataProvider.dailyChallenge
        )
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
    }
} 