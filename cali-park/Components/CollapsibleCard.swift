import SwiftUI

struct CollapsibleCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    @State private var isExpanded: Bool = false
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header z tytułem i ikoną rozwijania
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    // Ikona tematyczna
                    Image(systemName: icon)
                        .foregroundColor(.accent)
                        .font(.title3)
                    
                    Text(title)
                        .font(.title3)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    // Ikona rozwijania
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.textSecondary)
                        .font(.bodyMedium)
                        .rotationEffect(isExpanded ? .zero : .degrees(0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.componentBackground)
                .cornerRadius(isExpanded ? 16 : 12)
            }
            
            // Zawartość karty
            if isExpanded {
                content
                    .padding(.top, 8)
            }
        }
        .background(Color.appBackground)
    }
}

#Preview {
    VStack(spacing: 16) {
        CollapsibleCard(title: "Przykładowa karta", icon: "map") {
            VStack {
                Text("Zawartość karty")
                    .foregroundColor(.textPrimary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.componentBackground)
            }
        }
        
        CollapsibleCard(title: "Inna karta", icon: "person.3") {
            Text("Inna zawartość")
                .foregroundColor(.textPrimary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.componentBackground)
        }
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
} 