import SwiftUI

struct QuickActionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Szybkie akcje")
                .font(.title3)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                // Zapisz trening
                QuickActionButton(
                    icon: "plus",
                    title: "Zapisz trening",
                    action: {
                        // Akcja zapisywania treningu
                    }
                )
                
                // Znajdź park
                QuickActionButton(
                    icon: "mappin.and.ellipse",
                    title: "Znajdź park",
                    action: {
                        // Akcja znajdowania parku
                    }
                )
                
                // Dodaj post
                QuickActionButton(
                    icon: "camera",
                    title: "Dodaj post",
                    action: {
                        // Akcja dodawania posta
                    }
                )
            }
        }
    }
}

struct QuickActionButton: View {
    var icon: String
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.accent)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.componentBackground)
            .cornerRadius(12)
        }
    }
}

#Preview {
    QuickActionsView()
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 