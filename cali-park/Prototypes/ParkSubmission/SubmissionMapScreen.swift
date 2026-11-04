#if DEBUG
// PROTOTYPE — throwaway. Variant-A map with the "Dodaj Park" entry, pin placement and the
// duplicate warning ("Ten Park już jest obok").

import MapKit
import SwiftUI

struct SubmissionMapScreen: View {
    @Bindable var model: ParkSubmissionPrototypeModel
    @State private var position: MapCameraPosition
    @State private var span: MKCoordinateSpan

    init(model: ParkSubmissionPrototypeModel) {
        self.model = model
        let start: MKCoordinateRegion
        if let target = model.cameraTarget {
            start = MKCoordinateRegion(center: target, span: Self.placingSpan)
        } else if model.mapPhase == .placing {
            start = MKCoordinateRegion(center: model.draft.coordinate, span: Self.placingSpan)
        } else {
            start = MKCoordinateRegion(
                center: SubmissionSampleData.userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
        }
        _position = State(initialValue: .region(start))
        _span = State(initialValue: start.span)
    }

    static let placingSpan = MKCoordinateSpan(latitudeDelta: 0.0035, longitudeDelta: 0.0035)

    private var isPlacing: Bool { model.mapPhase == .placing }

    private var clusters: [MapLookCluster] {
        let others = MapLookSampleData.parks.filter { $0.id != model.openedPark?.id }
        var result = MapLookClustering.clusters(for: others, span: span)
        if let opened = model.openedPark { result.append(MapLookCluster(parks: [opened])) }
        return result
    }

    var body: some View {
        Map(position: $position) {
            Annotation("Tu jesteś", coordinate: SubmissionSampleData.userLocation, anchor: .center) {
                MapLookUserDot()
            }
            .annotationTitles(.hidden)

            ForEach(clusters) { cluster in
                if cluster.isSingle, let park = cluster.parks.first {
                    Annotation(park.name, coordinate: park.coordinate, anchor: .bottom) {
                        SubmissionParkPin(equipment: park.headlineEquipment, isSelected: park.id == model.openedPark?.id)
                            .opacity(isPlacing ? 0.55 : 1)
                    }
                    .annotationTitles(isPlacing ? .automatic : .hidden)
                } else {
                    Annotation(MapLookFormat.parks(cluster.parks.count), coordinate: cluster.coordinate, anchor: .center) {
                        SubmissionClusterBubble(count: cluster.parks.count)
                    }
                    .annotationTitles(.hidden)
                }
            }

            if isPlacing {
                MapCircle(center: model.draft.coordinate, radius: SubmissionSampleData.duplicateRadius)
                    .foregroundStyle(Color.accent.opacity(0.08))
                    .stroke(Color.accent.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                Annotation("Nowy Park", coordinate: model.draft.coordinate, anchor: .bottom) {
                    SubmissionNewPin()
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .continuous) { context in
            if isPlacing { model.movePin(to: context.region.center) }
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            span = context.region.span
        }
        .onChange(of: model.cameraRequest) {
            guard let target = model.cameraTarget else { return }
            withAnimation(.smooth) {
                position = .region(MKCoordinateRegion(center: target, span: Self.placingSpan))
            }
        }
        .safeAreaInset(edge: .top) {
            if isPlacing {
                PlacingHint()
            } else {
                SubmissionMapTopBar { model.isMinePresented = true }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Group {
                if isPlacing {
                    PlacingCard(model: model)
                } else if let park = model.openedPark {
                    OpenedParkCard(park: park) { model.openedPark = nil }
                } else {
                    AddParkButton { model.startAdding() }
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.smooth, value: isPlacing)
        .animation(.smooth, value: model.openedPark)
        .sheet(item: $model.duplicate) { park in
            DuplicateWarningSheet(park: park, pin: model.draft.coordinate, model: model)
        }
    }
}

// MARK: - Top bar

private struct SubmissionMapTopBar: View {
    let onMine: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                Text("Szukaj Parku lub dzielnicy")
                Spacer()
            }
            .foregroundStyle(Color.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .mapLookGlass(in: .capsule)

            Button("Moje zgłoszenia", systemImage: "tray.full", action: onMine)
                .labelStyle(.iconOnly)
                .font(.appTitle3)
                .foregroundStyle(Color.accent)
                .frame(width: 46, height: 46)
                .mapLookGlass(in: .circle)
        }
        .padding(.horizontal)
    }
}

private struct PlacingHint: View {
    var body: some View {
        Label("Przesuń mapę, aż pinezka stanie przy drążkach", systemImage: "hand.draw")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .mapLookGlass(in: .capsule)
            .padding(.horizontal)
    }
}

// MARK: - Bottom

private struct AddParkButton: View {
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button("Dodaj Park", systemImage: "plus", action: action)
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.accent, in: .capsule)
                .shadow(color: .black.opacity(0.5), radius: 8, y: 3)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

private struct PlacingCard: View {
    @Bindable var model: ParkSubmissionPrototypeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gdzie jest ten Park?")
                    .font(.appTitle3.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Postaw pinezkę dokładnie przy sprzęcie, nie przy wejściu do parku. Kropka to Twoja lokalizacja.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            HStack(spacing: 10) {
                Button("Anuluj") { model.cancelAdding() }
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1), in: .capsule)
                Button {
                    model.confirmPin()
                } label: {
                    Text("Tu jest Park")
                        .frame(maxWidth: .infinity)
                }
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.vertical, 12)
                .background(Color.accent, in: .capsule)
            }
        }
        .padding(16)
        .mapLookGlass(in: .rect(cornerRadius: 28))
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}

private struct OpenedParkCard: View {
    let park: MapLookPark
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(park.name)
                        .font(.appTitle3.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(park.district)
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
            EquipmentRow(equipment: park.equipment)
            HStack {
                Button("Coś się nie zgadza?", systemImage: "exclamationmark.bubble") {}
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Button("Prowadź", systemImage: "figure.walk") {}
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accent, in: .capsule)
            }
        }
        .padding(16)
        .mapLookGlass(in: .rect(cornerRadius: 28))
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}

/// Chips for the map-look equipment of a known Park.
struct EquipmentRow: View {
    let equipment: [MapLookEquipment]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(equipment) { item in
                Label(item.title, systemImage: item.symbol)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08), in: .capsule)
            }
        }
        .foregroundStyle(Color.textPrimary)
    }
}

// MARK: - Duplicate warning

private struct DuplicateWarningSheet: View {
    let park: MapLookPark
    let pin: CLLocationCoordinate2D
    let model: ParkSubmissionPrototypeModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Ten Park już jest obok", systemImage: "exclamationmark.triangle.fill")
                    .font(.appTitle2.weight(.bold))
                    .foregroundStyle(Color.textPrimary)
                    .symbolRenderingMode(.multicolor)
                Text("Twoja pinezka jest \(SubmissionFormat.meters(park.distance(from: pin))) od Parku, który już mamy na mapie. Sprawdź, czy to nie to samo miejsce.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)

                VStack(alignment: .leading, spacing: 10) {
                    Text(park.name)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    Text("\(park.district) · \(SubmissionFormat.meters(park.distance(from: pin))) od pinezki")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    EquipmentRow(equipment: park.equipment)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.componentBackground, in: .rect(cornerRadius: 18))

                Button {
                    model.openDuplicate()
                } label: {
                    Text("To ten. Otwórz Park")
                        .frame(maxWidth: .infinity)
                }
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.vertical, 14)
                .background(Color.accent, in: .capsule)

                Button {
                    model.continueDespiteDuplicate()
                } label: {
                    Text("To inny Park, dodaj nowy")
                        .frame(maxWidth: .infinity)
                }
                .font(.headline)
                .foregroundStyle(Color.accent)
                .padding(.vertical, 14)
                .overlay(Capsule().stroke(Color.accent, lineWidth: 1))

                Text("Wybierz „inny Park” tylko wtedy, gdy to osobne miejsce, np. drugi zestaw drążków po drugiej stronie boiska.")
                    .font(.footnote)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.appBackground)
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Pins

private struct SubmissionParkPin: View {
    let equipment: MapLookEquipment
    let isSelected: Bool

    var body: some View {
        VStack(spacing: -3) {
            Image(systemName: equipment.symbol)
                .font(isSelected ? .body.weight(.semibold) : .footnote.weight(.semibold))
                .foregroundStyle(isSelected ? Color.black : Color.accent)
                .frame(width: isSelected ? 44 : 34, height: isSelected ? 44 : 34)
                .background(isSelected ? Color.accent : Color.componentBackground, in: .circle)
                .overlay(Circle().stroke(Color.accent.opacity(isSelected ? 0 : 0.85), lineWidth: 1.5))
            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption2)
                .foregroundStyle(isSelected ? Color.accent : Color.componentBackground)
        }
        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
    }
}

private struct SubmissionClusterBubble: View {
    let count: Int

    var body: some View {
        Text(count, format: .number)
            .font(.subheadline.weight(.bold).monospacedDigit())
            .foregroundStyle(Color.accent)
            .frame(width: 30 + CGFloat(min(count, 8)) * 3, height: 30 + CGFloat(min(count, 8)) * 3)
            .background(Color.componentBackground.opacity(0.95), in: .circle)
            .overlay(Circle().stroke(Color.accent.opacity(0.35), lineWidth: 5))
            .overlay(Circle().stroke(Color.accent, lineWidth: 1))
    }
}

/// The pin being placed: bright, with a plus, so it never reads as an existing Park.
struct SubmissionNewPin: View {
    var body: some View {
        VStack(spacing: -4) {
            Image(systemName: "plus")
                .font(.appTitle3.weight(.bold))
                .foregroundStyle(.black)
                .frame(width: 48, height: 48)
                .background(Color.accent, in: .circle)
                .overlay(Circle().stroke(.white, lineWidth: 3))
            Image(systemName: "arrowtriangle.down.fill")
                .font(.footnote)
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.6), radius: 6, y: 3)
    }
}
#endif
