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

                    ForEach(0..<4, id: \.self) { index in
                        CommunityPostCard(index: index)
                    }
                }
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Społeczność")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - CommunityPostCard
private struct CommunityPostCard: View {
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Text("To jest przykładowy post użytkownika w społeczności CaliPark. Użytkownicy mogą dzielić się swoimi treningami i osiągnięciami.")
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
                Text("Użytkownik \(index + 1)")
                    .font(.bodyLarge)
                    .foregroundColor(.textPrimary)
                Text("2 godziny temu")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .foregroundColor(.textSecondary)
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
