import SwiftUI

// MARK: - SetPadDisplay
struct SetPadDisplay: View {
    let input: SetPadInput
    let measurement: ExerciseMeasurement
    let showsHint: Bool
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                if !input.setsForSaving.isEmpty {
                    Button("Wyczyść", action: onClear)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Text(input.displayText)
                    .font(.system(.largeTitle, design: .rounded, weight: .light))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: input.displayText)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    // Shrinks first, so "12 + 12 + 12" stays whole at large
                    // text sizes; only a long workout loses its first sets.
                    .minimumScaleFactor(0.6)
                    .truncationMode(.head)

                if measurement == .seconds {
                    Text("s")
                        .font(.appTitle3)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Text(summaryText)
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .contentTransition(.numericText())
                .animation(.snappy, value: summaryText)
        }
        .padding(16)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var summaryText: String {
        if showsHint && input.setsForSaving.isEmpty {
            return measurement == .seconds
                ? String(localized: "Każdy + to nowe utrzymanie")
                : String(localized: "Każdy + to nowa seria")
        }
        let sets = input.setsForSaving.count
        return "\(PolishPlural.sets(sets)) · \(MeasureFormat.total(of: input.loggedSets(for: measurement)))"
    }

    private var accessibilityLabel: String {
        let title = measurement == .seconds ? String(localized: "Utrzymania") : String(localized: "Serie")
        return String(localized: "\(title): \(input.displayText). \(summaryText)")
    }
}
