import MapKit
import SwiftUI

// MARK: - ParkMapContent
/// Variant A map: Park pins and cluster bubbles, the user's position when
/// allowed, and the OpenStreetMap credit.
struct ParkMapContent: View {
    @Bindable var viewModel: ParkMapViewModel

    var body: some View {
        Map(position: $viewModel.position) {
            if viewModel.authorization == .authorized {
                UserAnnotation()
            }
            ForEach(viewModel.clusters) { cluster in
                if cluster.isSingle, let park = cluster.parks.first {
                    Annotation(park.displayName, coordinate: park.coordinate, anchor: .bottom) {
                        Button {
                            withAnimation(.smooth) { viewModel.select(park) }
                        } label: {
                            ParkPin(equipment: park.headlineEquipment,
                                    isSelected: park.id == viewModel.selectedParkID,
                                    isFavorite: viewModel.isFavorite(park))
                                // Markers past XXXL would cover each other and the map.
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(park.displayName)
                        .accessibilityValue(viewModel.isFavorite(park) ? String(localized: "Ulubiony") : "")
                        .accessibilityHint("Otwiera kartę Parku")
                        .accessibilityAddTraits(park.id == viewModel.selectedParkID ? .isSelected : [])
                    }
                    .annotationTitles(.hidden)
                } else {
                    Annotation(ParkFormat.parkCount(cluster.parks.count), coordinate: cluster.coordinate, anchor: .center) {
                        Button {
                            withAnimation(.smooth) { viewModel.zoom(into: cluster) }
                        } label: {
                            ParkClusterBubble(count: cluster.parks.count)
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(ParkFormat.parkCount(cluster.parks.count))
                        .accessibilityHint("Przybliża mapę")
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls {
            if viewModel.authorization == .authorized {
                MapUserLocationButton()
            }
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.cameraDidChange(to: context.region)
        }
        .overlay(alignment: .bottomTrailing) {
            OSMAttributionLink()
                .padding(.trailing, 12)
                .padding(.bottom, 8)
        }
    }
}
