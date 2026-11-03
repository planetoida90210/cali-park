#if DEBUG
// PROTOTYPE — throwaway. Variant C "Lista najpierw": a short map header with bold accent
// dots, then a scrolling list of the nearest Parks with distance. The list is the hero.

import MapKit
import SwiftUI

struct MapLookListFirstVariant: View {
    @State private var position: MapCameraPosition
    @State private var selectedID: Int?
    @State private var filter: MapLookEquipment?

    init(initialSelection: Int?) {
        let selected = initialSelection.flatMap { id in MapLookSampleData.parks.first { $0.id == id } }
        let region = selected.map {
            MKCoordinateRegion(center: $0.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025))
        } ?? MKCoordinateRegion(center: MapLookSampleData.userLocation, span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06))
        _position = State(initialValue: .region(region))
        _selectedID = State(initialValue: selected?.id)
    }

    private var visibleParks: [MapLookPark] {
        let sorted = MapLookSampleData.sortedByDistance()
        guard let filter else { return sorted }
        return sorted.filter { $0.equipment.contains(filter) }
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                Map(position: $position) {
                    Annotation("Tu jesteś", coordinate: MapLookSampleData.userLocation, anchor: .center) {
                        MapLookUserDot()
                    }
                    .annotationTitles(.hidden)

                    ForEach(visibleParks) { park in
                        Annotation(park.name, coordinate: park.coordinate, anchor: .center) {
                            Button {
                                select(park)
                                withAnimation { proxy.scrollTo(park.id, anchor: .top) }
                            } label: {
                                ListFirstDot(park: park, isSelected: park.id == selectedID)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(park.name)
                        }
                        .annotationTitles(.hidden)
                    }
                }
                .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
                .mapControls {}
                .containerRelativeFrame(.vertical) { height, _ in height * 0.36 }
                .overlay(alignment: .bottom) {
                    LinearGradient(colors: [.clear, Color.appBackground], startPoint: .top, endPoint: .bottom)
                        .frame(height: 36)
                        .allowsHitTesting(false)
                }

                ListFirstHeader(filter: $filter, count: visibleParks.count)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(visibleParks.enumerated()), id: \.element.id) { index, park in
                            Button {
                                select(park)
                            } label: {
                                ListFirstRow(rank: index + 1, park: park, isSelected: park.id == selectedID)
                            }
                            .buttonStyle(.plain)
                            .id(park.id)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .background(Color.appBackground)
            .onAppear {
                if let selectedID { proxy.scrollTo(selectedID, anchor: .top) }
            }
        }
    }

    private func select(_ park: MapLookPark) {
        selectedID = park.id
        withAnimation(.smooth) {
            position = .region(MKCoordinateRegion(
                center: park.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
            ))
        }
    }
}

// MARK: - Pin

private struct ListFirstDot: View {
    let park: MapLookPark
    let isSelected: Bool

    var body: some View {
        if isSelected {
            Text(park.name)
                .font(.caption.weight(.bold))
                .foregroundStyle(.black)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.accent, in: .capsule)
                .overlay(Capsule().stroke(.black, lineWidth: 2))
                .shadow(color: Color.accent.opacity(0.6), radius: 8)
        } else {
            Circle()
                .fill(Color.accent)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(.black, lineWidth: 2.5))
                .padding(8) // larger tap target
                .contentShape(.circle)
        }
    }
}

// MARK: - Header

private struct ListFirstHeader: View {
    @Binding var filter: MapLookEquipment?
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("W pobliżu")
                    .font(.title1)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(MapLookFormat.parks(count))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            Picker("Sprzęt", selection: $filter) {
                Text("Wszystkie").tag(MapLookEquipment?.none)
                ForEach([MapLookEquipment.pullUpBar, .parallelBars, .rings]) { item in
                    Text(item.title).tag(Optional(item))
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Row

private struct ListFirstRow: View {
    let rank: Int
    let park: MapLookPark
    let isSelected: Bool

    var body: some View {
        let distance = park.distance(from: MapLookSampleData.userLocation)
        HStack(alignment: .center, spacing: 14) {
            Text(rank, format: .number.precision(.integerLength(2)))
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(isSelected ? Color.accent : Color.textTertiary)
                .frame(width: 26, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(park.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(park.district)
                    Text("·")
                    Label(MapLookFormat.rating(park.rating), systemImage: "star.fill")
                        .labelStyle(.titleAndIcon)
                    if park.isLit {
                        Image(systemName: "lightbulb.fill")
                            .accessibilityLabel("Oświetlony")
                    }
                }
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                HStack(spacing: 10) {
                    ForEach(park.equipment) { item in
                        Image(systemName: item.symbol)
                            .accessibilityLabel(item.title)
                    }
                }
                .font(.footnote)
                .foregroundStyle(Color.accent.opacity(0.9))
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(MapLookFormat.distance(distance))
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(isSelected ? Color.accent : Color.textPrimary)
                Text(MapLookFormat.walk(distance))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(isSelected ? Color.componentBackground : Color.clear)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.accent)
                .frame(width: 3)
                .opacity(isSelected ? 1 : 0)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.divider)
                .frame(height: 0.5)
                .padding(.leading, 56)
        }
        .contentShape(.rect)
    }
}
#endif
