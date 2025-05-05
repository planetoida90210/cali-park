import SwiftUI

// MARK: - Leaderboard Module

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

#Preview {
    LeaderboardModuleContent()
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 