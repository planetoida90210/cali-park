import SwiftUI

// MARK: - CommunityView
/// Placeholder tab until the community feature is built on the stabilized base.
struct CommunityView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Aktywność społeczności")
                        .font(.title3)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(Array(Self.posts.enumerated()), id: \.offset) { _, post in
                        CommunityPostCard(name: post.name, message: post.message, time: post.time)
                    }
                }
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Społeczność")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private static let posts: [(name: String, message: String, time: String)] = [
        ("Maciek", "15 podciągnięć na drążku. Czwarty dzień z rzędu.", "1 godzinę temu"),
        ("Kuba", "Plan na dziś: pompki i dipy.", "2 godziny temu"),
        ("Ola", "Pierwszy muscle-up w tym miesiącu.", "5 godzin temu"),
        ("Ania", "Trening przy 18 stopniach. Warto było wyjść.", "wczoraj")
    ]
}

// MARK: - CommunityPostCard
private struct CommunityPostCard: View {
    let name: String
    let message: String
    let time: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Text(message)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
            actions
        }
        .padding()
        .background(Color.componentBackground)
        .cornerRadius(16)
    }

    private var header: some View {
        HStack {
            Circle()
                .fill(Color.componentBackground)
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "person.fill").foregroundColor(.accent))

            VStack(alignment: .leading) {
                Text(name)
                    .font(.bodyLarge)
                    .foregroundColor(.textPrimary)
                Text(time)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
    }

    private var actions: some View {
        HStack {
            Label("24", systemImage: "heart")
                .foregroundColor(.textSecondary)
            Spacer()
            Label("8", systemImage: "bubble.right")
                .foregroundColor(.textSecondary)
            Spacer()
            Label("Udostępnij", systemImage: "square.and.arrow.up")
                .foregroundColor(.textSecondary)
        }
        .font(.bodyMedium)
        .tint(.accent)
        .padding(.top, 8)
    }
}

// MARK: - Preview
#Preview {
    CommunityView()
        .preferredColorScheme(.dark)
}
