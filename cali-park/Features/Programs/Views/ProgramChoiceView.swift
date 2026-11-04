import SwiftUI

// MARK: - ProgramChoiceView
/// Onboarding's program step: the suggested program first, the others below,
/// and "Bez programu". The choice is created when onboarding finishes.
struct ProgramChoiceView: View {
    let viewModel: ProgramChoiceViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Program na start")
                        .font(.title2)
                        .foregroundStyle(Color.textPrimary)

                    Text("Na podstawie Twoich odpowiedzi polecamy jeden program. Możesz wybrać inny albo żaden. Utworzymy z niego zwykły plan, który zmienisz w każdej chwili.")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                }

                VStack(spacing: 12) {
                    ForEach(orderedPrograms) { program in
                        ProgramChoiceRow(
                            title: program.name,
                            subtitle: "\(program.tagline) \(program.frequency), \(program.sessionLength).".keptTogether,
                            credit: program.creditLine.keptTogether,
                            isSuggested: viewModel.isSuggested(program),
                            isSelected: viewModel.choice == .program(program.id)
                        ) {
                            viewModel.pick(.program(program.id))
                        }
                    }

                    ProgramChoiceRow(
                        title: "Bez programu",
                        subtitle: "Plan ułożysz sam albo wybierzesz program później w Planach treningowych.",
                        credit: nil,
                        isSuggested: false,
                        isSelected: viewModel.choice == .none
                    ) {
                        viewModel.pick(.none)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    /// The suggested program first, the rest in catalog order.
    private var orderedPrograms: [TrainingProgram] {
        viewModel.programs.filter(viewModel.isSuggested) + viewModel.programs.filter { !viewModel.isSuggested($0) }
    }
}

// MARK: - ProgramChoiceRow
private struct ProgramChoiceRow: View {
    let title: String
    let subtitle: String
    let credit: String?
    let isSuggested: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.bodyLarge)
                            .foregroundStyle(Color.textPrimary)
                        if isSuggested {
                            Text("Polecany")
                                .font(.buttonSmall)
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accent, in: .capsule)
                        }
                    }

                    Text(subtitle)
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.leading)

                    if let credit {
                        Text(credit)
                            .font(.bodySmall)
                            .foregroundStyle(Color.textTertiary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accent : Color.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.componentBackground)
            .clipShape(.rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accent : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview
#Preview {
    ProgramChoiceView(viewModel: AppEnvironment.seeded().makeProgramChoiceViewModel())
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
