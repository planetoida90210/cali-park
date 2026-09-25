import SwiftUI

// MARK: - LastWorkoutCard
/// The inner card of the "Ostatni trening" module: headline, the exercises it
/// contained and when. The trailing chevron signals it opens the workout detail.
struct LastWorkoutCard: View {
    let headline: String
    let subtitle: String?
    let date: Date

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ostatni trening")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)

                Text(headline)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }

                Text(date, format: .dateTime.day().month().hour().minute())
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(Color.glassBackground)
        .clipShape(.rect(cornerRadius: 8))
        .contentShape(.rect(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview
#Preview {
    LastWorkoutCard(
        headline: "2 ćwiczenia · 77 powtórzeń",
        subtitle: "Pompki · Podciągnięcia",
        date: .now
    )
    .padding(16)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
