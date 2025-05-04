import SwiftUI

struct DailyChallengeView: View {
    var challenge: DailyChallenge
    @State private var completed: Bool
    
    init(challenge: DailyChallenge) {
        self.challenge = challenge
        self._completed = State(initialValue: challenge.completed)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.accent)
                    .font(.title2)
                
                Text("Wyzwanie dnia")
                    .font(.title3)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Reset time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.bodySmall)
                    
                    Text("Reset 5:00")
                        .font(.bodySmall)
                }
                .foregroundColor(.textSecondary)
            }
            
            // Challenge description
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.bodyLarge)
                        .foregroundColor(.textPrimary)
                        .bold()
                    
                    Text(challenge.description)
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Complete button
                Group {
                    Button(action: {
                        withAnimation {
                            completed.toggle()
                        }
                    }) {
                        Text(completed ? "Zaliczone ✓" : "Zaliczone")
                            .font(.buttonMedium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .disabled(completed)
                }
                .background(completed ? Color.componentBackground : Color.accent)
                .foregroundColor(completed ? Color.textSecondary : Color.black)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(completed ? Color.accent.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }
        }
        .padding()
        .background(Color.componentBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accent.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    DailyChallengeView(challenge: MockData.dailyChallenge)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 