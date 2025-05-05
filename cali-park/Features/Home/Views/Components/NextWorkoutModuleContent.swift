import SwiftUI

// MARK: - Next Workout Module

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

#Preview {
    NextWorkoutModuleContent()
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 