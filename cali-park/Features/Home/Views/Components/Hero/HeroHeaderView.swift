import SwiftUI

// MARK: - HeroHeaderView
/// The greeting lead-in shared by every hero state: a time-of-day salutation
/// without a name (there is no Account in this build). Deliberately quiet
/// (secondary text) so each state's own headline stays the primary message.
/// The `now` date is injected so the greeting is deterministic in previews.
struct HeroHeaderView: View {
    var now: Date = .now
    var calendar: Calendar = .current

    var body: some View {
        Text(Self.greeting(hour: calendar.component(.hour, from: now)))
            .font(.bodyMedium)
            .foregroundStyle(Color.textSecondary)
    }

    /// The salutation for an hour of the day (0–23), in the app's casual voice:
    /// 5–11 "Dzień dobry", 12–17 "Cześć", 18–21 "Dobry wieczór", and
    /// "Dobrej nocy" from 22 until 5, so 02:09 is not an evening.
    static func greeting(hour: Int) -> String {
        switch hour {
        case 5..<12: String(localized: "Dzień dobry")
        case 12..<18: String(localized: "Cześć")
        case 18..<22: String(localized: "Dobry wieczór")
        default: String(localized: "Dobrej nocy")
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(alignment: .leading, spacing: 12) {
        HeroHeaderView(now: dateAt(hour: 8))
        HeroHeaderView(now: dateAt(hour: 14))
        HeroHeaderView(now: dateAt(hour: 21))
        HeroHeaderView(now: dateAt(hour: 2))
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
