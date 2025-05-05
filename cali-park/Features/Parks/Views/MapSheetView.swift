import SwiftUI
import MapKit

struct MapSheetView: View {
    @ObservedObject var viewModel: ParksViewModel
    // Modern camera position (iOS 17+)
    @available(iOS 17.0, *)
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    // Legacy region (iOS 14-16)
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Environment(\.dismiss) var dismiss

    init(viewModel: ParksViewModel) {
        self.viewModel = viewModel
        // Pick first park as initial center (nearest already sorted by VM)
        if let first = viewModel.parks.first {
            _region = State(initialValue: MKCoordinateRegion(center: first.coordinate,
                                                              span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
            if #available(iOS 17.0, *) {
                _cameraPosition = State(initialValue: .camera(MapCamera(centerCoordinate: first.coordinate, distance: 2000)))
            }
        }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Mapa siłowni")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Zamknij") { dismiss() }
                    }
                }
        }
    }

    // MARK: - Map Content (conditional)
    @ViewBuilder
    private var content: some View {
        if #available(iOS 17.0, *) {
            Map(position: $cameraPosition) {
                ForEach(viewModel.parks) { park in
                    Marker(park.name, coordinate: park.coordinate)
                        .tint(Color.accent)
                }
            }
            .mapControls {
                MapCompass()
                MapUserLocationButton()
            }
        } else {
            // Fallback map for iOS 14-16
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: viewModel.parks) { park in
                MapMarker(coordinate: park.coordinate, tint: Color.accent)
            }
        }
    }
}

struct MapSheetView_Previews: PreviewProvider {
    static var previews: some View {
        MapSheetView(viewModel: ParksViewModel())
    }
} 