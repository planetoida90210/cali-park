import SwiftUI

// MARK: - HeroHeaderView
/// The greeting lead-in shared by every hero state: a time-of-day salutation
/// plus the user's name. Deliberately quiet (secondary text) so each state's
/// own headline stays the primary message. The `now` date is injected so the
/// greeting is deterministic in previews.
struct HeroHeaderView: View {
    let name: String
    var now: Date = .now
    var calendar: Calendar = .current

    var body: some View {
        Text("\(greeting), \(name)")
            .font(.bodyMedium)
            .foregroundStyle(Color.textSecondary)
            .accessibilityLabel("\(greeting), \(name)")
    }

    /// Morning / midday / evening salutation, matching the app's casual voice.
    private var greeting: String {
        switch calendar.component(.hour, from: now) {
        case 5..<12: "Dzień dobry"
        case 12..<18: "Siema"
        default: "Dobry wieczór"
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(alignment: .leading, spacing: 12) {
        HeroHeaderView(name: "Michał", now: dateAt(hour: 8))
        HeroHeaderView(name: "Michał", now: dateAt(hour: 14))
        HeroHeaderView(name: "Michał", now: dateAt(hour: 21))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

/// Preview-only helper: today at a fixed hour, to eyeball each greeting.
private func dateAt(hour: Int) -> Date {
    Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
}
