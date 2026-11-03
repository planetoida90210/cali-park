#if DEBUG
// PROTOTYPE — throwaway. Sections of the full Park card.

import SwiftUI

// MARK: - Photos

struct CardPhotosSection: View {
    let park: CardPark
    let model: ParkCardPrototypeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardSectionHeader(
                title: "Zdjęcia",
                subtitle: park.photos.isEmpty ? nil : ParkCardFormat.photos(park.photos.count)
            ) {
                if !park.photos.isEmpty {
                    CardHeaderAction(title: "Dodaj zdjęcie", symbol: "camera") { model.modal = .addPhoto }
                }
            }
            .padding(.horizontal, 20)

            if park.photos.isEmpty {
                EmptySectionBox(
                    symbol: "photo.on.rectangle",
                    title: "Nikt jeszcze nie dodał zdjęcia",
                    message: "Zdjęcie z miejsca pokazuje innym, jaki tu jest sprzęt. Robisz je aparatem w apce, na miejscu."
                ) {
                    Button {
                        model.modal = .addPhoto
                    } label: {
                        Label("Dodaj zdjęcie", systemImage: "camera.fill")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accent, in: .capsule)
                }
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(Array(park.photos.enumerated()), id: \.element.id) { index, photo in
                            PhotoThumbnail(photo: photo, isCover: index == 0) {
                                model.viewer = PhotoViewerItem(startID: photo.id)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

private struct PhotoThumbnail: View {
    let photo: CardPhoto
    let isCover: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SamplePhotoView(index: photo.scene)
                .frame(width: isCover ? 240 : 130, height: 170)
                .overlay(alignment: .bottomLeading) {
                    if photo.isTeamPhoto {
                        PhotoTag(text: isCover ? "Ekipa CaliPark" : "Ekipa", symbol: "checkmark.seal.fill", tint: .accent)
                    } else if photo.isPendingModeration {
                        PhotoTag(text: isCover ? "Czeka na moderację" : "Czeka", symbol: "clock", tint: .orange)
                    }
                }
                .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(photo.isTeamPhoto ? "Zdjęcie ekipy CaliPark" : "Zdjęcie od \(photo.author)")
    }
}

struct PhotoTag: View {
    let text: String
    let symbol: String
    let tint: Color

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.black.opacity(0.7), in: .capsule)
            .padding(8)
    }
}

// MARK: - Equipment

struct EquipmentCardSection: View {
    let park: CardPark
    let model: ParkCardPrototypeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardSectionHeader(title: "Sprzęt")

            if park.equipment.isEmpty {
                EmptySectionBox(
                    symbol: "questionmark.circle",
                    title: "Sprzęt nieznany",
                    message: "OpenStreetMap mówi tylko, że to miejsce do kalisteniki. Nie wiemy, ile jest drążków ani jakiej są wysokości."
                ) {
                    Button {
                        model.modal = .correction(.equipment)
                    } label: {
                        Label("Uzupełnij sprzęt", systemImage: "plus.circle.fill")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accent)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(park.equipment.enumerated()), id: \.element.id) { index, item in
                        if index > 0 { Divider().overlay(Color.divider) }
                        EquipmentLine(
                            item: item,
                            isAffectedByCorrection: park.correction?.affected.contains(item.type) == true
                        )
                    }
                }
                .padding(.horizontal, 14)
                .background(Color.componentBackground, in: .rect(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 6) {
                    if park.supportsFlag {
                        Label("Nadaje się do flagi: jest pionowy drążek albo drabinka", systemImage: "flag.fill")
                    }
                    if park.hasMachines {
                        Label("Obok są też maszyny (np. orbitrek). Nie liczymy ich jako sprzętu.", systemImage: "info.circle")
                    }
                }
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, 20)
    }
}

private struct EquipmentLine: View {
    let item: CardEquipment
    let isAffectedByCorrection: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.accent)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.08), in: .circle)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.type.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                    if let count = ParkCardFormat.count(item.count) {
                        Text(count)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                if !item.heights.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(BarHeight.allCases) { height in
                            let has = item.heights.contains(height)
                            Text(height.title.lowercased())
                                .font(.caption.weight(.medium))
                                .foregroundStyle(has ? Color.textPrimary : Color.textTertiary)
                                .strikethrough(!has, color: Color.textTertiary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(has ? 0.12 : 0.03), in: .capsule)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Wysokości: \(item.heights.map { $0.title.lowercased() }.joined(separator: ", "))")
                }
            }
            Spacer(minLength: 0)
            if isAffectedByCorrection {
                Label("Zgłoszona zmiana", systemImage: "clock")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Verification

struct VerificationSection: View {
    let park: CardPark

    private var explanation: String {
        switch park.verification {
        case .verified(let date):
            "Ekipa CaliPark była tu \(ParkCardFormat.day(date)) i sprawdziła sprzęt na miejscu. Zdjęcia ekipy są okładką."
        case .community:
            "Park dodała osoba ze Społeczności, ze zdjęciem z miejsca. Moderator sprawdził Zgłoszenie, ale ekipa jeszcze tu nie była."
        case .osm:
            "Dane pochodzą z OpenStreetMap. Nikt z CaliPark jeszcze ich nie sprawdził, więc mogą być nieaktualne."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CardSectionHeader(title: "Skąd te dane")
            VStack(alignment: .leading, spacing: 8) {
                VerificationBadge(verification: park.verification)
                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let confirmed = park.lastConfirmedAt {
                    Text("Ostatnio potwierdzone: \(ParkCardFormat.month(confirmed))")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                } else {
                    Text("Nikt jeszcze nie potwierdził tych danych na miejscu.")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.componentBackground, in: .rect(cornerRadius: 18))
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Weather

struct WeatherSection: View {
    let weather: CardWeather

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardSectionHeader(title: "Pogoda", subtitle: "Przykładowe dane. Docelowo WeatherKit od Apple.")
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    Image(systemName: weather.symbol)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 34))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(weather.temperature)° · \(weather.condition)")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                        Text("Odczuwalna \(weather.feelsLike)° · wiatr \(weather.windKmh) km/h")
                            .font(.footnote)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                Label(weather.hint, systemImage: "umbrella")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.accent)
                HStack(spacing: 0) {
                    ForEach(weather.hours) { hour in
                        VStack(spacing: 6) {
                            Text("\(hour.hour):00")
                                .font(.caption2)
                                .foregroundStyle(Color.textSecondary)
                            Image(systemName: hour.symbol)
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 18))
                                .frame(height: 22)
                            Text("\(hour.temperature)°")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.textPrimary)
                            Text("\(hour.rainChance)%")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(hour.rainChance >= 50 ? Color.cyan : Color.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                Text(" Pogoda · Źródła danych")
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(14)
            .background(Color.componentBackground, in: .rect(cornerRadius: 18))
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Reviews

struct ReviewsSection: View {
    let park: CardPark
    @Bindable var model: ParkCardPrototypeModel
    private let previewCount = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardSectionHeader(title: "Opinie") {
                if !park.reviews.isEmpty {
                    CardHeaderAction(title: "Napisz opinię", symbol: "square.and.pencil") { model.modal = .review }
                }
            }

            if let average = park.averageRating {
                RatingSummary(park: park, average: average)
                let visible = model.showsAllReviews ? park.reviews : Array(park.reviews.prefix(previewCount))
                VStack(spacing: 0) {
                    ForEach(Array(visible.enumerated()), id: \.element.id) { index, review in
                        if index > 0 { Divider().overlay(Color.divider) }
                        ReviewRow(review: review) {
                            model.modal = .report(.review(review))
                        }
                    }
                }
                if park.reviews.count > previewCount && !model.showsAllReviews {
                    Button("Pokaż wszystkie (\(park.reviews.count))") {
                        withAnimation(.smooth) { model.showsAllReviews = true }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accent)
                }
            } else {
                EmptySectionBox(
                    symbol: "star.bubble",
                    title: "Brak opinii",
                    message: "Trenowałeś tu? Oceń Park i napisz, jak jest: wysokość drążków, nawierzchnia, tłok."
                ) {
                    Button {
                        model.modal = .review
                    } label: {
                        Label("Napisz pierwszą opinię", systemImage: "square.and.pencil")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accent)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

private struct RatingSummary: View {
    let park: CardPark
    let average: Double

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(spacing: 2) {
                Text(ParkCardFormat.rating(average))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                StarRow(rating: Int(average.rounded()), size: 12)
                Text(ParkCardFormat.reviews(park.reviews.count))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            VStack(spacing: 4) {
                ForEach((1...5).reversed(), id: \.self) { stars in
                    HStack(spacing: 6) {
                        Text("\(stars)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: 10)
                        GeometryReader { proxy in
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.accent)
                                        .frame(width: proxy.size.width * park.ratingShare(of: stars))
                                }
                        }
                        .frame(height: 6)
                    }
                }
            }
            .accessibilityHidden(true)
        }
        .padding(14)
        .background(Color.componentBackground, in: .rect(cornerRadius: 18))
    }
}

struct StarRow: View {
    let rating: Int
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(star <= rating ? Color.accent : Color.textTertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rating) na 5")
    }
}

private struct ReviewRow: View {
    let review: CardReview
    let onReport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(review.author)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                if review.isMine {
                    Text("Ty")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accent, in: .capsule)
                }
                StarRow(rating: review.rating, size: 10)
                Text(ParkCardFormat.relative(review.date))
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
                Spacer(minLength: 0)
                if !review.isMine {
                    Menu {
                        Button("Zgłoś opinię", systemImage: "flag", action: onReport)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: 28, height: 28)
                            .contentShape(.rect)
                    }
                    .accessibilityLabel("Więcej opcji opinii")
                }
            }
            if let text = review.text {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Color.textPrimary.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Sama ocena, bez komentarza")
                    .font(.footnote.italic())
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Facts (012 §2, optional)

struct FactsSection: View {
    let park: CardPark

    private func yesNo(_ value: Bool?, yes: String, no: String) -> String? {
        value.map { $0 ? yes : no }
    }

    private var nearby: String? {
        var items: [String] = []
        if park.nearbyWater { items.append("woda pitna") }
        if park.nearbyToilets { items.append("toaleta") }
        return items.isEmpty ? nil : items.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardSectionHeader(title: "Szczegóły")
            VStack(spacing: 0) {
                FactRow(symbol: "square.grid.3x3.fill", label: "Nawierzchnia", value: park.surface?.title)
                Divider().overlay(Color.divider)
                FactRow(symbol: "lightbulb.fill", label: "Oświetlenie", value: yesNo(park.lit, yes: "Tak", no: "Nie"))
                Divider().overlay(Color.divider)
                FactRow(symbol: "umbrella.fill", label: "Zadaszenie", value: yesNo(park.covered, yes: "Tak", no: "Nie"))
                Divider().overlay(Color.divider)
                FactRow(symbol: "person.2.fill", label: "Dostęp", value: park.access.title)
                Divider().overlay(Color.divider)
                FactRow(symbol: "clock.fill", label: "Godziny", value: park.openingHours)
                Divider().overlay(Color.divider)
                FactRow(symbol: "drop.fill", label: "Do 150 m", value: nearby, missing: "Nic nie wiemy")
            }
            .padding(.horizontal, 14)
            .background(Color.componentBackground, in: .rect(cornerRadius: 18))
        }
        .padding(.horizontal, 20)
    }
}

private struct FactRow: View {
    let symbol: String
    let label: String
    let value: String?
    var missing = "Brak danych"

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 20)
            Text(label)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value ?? missing)
                .foregroundStyle(value == nil ? Color.textTertiary : Color.textPrimary)
        }
        .font(.subheadline)
        .padding(.vertical, 11)
    }
}

// MARK: - Footer: corrections, navigation, attribution

struct CardFooter: View {
    let park: CardPark
    let model: ParkCardPrototypeModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Button {
                    openURL(ParkCardNavigation.appleMapsURL(for: park))
                } label: {
                    Label("Nawiguj", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .frame(maxWidth: .infinity)
                }
                .foregroundStyle(.black)
                .background(Color.accent, in: .capsule)

                Button {
                    model.modal = .correction(nil)
                } label: {
                    Label("Zgłoś poprawkę", systemImage: "exclamationmark.bubble")
                        .frame(maxWidth: .infinity)
                }
                .foregroundStyle(Color.textPrimary)
                .background(Color.white.opacity(0.1), in: .capsule)
                .disabled(park.correction != nil)
            }
            .font(.subheadline.weight(.semibold))
            .buttonStyle(FooterButtonStyle())

            Text("Coś się nie zgadza? Poprawka trafia do Moderatora. Treści innych osób (zdjęcia, opinie) zgłaszasz przez ••• przy nich.")
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                if park.hasOSMData {
                    Link(destination: URL(string: "https://www.openstreetmap.org/copyright")!) {
                        Text("Dane Parku: © współtwórcy OpenStreetMap, licencja ODbL")
                            .underline()
                    }
                } else {
                    Text("Dane Parku: Społeczność CaliPark, licencja ODbL")
                }
                Text("Fakty o Parku są w otwartej bazie. Zdjęcia i opinie nie są jej częścią.")
            }
            .font(.caption)
            .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, 20)
    }
}

private struct FooterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
#endif
