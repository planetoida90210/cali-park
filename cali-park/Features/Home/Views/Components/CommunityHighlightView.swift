import SwiftUI

struct CommunityHighlightView: View {
    var post: CommunityPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Nagłówek
            HStack {
                Text("Społeczność")
                    .font(.title3)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: {
                    // Akcja przejścia do widoku społeczności
                }) {
                    Text("Zobacz więcej")
                        .font(.bodySmall)
                        .foregroundColor(.accent)
                }
            }
            
            // Post użytkownika
            VStack(alignment: .leading, spacing: 12) {
                // Informacje o autorze
                HStack {
                    Image(systemName: post.authorAvatar)
                        .font(.title2)
                        .foregroundColor(.accent)
                        .frame(width: 40, height: 40)
                        .background(Color.componentBackground)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text(post.author)
                            .font(.bodyLarge)
                            .foregroundColor(.textPrimary)
                        
                        Text(post.timeAgo)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Akcja menu opcji
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // Treść posta
                Text(post.content)
                    .font(.bodyMedium)
                    .foregroundColor(.textPrimary)
                    .lineLimit(3)
                
                // Zdjęcie posta (opcjonalnie)
                if let image = post.image {
                    ZStack(alignment: .bottomTrailing) {
                        Rectangle()
                            .fill(Color.componentBackground)
                            .frame(height: 180)
                            .cornerRadius(10)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.accent)
                            )
                        
                        // W prawdziwej aplikacji zamiast placeholdera byłoby prawdziwe zdjęcie z AsyncImage
                        // AsyncImage(url: URL(string: image)) { ... }
                        
                        // Badge z ikoną muscle-up jeśli post o tym wspomina
                        if post.content.lowercased().contains("muscle-up") {
                            Text("Muscle-Up 💪")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.accent)
                                .cornerRadius(15)
                                .padding(10)
                        }
                    }
                }
                
                // Liczniki interakcji
                HStack(spacing: 20) {
                    Button(action: {
                        // Akcja like
                    }) {
                        HStack {
                            Image(systemName: "heart")
                                .foregroundColor(.accent)
                            
                            Text("\(post.likes)")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Button(action: {
                        // Akcja komentowania
                    }) {
                        HStack {
                            Image(systemName: "bubble.right")
                                .foregroundColor(.accent)
                            
                            Text("\(post.comments)")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Akcja udostępnienia
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.accent)
                    }
                }
            }
            .padding()
            .background(Color.componentBackground)
            .cornerRadius(16)
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    CommunityHighlightView(post: MockData.communityHighlight)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 