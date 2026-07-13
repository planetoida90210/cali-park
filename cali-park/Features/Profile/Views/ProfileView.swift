import SwiftUI

// MARK: - ProfileView
/// Placeholder tab until the profile feature is built on the stabilized base.
struct ProfileView: View {
    private let stats = ["Treningi", "Znajomi", "Osiągnięcia"]
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

            Text("Użytkownik CaliPark")
                .font(.title2)
                .foregroundColor(.textPrimary)

            Text("Poziom zaawansowania: Średni")
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
        }
        .padding(.top, 20)
    }

    // MARK: - Stats
    private var statsRow: some View {
        HStack(spacing: 20) {
            ForEach(stats, id: \.self) { stat in
                VStack {
                    Text("24")
                        .font(.title2)
                        .foregroundColor(.accent)
                    Text(stat)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.componentBackground)
                .cornerRadius(12)
            }
        }
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
