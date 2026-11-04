import SwiftUI

// MARK: - ParkCardSectionHeader
/// Section title on the full Park card; a VoiceOver heading.
struct ParkCardSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(.title3, weight: .bold))
            .foregroundStyle(Color.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - ParkEquipmentSection
/// "Sprzęt": every device with its Polish name, and the count and heights
/// when OSM has them. Every Park has at least one core device.
struct ParkEquipmentSection: View {
    let park: Park

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ParkCardSectionHeader(title: "Sprzęt")

            VStack(spacing: 0) {
                ForEach(park.equipment, id: \.type) { item in
                    if item.type != park.equipment.first?.type {
                        Divider().overlay(Color.divider)
                    }
                    ParkEquipmentLine(item: item)
                }
            }
            .padding(.horizontal, 14)
            .background(Color.componentBackground, in: .rect(cornerRadius: 18))

            if ParkFormat.supportsFlag(park) {
                Label("Nadaje się do flagi: jest słup albo drabinka gimnastyczna", systemImage: "flag.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}

private struct ParkEquipmentLine: View {
    let item: ParkEquipment

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 34

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accent)
                .frame(width: size, height: size)
                .background(Color.white.opacity(0.08), in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.type.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                if let heights = ParkFormat.heights(item) {
                    Text("Wysokość: \(heights)")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Spacer(minLength: 8)
            if let count = ParkFormat.count(item) {
                Text(count)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ParkFormat.equipmentAccessibility(item))
    }
}

// MARK: - ParkSourceSection
/// "Skąd te dane": the verification badge and what it means, the OSM data
/// date, the ODbL credit and a link to the OSM element.
struct ParkSourceSection: View {
    let park: Park
    let dataTimestamp: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ParkCardSectionHeader(title: "Skąd te dane")

            VStack(alignment: .leading, spacing: 10) {
                ParkVerificationBadge(verification: park.verification)
                Text(park.verification.explanation)
                    .font(.subheadline)
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if park.source == .osm, let dataTimestamp {
                    Text(ParkFormat.dataDate(dataTimestamp))
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }

                Divider().overlay(Color.divider)

                if let url = ParkFormat.osmURL(for: park) {
                    Link(destination: url) {
                        Label("Zobacz w OpenStreetMap", systemImage: "arrow.up.right.square")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.accent)
                    }
                    .accessibilityHint("Otwiera ten Park na stronie OpenStreetMap")
                }
                VStack(alignment: .leading, spacing: 2) {
                    Link(destination: ParkFormat.copyrightURL) {
                        Text(ParkFormat.attribution)
                            .underline()
                    }
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityHint("Otwiera licencję danych OpenStreetMap")
                    Text("Fakty o Parku są na licencji ODbL.")
                        .foregroundStyle(Color.textSecondary)
                }
                .font(.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.componentBackground, in: .rect(cornerRadius: 18))
        }
    }
}

// MARK: - ParkDetailsSection
/// "Szczegóły": surface, lighting, roof, access, opening hours and machines,
/// with "Brak danych" where OSM doesn't say.
struct ParkDetailsSection: View {
    let park: Park

    var body: some View {
        let details = ParkFormat.details(for: park)
        VStack(alignment: .leading, spacing: 12) {
            ParkCardSectionHeader(title: "Szczegóły")
            VStack(spacing: 0) {
                ForEach(details) { detail in
                    if detail.id != details.first?.id {
                        Divider().overlay(Color.divider)
                    }
                    ParkDetailRow(detail: detail)
                }
            }
            .padding(.horizontal, 14)
            .background(Color.componentBackground, in: .rect(cornerRadius: 18))
        }
    }
}

private struct ParkDetailRow: View {
    let detail: ParkDetail

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: detail.symbol)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .frame(minWidth: 20)
            Text(detail.label)
                .foregroundStyle(Color.textSecondary)
            Spacer(minLength: 8)
            Text(detail.value ?? ParkFormat.unknownDetail)
                .foregroundStyle(detail.value == nil ? Color.textSecondary : Color.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, 11)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(detail.label)
        .accessibilityValue(detail.value ?? ParkFormat.unknownDetail)
    }
}
