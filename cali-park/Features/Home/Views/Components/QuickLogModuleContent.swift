import SwiftUI

// MARK: - Quick Log Module (moved from Components/ModuleView)

struct QuickLogModuleContent: View {
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        VStack(spacing: 12) {
            // Przycisk "Dodaj serię"
            Button(action: {
                impactFeedback.impactOccurred()
                // Akcja dodawania serii
            }) {
                HStack {
                    Image(systemName: "plus")
                        .foregroundColor(.black)
                    
                    Text("Dodaj serię")
                        .font(.buttonMedium)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accent)
                .cornerRadius(8)
            }
            
            // Ostatni zapis
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ostatni zapis")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                    
                    Text("10 podciągnięć • Wczoraj, 18:30")
                        .font(.bodyLarge)
                        .foregroundColor(.textPrimary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.glassBackground)
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Color.glassBackground.blur(radius: 30))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    QuickLogModuleContent()
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 