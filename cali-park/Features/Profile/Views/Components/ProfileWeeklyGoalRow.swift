import SwiftUI

// MARK: - ProfileWeeklyGoalRow
/// The weekly goal row in Profile: the goal, this week's progress and "Zmień",
/// which opens the goal editor.
struct ProfileWeeklyGoalRow: View {
    /// The goal's title, or `nil` when it couldn't be read.
    let title: String?
    /// This week's progress, or `nil` when the goal couldn't be read.
    let progressText: String?
    let onChange: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 28

    var body: some View {
        Button {
            onChange()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "target")
                    .foregroundStyle(Color.accent)
                    .frame(width: iconWidth)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title ?? String(localized: "Cel tygodniowy"))
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textPrimary)
                    Text(progressText.map { String(localized: "Ten tydzień: \($0)") }
                         ?? String(localized: "Nie udało się odczytać celu"))
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                    // At accessibility sizes "Zmień" moves under the text, so
                    // the goal keeps the row's full width.
                    if typeSize.isAccessibilitySize {
                        changeLabel
                            .padding(.top, 4)
                    }
                }

                if !typeSize.isAccessibilitySize {
                    Spacer()
                    changeLabel
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Otwiera edycję celu tygodniowego")
        .listRowBackground(Color.componentBackground)
    }

    private var changeLabel: some View {
        Text("Zmień")
            .font(.buttonSmall)
            .foregroundStyle(Color.accent)
    }
}
