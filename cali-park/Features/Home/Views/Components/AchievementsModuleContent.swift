import SwiftUI

// MARK: - Achievements Module

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

#Preview {
    AchievementsModuleContent()
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 