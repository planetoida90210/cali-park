import SwiftUI

// MARK: - BadgesSectionView
/// The badges the athlete has earned and the ones still ahead, in one grid.
/// Earned badges wear the accent; locked ones stay dimmed and spell out what
/// they ask for, so the wall is a goal board, not a mystery box.
struct BadgesSectionView: View {
    let earned: Set<Badge>

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Odznaki")
                    .font(.title3)
                    .foregroundStyle(Color.textPrimary)

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
            Circle()
                .fill(isEarned ? Color.accent : Color.appBackground)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: badge.symbolName)
                        .font(.title3)
                        .foregroundStyle(isEarned ? Color.black : Color.textTertiary)
                }

            Text(badge.title)
                .font(.bodySmall)
                .foregroundStyle(isEarned ? Color.textPrimary : Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isEarned ? "\(badge.title). Zdobyta." : "\(badge.title). \(badge.requirement)")
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
