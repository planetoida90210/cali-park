import SwiftUI

// MARK: - OnboardingView
/// First-run flow: welcome, placement (where the athlete already is on each
/// progression path), goals, and location permission.
///
/// The placement page replaces the old three-card "fitness level" question,
/// whose answer was thrown away. Its answers are saved through `PlacementStoring`
/// via `PlacementCalibrationViewModel`, so a strong athlete starts partway up
/// each ladder instead of from the bottom.
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var currentPage = 0
    @State private var calibration: PlacementCalibrationViewModel
    @State private var selectedGoals: [String] = []
    @State private var locationPermission = false

    /// Scales the hero glyphs with Dynamic Type while keeping their base size.
    @ScaledMetric private var heroIconSize: CGFloat = 80

    private let goals = [
        "Zwiększenie siły",
        "Budowa masy mięśniowej",
        "Poprawa wytrzymałości",
        "Redukcja tkanki tłuszczowej",
        "Nauka nowych umiejętności",
        "Przygotowanie do zawodów"
    ]

    private let pageCount = 4

    init(environment: AppEnvironment) {
        _calibration = State(initialValue: environment.makePlacementCalibrationViewModel())
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack {
                TabView(selection: $currentPage) {
                    welcomeView.tag(0)
                    placementView.tag(1)
                    goalsView.tag(2)
                    locationPermissionView.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack {
                    pageIndicators
                        .padding(.bottom, 20)

                    navigationButtons
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding()
        }
    }

    // MARK: - Navigation chrome

    private var pageIndicators: some View {
        HStack {
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? Color.accent : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
        .accessibilityHidden(true)
    }

    private var navigationButtons: some View {
        HStack {
            if currentPage > 0 {
                Button("Wróć") {
                    withAnimation { currentPage -= 1 }
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            Spacer()

            let isLastPage = currentPage == pageCount - 1
            Button(isLastPage ? "Rozpocznij" : "Dalej") {
                if isLastPage {
                    finish()
                } else {
                    withAnimation { currentPage += 1 }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private func finish() {
        calibration.save()
        hasCompletedOnboarding = true
    }

    // MARK: - Pages

    private var welcomeView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.gymnastics")
                .font(.system(size: heroIconSize))
                .foregroundStyle(Color.accent)

            Text("Witaj w CaliPark")
                .font(.largeTitle)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text("Twoja podróż po świecie kalisteniki zaczyna się tutaj. Przygotujmy wszystko, aby dopasować aplikację do Twoich potrzeb.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    private var placementView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Co już potrafisz?")
                        .font(.title2)
                        .foregroundStyle(Color.textPrimary)

                    Text("Zaczniesz od właściwego szczebla, nie od zera.")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                }

                PlacementFormView(viewModel: calibration)
            }
            .padding(.vertical, 8)
        }
    }

    private var goalsView: some View {
        VStack(spacing: 20) {
            Text("Jakie są Twoje cele treningowe?")
                .font(.title2)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text("Wybierz wszystkie, które Cię interesują.")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(goals, id: \.self) { goal in
                        goalRow(goal: goal)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    private func goalRow(goal: String) -> some View {
        let isSelected = selectedGoals.contains(goal)

        return Button {
            if isSelected {
                selectedGoals.removeAll { $0 == goal }
            } else {
                selectedGoals.append(goal)
            }
        } label: {
            HStack {
                Text(goal)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? Color.accent : Color.textTertiary)
                    .font(.title3)
            }
            .padding()
            .background(Color.componentBackground)
            .clipShape(.rect(cornerRadius: 12))
        }
        .accessibilityLabel(goal)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var locationPermissionView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "location.circle.fill")
                .font(.system(size: heroIconSize))
                .foregroundStyle(Color.accent)

            Text("Dostęp do lokalizacji")
                .font(.title2)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text("Aby znaleźć siłownie kalisteniki w pobliżu, potrzebujemy dostępu do Twojej lokalizacji. Możesz zmienić to później w ustawieniach.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Toggle(isOn: $locationPermission) {
                Text("Zezwól na dostęp do lokalizacji")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)
            }
            .tint(Color.accent)
            .padding()
            .background(Color.componentBackground)
            .clipShape(.rect(cornerRadius: 12))

            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(environment: .preview)
        .preferredColorScheme(.dark)
}
