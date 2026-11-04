import SwiftUI

// MARK: - ParkPin
/// Variant A pin: dark disc with a lime equipment glyph; lime when selected.
struct ParkPin: View {
    let equipment: EquipmentType?
    let isSelected: Bool

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 34

    var body: some View {
        let diameter = isSelected ? size * 1.3 : size
        VStack(spacing: -3) {
            Image(systemName: equipment?.symbol ?? "figure.strengthtraining.functional")
                .font(isSelected ? .body.weight(.semibold) : .footnote.weight(.semibold))
                .foregroundStyle(isSelected ? Color.black : Color.accent)
                .frame(width: diameter, height: diameter)
                .background(isSelected ? Color.accent : Color.componentBackground, in: .circle)
                .overlay(Circle().stroke(Color.accent.opacity(isSelected ? 0 : 0.85), lineWidth: 1.5))
            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption2)
                .foregroundStyle(isSelected ? Color.accent : Color.componentBackground)
        }
        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}

// MARK: - ParkClusterBubble
struct ParkClusterBubble: View {
    let count: Int

    @ScaledMetric(relativeTo: .subheadline) private var base: CGFloat = 32

    var body: some View {
        let diameter = base + CGFloat(min(count, 20)) * 1.2
        Text(count, format: .number)
            .font(.subheadline.weight(.bold).monospacedDigit())
            .foregroundStyle(Color.accent)
            .frame(width: diameter, height: diameter)
            .background(Color.componentBackground.opacity(0.95), in: .circle)
            .overlay(Circle().stroke(Color.accent.opacity(0.35), lineWidth: 5))
            .overlay(Circle().stroke(Color.accent, lineWidth: 1))
            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
    }
}

// MARK: - OSMAttributionLink
/// "© Współtwórcy OpenStreetMap", linking to the OSM copyright page (ODbL).
struct OSMAttributionLink: View {
    var body: some View {
        Link(ParkFormat.attribution, destination: ParkFormat.copyrightURL)
            .font(.caption2.weight(.medium))
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.55), in: .capsule)
            .accessibilityHint("Otwiera licencję danych OpenStreetMap")
    }
}

// MARK: - ParkVerificationBadge
/// "Zweryfikowany" in lime; "Ze Społeczności" and "Z OSM" in grey (ticket 023).
struct ParkVerificationBadge: View {
    let verification: ParkVerification

    var body: some View {
        let isVerified = verification == .verified
        Label(verification.label, systemImage: isVerified ? "checkmark.seal.fill" : "map")
            .font(.caption.weight(.semibold))
            .foregroundStyle(isVerified ? Color.black : Color.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isVerified ? Color.accent : Color.white.opacity(0.08), in: .capsule)
    }
}

// MARK: - EquipmentChips
/// Equipment as small capsules; "Sprzęt nieznany" when OSM lists none.
struct EquipmentChips: View {
    let equipment: [ParkEquipment]
    var limit = Int.max

    var body: some View {
        if equipment.isEmpty {
            Label("Sprzęt nieznany", systemImage: "questionmark.circle")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.textSecondary)
        } else {
            let shown = equipment.prefix(limit)
            HStack(spacing: 6) {
                ForEach(shown, id: \.type) { item in
                    Label(item.type.title, systemImage: item.type.symbol)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08), in: .capsule)
                }
                if equipment.count > shown.count {
                    Text("+\(equipment.count - shown.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .foregroundStyle(Color.textPrimary)
        }
    }
}

// MARK: - Glass
extension View {
    /// Liquid Glass on iOS 26, a dark material below that.
    @ViewBuilder
    func parkGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }
}
