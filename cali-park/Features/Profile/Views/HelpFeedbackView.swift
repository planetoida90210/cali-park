import SwiftUI

// MARK: - HelpFeedbackView
/// "Pomoc i opinie": mail to the team, and how TestFlight testers send
/// feedback with a screenshot.
struct HelpFeedbackView: View {
    var body: some View {
        List {
            Section {
                if let mail = SupportContact.mailURL() {
                    Link(destination: mail) {
                        Label("Napisz do nas", systemImage: "envelope")
                            .foregroundStyle(Color.accent)
                    }
                }
            } footer: {
                Text("Pytanie, błąd albo pomysł? Odpisujemy na każdą wiadomość. Adres: \(SupportContact.email)")
            }
            .listRowBackground(Color.componentBackground)

            Section("Testujesz w TestFlight?") {
                Text("Zrób zrzut ekranu w apce, stuknij miniaturkę i wybierz „Udostępnij do wersji beta”. Opinia trafi do nas razem ze zrzutem. Możesz też otworzyć TestFlight i wybrać „Wyślij opinię o wersji beta”.")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
            }
            .listRowBackground(Color.componentBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Pomoc i opinie")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { HelpFeedbackView() }
        .preferredColorScheme(.dark)
}
