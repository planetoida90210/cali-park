#if DEBUG
// PROTOTYPE — throwaway. The Park card sheet: compact header at the low detent,
// full card at the large detent, sections in the order picked in the switcher.

import SwiftUI

struct ParkCardSheet: View {
    @Bindable var model: ParkCardPrototypeModel
    let hidesSwitcher: Bool

    var body: some View {
        Group {
            if let park = model.selectedPark {
                content(for: park)
            }
        }
        .presentationDetents([ParkCardPrototypeModel.compactDetent, .large], selection: $model.detent)
        .presentationBackgroundInteraction(.enabled(upThrough: ParkCardPrototypeModel.compactDetent))
        .presentationContentInteraction(.resizes)
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
        .preferredColorScheme(.dark)
        .sheet(item: $model.modal) { modal in
            ParkCardModalView(model: model, modal: modal)
        }
        .fullScreenCover(item: $model.viewer) { item in
            PhotoViewer(model: model, startID: item.startID)
        }
        .task {
            guard let name = model.pendingModal else { return }
            model.pendingModal = nil
            try? await Task.sleep(for: .milliseconds(800))
            model.apply(modal: name)
        }
    }

    private func content(for park: CardPark) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    CompactParkHeader(park: park, model: model)
                        .padding(.bottom, 20)

                    if let correction = park.correction {
                        PendingCorrectionBanner(correction: correction) {
                            model.withdrawCorrection()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }

                    VStack(alignment: .leading, spacing: 28) {
                        ForEach(model.order.sections) { section in
                            sectionView(section, park: park)
                                .id(section)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.hidden)
            // Keeps a section scrolled to the top clear of the drag indicator.
            .safeAreaPadding(.top, 14)
            .safeAreaInset(edge: .bottom) {
                if model.isFull && !hidesSwitcher {
                    ParkCardSwitcherPill(model: model)
                        .padding(.bottom, 4)
                }
            }
            .task {
                guard let target = model.scrollTarget else { return }
                try? await Task.sleep(for: .milliseconds(600))
                proxy.scrollTo(target, anchor: .top)
                model.scrollTarget = nil
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ section: CardSection, park: CardPark) -> some View {
        switch section {
        case .photos: CardPhotosSection(park: park, model: model)
        case .equipment: EquipmentCardSection(park: park, model: model)
        case .verification: VerificationSection(park: park)
        case .weather: WeatherSection(weather: park.weather)
        case .reviews: ReviewsSection(park: park, model: model)
        case .facts: FactsSection(park: park)
        case .footer: CardFooter(park: park, model: model)
        }
    }
}

// MARK: - Compact header

/// Everything that has to fit in the compact detent: name, badge, distance, rating,
/// equipment glyphs and the two buttons.
struct CompactParkHeader: View {
    let park: CardPark
    let model: ParkCardPrototypeModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(park.displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(park.locality) · \(MapLookFormat.distance(park.distance)) · \(MapLookFormat.walk(park.distance))")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: 0)
                Button("Zamknij", systemImage: "xmark") {
                    model.select(nil)
                }
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.08), in: .circle)
            }

            HStack(spacing: 6) {
                VerificationBadge(verification: park.verification)
                if park.correction != nil {
                    Label("Twoja poprawka czeka", systemImage: "clock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15), in: .capsule)
                }
            }

            HStack(spacing: 12) {
                InlineRating(park: park)
                Spacer(minLength: 0)
                EquipmentGlyphs(park: park)
            }

            HStack(spacing: 10) {
                Button {
                    openURL(ParkCardNavigation.appleMapsURL(for: park))
                } label: {
                    Label("Nawiguj", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .frame(maxWidth: .infinity)
                }
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.vertical, 12)
                .background(Color.accent, in: .capsule)

                if !model.isFull {
                    Button {
                        withAnimation(.smooth) { model.detent = .large }
                    } label: {
                        Label("Szczegóły", systemImage: "chevron.up")
                            .frame(maxWidth: .infinity)
                    }
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1), in: .capsule)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

enum ParkCardNavigation {
    /// Walking directions in Apple Maps. The URL scheme avoids MKPlacemark, which iOS 26 deprecates.
    static func appleMapsURL(for park: CardPark) -> URL {
        var components = URLComponents()
        components.scheme = "maps"
        components.queryItems = [
            URLQueryItem(name: "daddr", value: "\(park.latitude),\(park.longitude)"),
            URLQueryItem(name: "dirflg", value: "w"),
        ]
        return components.url ?? URL(string: "maps://")!
    }
}

struct VerificationBadge: View {
    let verification: CardVerification

    var body: some View {
        let isVerified = if case .verified = verification { true } else { false }
        Label(verification.title, systemImage: verification.symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isVerified ? Color.black : Color.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isVerified ? Color.accent : Color.white.opacity(0.1), in: .capsule)
    }
}

private struct InlineRating: View {
    let park: CardPark

    var body: some View {
        if let average = park.averageRating {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.accent)
                Text(ParkCardFormat.rating(average))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Text("· \(ParkCardFormat.reviews(park.reviews.count))")
                    .foregroundStyle(Color.textSecondary)
            }
            .font(.subheadline)
        } else {
            Label("Brak opinii", systemImage: "star")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
    }
}

private struct EquipmentGlyphs: View {
    let park: CardPark
    private let limit = 4

    var body: some View {
        if park.equipment.isEmpty {
            Label("Sprzęt nieznany", systemImage: "questionmark.circle")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        } else {
            HStack(spacing: 4) {
                ForEach(park.equipment.prefix(limit)) { item in
                    Image(systemName: item.type.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.accent)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.08), in: .circle)
                        .accessibilityLabel(item.type.title)
                }
                if park.equipment.count > limit {
                    Text("+\(park.equipment.count - limit)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
}

// MARK: - Pending correction

private struct PendingCorrectionBanner: View {
    let correction: CardCorrection
    let onWithdraw: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Twoja poprawka czeka na Moderatora", systemImage: "clock.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
            Text("„\(correction.summary)”")
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
            Text("Wysłana \(ParkCardFormat.relative(correction.sentAt)) jako \(ParkCardSampleData.nickname). Zwykle odpowiadamy w 24 h. Do decyzji karta pokazuje dane sprzed poprawki.")
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
            Button("Wycofaj poprawkę", action: onWithdraw)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.orange.opacity(0.12), in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.orange.opacity(0.35), lineWidth: 1))
    }
}

// MARK: - Shared section chrome

struct CardSectionHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Spacer()
            trailing
        }
    }
}

extension CardSectionHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// Small outlined action used in section headers ("Dodaj zdjęcie", "Napisz opinię").
struct CardHeaderAction: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accent)
        }
    }
}

/// Dashed placeholder for a section with no data yet.
struct EmptySectionBox<Actions: View>: View {
    let symbol: String
    let title: String
    let message: String
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            actions
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
    }
}
#endif
