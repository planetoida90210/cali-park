import SwiftUI

struct PrimaryActionRailView: View {
    // Impact feedback generator
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        HStack(spacing: 8) {
            // Start Training Button
            actionButton(
                iconName: "play.fill",
                title: "Start treningu",
                action: { 
                    impactFeedback.impactOccurred()
                    // Start training action
                }
            )
            
            // Quick Log Button
            actionButton(
                iconName: "plus",
                title: "Quick Log",
                action: { 
                    impactFeedback.impactOccurred()
                    // Quick log action
                }
            )
            
            // Next Workout Button
            actionButton(
                iconName: "calendar",
                title: "Nast. trening",
                action: { 
                    impactFeedback.impactOccurred()
                    // Next workout action
                }
            )
        }
        .padding(.horizontal, 16)
    }
    
    private func actionButton(iconName: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.bodySmall)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.componentBackground)
            .foregroundColor(.accent)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accent.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct PrimaryActionRailView_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryActionRailView()
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.appBackground)
            .preferredColorScheme(.dark)
    }
} 