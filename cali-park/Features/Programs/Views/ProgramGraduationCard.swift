import SwiftUI

// MARK: - ProgramGraduationCard
/// "Czas na Fundamenty": shown above the plans when the athlete finished
/// "Pierwsze podciągnięcie" (3 × 8 full pull-ups). One tap replaces the plan
/// with "Fundamenty" on the same days; "Nie teraz" hides the card for good.
struct ProgramGraduationCard: View {
    let planName: String
    let isReplacing: Bool
    let onMoveOn: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(Color.accent)
                    .accessibilityHidden(true)
                Text("Czas na Fundamenty")
                    .font(.appTitle3)
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }

            Text("Robisz już 3 serie po 8 pełnych podciągnięć, więc plan „\(planName)” zrobił swoje. Fundamenty trenują całe ciało w trzech parach.")
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Text("Plan Fundamenty zastąpi „\(planName)” w te same dni i z tym samym przypomnieniem. Historia treningów zostaje.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { buttons }
                VStack(alignment: .leading, spacing: 12) { buttons }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder private var buttons: some View {
        Button("Przejdź na Fundamenty", action: onMoveOn)
            .buttonStyle(.accent(.compact, fillsWidth: false))
            .disabled(isReplacing)
        Button("Nie teraz", action: onDismiss)
            .font(.buttonMedium)
            .foregroundStyle(Color.textSecondary)
            .disabled(isReplacing)
    }
}

// MARK: - Preview
#Preview {
    List {
        ProgramGraduationCard(planName: "Pierwsze podciągnięcie", isReplacing: false, onMoveOn: {}, onDismiss: {})
            .listRowBackground(Color.componentBackground)
    }
    .scrollContentBackground(.hidden)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
