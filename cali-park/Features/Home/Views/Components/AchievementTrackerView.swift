import SwiftUI

struct AchievementTrackerView: View {
    var achievement: Achievement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Ikona odznaki
                ZStack {
                    Circle()
                        .fill(Color.componentBackground)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: achievement.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.title)
                        .font(.bodyLarge)
                        .foregroundColor(.textPrimary)
                    
                    Text(achievement.description)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
            }
            
            VStack(spacing: 6) {
                // Pasek postępu
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Tło paska
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.componentBackground)
                            .frame(height: 8)
                        
                        // Wypełnienie paska
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accent)
                            .frame(width: geometry.size.width * achievement.progress, height: 8)
                    }
                }
                .frame(height: 8)
                
                // Licznik postępu
                HStack {
                    Text("\(achievement.currentValue)/\(achievement.targetValue)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    Text("Jeszcze \(achievement.targetValue - achievement.currentValue) powtórzeń")
                        .font(.caption)
                        .foregroundColor(.accent)
                }
            }
            
            // CTA - przycisk
            Button(action: {
                // Akcja treningu
            }) {
                HStack {
                    Text("Zacznij trening")
                        .font(.bodyMedium)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image(systemName: "play.fill")
                        .foregroundColor(.black)
                }
                .padding()
                .background(Color.accent)
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.componentBackground)
        .cornerRadius(16)
    }
}

#Preview {
    AchievementTrackerView(achievement: MockData.currentAchievement)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 