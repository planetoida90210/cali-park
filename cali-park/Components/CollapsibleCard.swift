import SwiftUI

struct CollapsibleCard<Content: View>: View {
    let id: String
    let title: String
    let icon: String
    let content: Content
    @State private var isExpanded: Bool = false
    @Binding var scrollTarget: String?
    
    init(id: String, title: String, icon: String, scrollTarget: Binding<String?>, @ViewBuilder content: () -> Content) {
        self.id = id
        self.title = title
        self.icon = icon
        self.content = content()
        self._scrollTarget = scrollTarget
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header z tytułem i ikoną rozwijania
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                    
                    // Jeśli karta została rozwinięta, ustaw cel przewijania
                    if isExpanded {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scrollTarget = id
                        }
                    }
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
        .id(id)
        .background(Color.appBackground)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var scrollTarget: String? = nil
        
        var body: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        CollapsibleCard(id: "karta1", title: "Przykładowa karta", icon: "map", scrollTarget: $scrollTarget) {
                            VStack {
                                Text("Zawartość karty")
                                    .foregroundColor(.textPrimary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.componentBackground)
                            }
                        }
                        
                        CollapsibleCard(id: "karta2", title: "Inna karta", icon: "person.3", scrollTarget: $scrollTarget) {
                            Text("Inna zawartość")
                                .foregroundColor(.textPrimary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.componentBackground)
                        }
                    }
                    .padding()
                }
                .onChange(of: scrollTarget) { target in
                    if let target = target {
                        withAnimation {
                            proxy.scrollTo(target, anchor: .center)
                        }
                    }
                }
            }
            .background(Color.appBackground)
            .preferredColorScheme(.dark)
        }
    }
    
    return PreviewWrapper()
} 