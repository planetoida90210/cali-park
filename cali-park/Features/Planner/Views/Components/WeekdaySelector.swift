import SwiftUI

// MARK: - WeekdaySelector
/// Row of weekday toggles in the user's locale order (Monday-first in Poland).
/// Multiple days can be active — that is the weekly schedule's `Set<Weekday>`.
/// At accessibility text sizes the seven days don't fit one row, so they wrap
/// into rows of four.
struct WeekdaySelector: View {
    let selected: Set<Weekday>
    let onToggle: (Weekday) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 4), count: typeSize.isAccessibilitySize ? 4 : 7)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Weekday.ordered()) { day in
                let isOn = selected.contains(day)
                Button {
                    onToggle(day)
                } label: {
                    Text(day.shortName)
                        .font(.buttonSmall)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(isOn ? Color.accent : Color.appBackground)
                        .foregroundStyle(isOn ? Color.black : Color.textPrimary)
                        .clipShape(.rect(cornerRadius: AppRadius.small))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.displayName)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}
