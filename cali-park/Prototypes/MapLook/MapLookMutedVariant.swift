#if DEBUG
// PROTOTYPE — throwaway. Variant A "Wyciszona": muted standard map, custom pins with
// equipment glyphs, grid clustering, compact bottom card for the selected Park.

import MapKit
import SwiftUI

struct MapLookMutedVariant: View {
    @State private var position: MapCameraPosition
    @State private var span: MKCoordinateSpan
    @State private var selectedID: Int?

    init(initialSelection: Int?) {
        let selected = initialSelection.flatMap { id in MapLookSampleData.parks.first { $0.id == id } }
        let region = selected.map {
            MKCoordinateRegion(center: $0.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
        } ?? MapLookSampleData.initialRegion
        _position = State(initialValue: .region(region))
        _span = State(initialValue: region.span)
        _selectedID = State(initialValue: selected?.id)
    }

    private var selectedPark: MapLookPark? {
        MapLookSampleData.parks.first { $0.id == selectedID }
    }

    /// The selected Park always stays a single pin, even when its neighbours cluster.
    private var clusters: [MapLookCluster] {
        let others = MapLookSampleData.parks.filter { $0.id != selectedID }
        var result = MapLookClustering.clusters(for: others, span: span)
        if let selectedPark { result.append(MapLookCluster(parks: [selectedPark])) }
        return result
    }

    var body: some View {
        Map(position: $position) {
            Annotation("Tu jesteś", coordinate: MapLookSampleData.userLocation, anchor: .center) {
                MapLookUserDot()
            }
            .annotationTitles(.hidden)

            ForEach(clusters) { cluster in
                if cluster.isSingle, let park = cluster.parks.first {
                    Annotation(park.name, coordinate: park.coordinate, anchor: .bottom) {
                        Button {
                            select(park)
                        } label: {
                            MutedPin(equipment: park.headlineEquipment, isSelected: park.id == selectedID)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(park.name)
                    }
                    .annotationTitles(.hidden)
                } else {
                    Annotation(MapLookFormat.parks(cluster.parks.count), coordinate: cluster.coordinate, anchor: .center) {
                        Button {
                            withAnimation(.smooth) {
                                position = .region(MapLookClustering.region(fitting: cluster.parks))
                            }
                        } label: {
                            MutedClusterBubble(count: cluster.parks.count)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(MapLookFormat.parks(cluster.parks.count))
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            span = context.region.span
        }
        .safeAreaInset(edge: .top) {
            MutedSearchBar()
        }
        .safeAreaInset(edge: .bottom) {
            if let selectedPark {
                MutedParkCard(park: selectedPark) {
                    withAnimation(.smooth) { selectedID = nil }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.smooth, value: selectedID)
    }

    private func select(_ park: MapLookPark) {
        selectedID = park.id
        withAnimation(.smooth) {
            position = .region(MKCoordinateRegion(
                center: park.coordinate,
                span: MKCoordinateSpan(latitudeDelta: min(span.latitudeDelta, 0.03), longitudeDelta: min(span.longitudeDelta, 0.03))
            ))
        }
    }
}

// MARK: - Pins

private struct MutedPin: View {
    let equipment: MapLookEquipment
    let isSelected: Bool

    var body: some View {
        VStack(spacing: -3) {
            Image(systemName: equipment.symbol)
                .font(.system(size: isSelected ? 18 : 14, weight: .semibold))
                .foregroundStyle(isSelected ? Color.black : Color.accent)
                .frame(width: isSelected ? 44 : 34, height: isSelected ? 44 : 34)
                .background(isSelected ? Color.accent : Color.componentBackground, in: .circle)
                .overlay(Circle().stroke(Color.accent.opacity(isSelected ? 0 : 0.85), lineWidth: 1.5))
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? Color.accent : Color.componentBackground)
        }
        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}

private struct MutedClusterBubble: View {
    let count: Int

    var body: some View {
        Text(count, format: .number)
            .font(.subheadline.weight(.bold).monospacedDigit())
            .foregroundStyle(Color.accent)
            .frame(width: 30 + CGFloat(min(count, 8)) * 3, height: 30 + CGFloat(min(count, 8)) * 3)
            .background(Color.componentBackground.opacity(0.95), in: .circle)
            .overlay(Circle().stroke(Color.accent.opacity(0.35), lineWidth: 5))
            .overlay(Circle().stroke(Color.accent, lineWidth: 1))
            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
    }
}

struct MapLookUserDot: View {
    var body: some View {
        Circle()
            .fill(.blue)
            .frame(width: 16, height: 16)
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .background(Circle().fill(.blue.opacity(0.2)).frame(width: 44, height: 44))
            .shadow(radius: 2)
    }
}

// MARK: - Search bar

private struct MutedSearchBar: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textSecondary)
            Text("Szukaj Parku lub dzielnicy")
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Image(systemName: "line.3.horizontal.decrease")
                .foregroundStyle(Color.accent)
                .accessibilityLabel("Filtry")
        }
        .font(.body)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .mapLookGlass(in: .capsule)
        .padding(.horizontal)
    }
}

// MARK: - Bottom card

private struct MutedParkCard: View {
    let park: MapLookPark
    let onClose: () -> Void

    var body: some View {
        let distance = park.distance(from: MapLookSampleData.userLocation)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(park.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text("\(park.district) · \(MapLookFormat.distance(distance)) · \(MapLookFormat.walk(distance))")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Button("Zamknij", systemImage: "xmark", action: onClose)
                    .labelStyle(.iconOnly)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.08), in: .circle)
            }

            HStack(spacing: 6) {
                ForEach(park.equipment) { item in
                    Label(item.title, systemImage: item.symbol)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08), in: .capsule)
                }
            }
            .foregroundStyle(Color.textPrimary)

            HStack(spacing: 12) {
                Label(MapLookFormat.rating(park.rating), systemImage: "star.fill")
                    .foregroundStyle(Color.textPrimary)
                if park.isLit {
                    Label("Oświetlony", systemImage: "lightbulb.fill")
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Button("Prowadź", systemImage: "figure.walk") {}
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accent, in: .capsule)
            }
            .font(.subheadline)
        }
        .padding(16)
        .mapLookGlass(in: .rect(cornerRadius: 28))
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}
#endif
