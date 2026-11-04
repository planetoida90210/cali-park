import SwiftUI

// MARK: - BadgesSectionView
/// The badges the athlete has earned and the ones still ahead, in one grid.
/// Earned badges wear the accent; locked ones stay dimmed and spell out what
/// they ask for, so the wall is a goal board, not a mystery box.
struct BadgesSectionView: View {
    let earned: Set<Badge>

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Three badges per row; two at accessibility text sizes.
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 2 : 3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Odznaki")
                    .font(.appTitle3)
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Text("\(earned.count)/\(Badge.allCases.count)")
                    .font(.bodySmall)
                    .monospacedDigit()
                    .foregroundStyle(Color.textSecondary)
            }

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Badge.allCases) { badge in
                    BadgeCell(badge: badge, isEarned: earned.contains(badge))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
    }
}

// MARK: - BadgeCell
private struct BadgeCell: View {
    let badge: Badge
    let isEarned: Bool

    var body: some View {
        VStack(spacing: 8) {
            BadgeMedal(symbolName: badge.symbolName, isEarned: isEarned)
                // Decorative: grows with the text up to XXXL, then the room
                // goes to the title.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            Text(badge.title)
                .font(.bodySmall)
                .foregroundStyle(isEarned ? Color.textPrimary : Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            isEarned
                ? String(localized: "\(badge.title). Zdobyta.")
                : String(localized: "\(badge.title). \(badge.requirement)")
        )
    }
}

// MARK: - BadgeMedal
private struct BadgeMedal: View {
    let symbolName: String
    let isEarned: Bool

    @ScaledMetric(relativeTo: .title3) private var diameter: CGFloat = 56

    var body: some View {
        Circle()
            .fill(isEarned ? Color.accent : Color.appBackground)
            .frame(width: diameter, height: diameter)
            .overlay {
                Image(systemName: symbolName)
                    .font(.appTitle3)
                    .foregroundStyle(isEarned ? Color.black : Color.textTertiary)
            }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        BadgesSectionView(earned: [.firstWorkout, .weekStreak, .firstSkill])
            .padding(16)
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
