import SwiftUI

// MARK: - ProfileView
/// Placeholder tab until the profile feature is built on the stabilized base.
struct ProfileView: View {
    private let menuOptions = ["Edytuj profil", "Moje treningi", "Historia", "Ustawienia", "Pomoc", "Wyloguj"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    statsRow
                    menuList
                }
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Header
    private var profileHeader: some View {
        VStack {
            Circle()
                .fill(Color.componentBackground)
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.accent)
                )

            Text("Twój profil")
                .font(.title2)
                .foregroundColor(.textPrimary)
        }
        .padding(.top, 20)
    }

    // MARK: - Stats
    private var statsRow: some View {
        Text("Statystyki pojawią się, gdy zaczniesz trenować.")
            .font(.bodyMedium)
            .foregroundColor(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Menu
    private var menuList: some View {
        VStack(spacing: 0) {
            ForEach(menuOptions, id: \.self) { option in
                HStack {
                    Text(option)
                        .font(.bodyLarge)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.accent)
                }
                .padding()
                .background(Color.componentBackground)

                if option != menuOptions.last {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .cornerRadius(16)
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
