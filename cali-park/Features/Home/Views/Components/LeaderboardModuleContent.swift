import SwiftUI

// MARK: - Leaderboard Module

struct LeaderboardModuleContent: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Ranking znajomych")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                Text("Ten tydzień")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
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
                    .foregroundStyle(Color.accent)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
    }
    
    private func leaderboardRow(rank: Int, name: String, points: Int, isCurrentUser: Bool) -> some View {
        HStack {
            Text("\(rank)")
                .font(.system(.body, design: .rounded).bold())
                .foregroundStyle(rank <= 3 ? Color.accent : Color.textSecondary)
                .frame(width: 24)
            
            Circle()
                .fill(isCurrentUser ? Color.accent.opacity(0.3) : Color.componentBackground)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.footnote.bold())
                        .foregroundStyle(isCurrentUser ? Color.accent : Color.textSecondary)
                )
            
            Text(name)
                .font(.bodyMedium)
                .foregroundStyle(isCurrentUser ? Color.accent : Color.textPrimary)
            
            Spacer()
            
            Text("\(points) p")
                .font(.bodyMedium.bold())
                .foregroundStyle(isCurrentUser ? Color.accent : Color.textPrimary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isCurrentUser ? Color.accent.opacity(0.1) : Color.clear)
        .clipShape(.rect(cornerRadius: 8))
    }
}

#Preview {
    LeaderboardModuleContent()
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 