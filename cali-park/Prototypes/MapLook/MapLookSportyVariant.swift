#if DEBUG
// PROTOTYPE — throwaway. Variant B "Sportowa": satellite hybrid with realistic elevation,
// large neon pins, equipment filter chips and a card carousel synced with the map.

import MapKit
import SwiftUI

struct MapLookSportyVariant: View {
    @State private var position: MapCameraPosition
    @State private var span: MKCoordinateSpan
    @State private var carouselID: Int?
    @State private var filter: MapLookEquipment?

    init(initialSelection: Int?) {
        let selected = initialSelection.flatMap { id in MapLookSampleData.parks.first { $0.id == id } }
        if let selected {
            _position = State(initialValue: .camera(Self.camera(for: selected)))
            _span = State(initialValue: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012))
        } else {
            _position = State(initialValue: .region(MapLookSampleData.initialRegion))
            _span = State(initialValue: MapLookSampleData.initialRegion.span)
        }
        _carouselID = State(initialValue: selected?.id)
    }

    private var visibleParks: [MapLookPark] {
        let sorted = MapLookSampleData.sortedByDistance()
        guard let filter else { return sorted }
        return sorted.filter { $0.equipment.contains(filter) }
    }

    private var clusters: [MapLookCluster] {
        let others = visibleParks.filter { $0.id != carouselID }
        var result = MapLookClustering.clusters(for: others, span: span, cellsAcross: 3.5)
        if let selected = visibleParks.first(where: { $0.id == carouselID }) {
            result.append(MapLookCluster(parks: [selected]))
        }
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
                            withAnimation(.snappy) { carouselID = park.id }
                        } label: {
                            SportyPin(park: park, isSelected: park.id == carouselID)
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
                            SportyClusterBubble(count: cluster.parks.count)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(MapLookFormat.parks(cluster.parks.count))
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        // Realistic elevation only once a Park is selected: in the iOS 26.5 simulator,
        // SwiftUI annotations disappear at city zoom with `.realistic` elevation.
        .mapStyle(.hybrid(elevation: carouselID == nil ? .flat : .realistic, pointsOfInterest: .excludingAll))
        .mapControls {
            MapPitchToggle()
            MapCompass()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            span = context.region.span
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            SportyHeader(filter: $filter, count: visibleParks.count)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SportyCarousel(parks: visibleParks, selectedID: $carouselID)
        }
        .onChange(of: carouselID) { _, newValue in
            guard let park = MapLookSampleData.parks.first(where: { $0.id == newValue }) else { return }
            withAnimation(.smooth(duration: 0.8)) {
                position = .camera(Self.camera(for: park))
            }
        }
        .onChange(of: filter) { _, _ in
            carouselID = nil
        }
    }

    private static func camera(for park: MapLookPark) -> MapCamera {
        MapCamera(centerCoordinate: park.coordinate, distance: 1400, heading: 20, pitch: 55)
    }
}

// MARK: - Header

private struct SportyHeader: View {
    @Binding var filter: MapLookEquipment?
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("PARKI")
                    .font(.largeTitle.weight(.black).italic())
                    .foregroundStyle(Color.accent)
                Text("W POBLIŻU")
                    .font(.largeTitle.weight(.black).italic())
                    .foregroundStyle(.white)
                Spacer()
                Text(count, format: .number)
                    .font(.title2.weight(.black).monospacedDigit())
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.7), radius: 6)
            .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    SportyChip(title: "Wszystko", symbol: "square.grid.2x2.fill", isOn: filter == nil) {
                        filter = nil
                    }
                    ForEach(MapLookEquipment.allCases) { item in
                        SportyChip(title: item.title, symbol: item.symbol, isOn: filter == item) {
                            filter = filter == item ? nil : item
                        }
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.bottom, 10)
        .background(
            LinearGradient(colors: [.black.opacity(0.85), .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
    }
}

private struct SportyChip: View {
    let title: String
    let symbol: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(title, systemImage: symbol, action: action)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(isOn ? Color.black : Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isOn ? Color.accent : Color.black.opacity(0.6), in: .capsule)
            .overlay(Capsule().stroke(Color.white.opacity(isOn ? 0 : 0.2), lineWidth: 1))
    }
}

// MARK: - Pins

private struct SportyPin: View {
    let park: MapLookPark
    let isSelected: Bool

    var body: some View {
        let size: CGFloat = isSelected ? 64 : 46
        VStack(spacing: -6) {
            Image(systemName: park.headlineEquipment.symbol)
                .font(.system(size: size * 0.42, weight: .heavy))
                .foregroundStyle(.black)
                .frame(width: size, height: size)
                .background(Color.accent, in: .circle)
                .overlay(Circle().stroke(isSelected ? Color.white : Color.black, lineWidth: isSelected ? 4 : 2.5))
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: isSelected ? 20 : 15))
                .foregroundStyle(isSelected ? Color.white : Color.black)
        }
        .shadow(color: Color.accent.opacity(isSelected ? 0.8 : 0.35), radius: isSelected ? 16 : 6)
        .animation(.spring(duration: 0.3, bounce: 0.4), value: isSelected)
    }
}

private struct SportyClusterBubble: View {
    let count: Int

    var body: some View {
        Text(count, format: .number)
            .font(.title3.weight(.black).monospacedDigit())
            .foregroundStyle(Color.accent)
            .frame(width: 52, height: 52)
            .background(Color.black.opacity(0.85), in: .circle)
            .overlay(Circle().stroke(Color.accent, lineWidth: 3))
            .shadow(color: Color.accent.opacity(0.5), radius: 8)
    }
}

// MARK: - Carousel

private struct SportyCarousel: View {
    let parks: [MapLookPark]
    @Binding var selectedID: Int?

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(parks) { park in
                    SportyCard(park: park, isSelected: park.id == selectedID)
                        .containerRelativeFrame(.horizontal) { width, _ in width * 0.82 }
                        .id(park.id)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $selectedID, anchor: .center)
        .scrollIndicators(.hidden)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 8)
    }
}

private struct SportyCard: View {
    let park: MapLookPark
    let isSelected: Bool

    var body: some View {
        let distance = park.distance(from: MapLookSampleData.userLocation)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(MapLookFormat.distance(distance))
                    .font(.title.weight(.black).italic().monospacedDigit())
                    .foregroundStyle(Color.accent)
                Text(MapLookFormat.walk(distance))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Label(MapLookFormat.rating(park.rating), systemImage: "star.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }
            Text(park.name.uppercased())
                .font(.headline.weight(.heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
            HStack(spacing: 8) {
                ForEach(park.equipment) { item in
                    Image(systemName: item.symbol)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(width: 32, height: 32)
                        .background(Color.accent, in: .circle)
                        .accessibilityLabel(item.title)
                }
                Spacer()
                Text(park.district)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(16)
        .background(Color.appBackground.opacity(0.92), in: .rect(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(isSelected ? Color.accent : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
        )
    }
}
#endif
