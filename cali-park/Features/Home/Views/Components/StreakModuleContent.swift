import SwiftUI

// MARK: - Streak Module

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

#Preview {
    StreakModuleContent()
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 