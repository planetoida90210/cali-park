import SwiftUI

// MARK: - RatingStarsView
/// Reusable star–rating component. Supports interactive and read-only modes.
/// Designed to be independent from concrete feature, hence placed in `Components/`.
struct RatingStarsView: View {
    // Binding when interactive, constant value when read-only.
    private let rating: Binding<Int>
    private let maximum: Int
    private let interactive: Bool

    // MARK: Init helpers
    init(rating: Binding<Int>, max: Int = 5) {
        self.rating = rating
        self.maximum = max
        self.interactive = true
    }

    init(value: Int, max: Int = 5) {
        self.rating = .constant(value)
        self.maximum = max
        self.interactive = false
    }

    // MARK: Body
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maximum, id: \.self) { index in
                Image(systemName: starName(for: index))
                    .foregroundColor(index <= rating.wrappedValue ? .accent : .gray.opacity(0.5))
                    .font(.system(size: 18))
                    .accessibilityHidden(true)
                    .contentShape(Rectangle())
                    .onTapGesture { handleTap(index) }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Ocena")
        .accessibilityValue("\(rating.wrappedValue) gwiazdek")
        .accessibilityAdjustableAction { direction in
            guard interactive else { return }
            switch direction {
            case .increment: rating.wrappedValue = Swift.min(maximum, rating.wrappedValue + 1)
            case .decrement: rating.wrappedValue = Swift.max(1, rating.wrappedValue - 1)
            default: break
            }
        }
    }

    // MARK: Helpers
    private func starName(for index: Int) -> String {
        index <= rating.wrappedValue ? "star.fill" : "star"
    }

    private func handleTap(_ index: Int) {
        guard interactive else { return }
        rating.wrappedValue = index
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        RatingStarsView(value: 3)
        RatingStarsView(rating: .constant(4))
    }
    .padding()
    .preferredColorScheme(.dark)
} 