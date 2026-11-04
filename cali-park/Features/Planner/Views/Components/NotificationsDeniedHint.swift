import SwiftUI

// MARK: - NotificationsDeniedHint
struct NotificationsDeniedHint: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Powiadomienia są wyłączone. Włącz je w Ustawieniach, żeby dostawać przypomnienia.")
            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                Link("Otwórz Ustawienia", destination: url)
                    .foregroundStyle(Color.accent)
            }
        }
    }
}
