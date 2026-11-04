import SwiftUI

// MARK: - OnboardingNavigationButtons
/// "Wróć" and "Dalej" side by side; when large text doesn't fit one row
/// they are stacked at full width, so the titles don't break mid-word.
struct OnboardingNavigationButtons: View {
    let viewModel: OnboardingViewModel
    /// Runs when "Rozpocznij" is tapped on the last page.
    let onFinish: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                if viewModel.page.previous != nil {
                    backButton(fullWidth: false)
                }

                Spacer()

                forwardButton(fullWidth: false)
            }

            VStack(spacing: 12) {
                forwardButton(fullWidth: true)
                if viewModel.page.previous != nil {
                    backButton(fullWidth: true)
                }
            }
        }
    }

    private func backButton(fullWidth: Bool) -> some View {
        Button("Wróć") {
            withAnimation { viewModel.goBack() }
        }
        .buttonStyle(.secondary(.large, fillsWidth: fullWidth))
    }

    private func forwardButton(fullWidth: Bool) -> some View {
        Button {
            if viewModel.page.isLast {
                onFinish()
            } else {
                withAnimation { viewModel.goForward() }
            }
        } label: {
            Text(viewModel.page.isLast ? "Rozpocznij" : "Dalej")
        }
        .buttonStyle(.accent(.large, fillsWidth: fullWidth))
        .disabled(viewModel.isFinishing)
    }
}
