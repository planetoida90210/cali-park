import SwiftUI

// MARK: - ExerciseInstructionRow
struct ExerciseInstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.bodyMedium)
                .monospacedDigit()
                .foregroundStyle(Color.accent)

            Text(text)
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}
