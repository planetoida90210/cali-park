import SwiftUI

// MARK: - ParkRow
/// One Park in the list or the search suggestions: equipment glyph, name,
/// locality, favorite heart and distance.
struct ParkRow: View {
    let item: ParkDistance
    var isFavorite = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.park.headlineEquipment?.symbol ?? "figure.strengthtraining.functional")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.accent)
                .scaledIconFrame(34, relativeTo: .footnote)
                .background(Color.appBackground, in: .circle)
                .overlay(Circle().stroke(Color.accent.opacity(0.6), lineWidth: 1))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(item.park.displayName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(Color.accent)
                            .accessibilityLabel("Ulubiony")
                    }
                }
                if let locality = item.park.locality.label {
                    Text(locality)
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if let meters = item.meters {
                Text(ParkFormat.distance(meters))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.accent)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
