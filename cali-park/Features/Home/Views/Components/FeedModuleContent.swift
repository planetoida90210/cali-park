import SwiftUI

// MARK: - Feed Module

struct FeedModuleContent: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Aktywność znajomych")
                    .font(.bodyLarge)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                feedItem(
                    avatar: "M",
                    name: "Maciek S.",
                    action: "zaliczył nowy rekord: 15 podciągnięć",
                    time: "1 godz. temu"
                )
                
                feedItem(
                    avatar: "K",
                    name: "Kuba W.",
                    action: "ukończył trening Pull",
                    time: "3 godz. temu"
                )
            }
        }
        .padding()
        .background(Color.componentBackground)
        .cornerRadius(12)
    }
    
    private func feedItem(avatar: String, name: String, action: String, time: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.accent.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(avatar)
                            .font(.footnote.bold())
                            .foregroundColor(.accent)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.bodyMedium.bold())
                        .foregroundColor(.textPrimary)
                    
                    Text(action)
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            
            Divider()
                .background(Color.divider)
        }
    }
}

#Preview {
    FeedModuleContent()
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 