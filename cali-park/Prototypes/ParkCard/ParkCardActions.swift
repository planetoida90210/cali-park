#if DEBUG
// PROTOTYPE — throwaway. Sheets opened from the Park card: correction (ticket 014),
// content report (DSA / App Store 1.2), review, add photo, and the photo viewer.
// Nothing is sent anywhere; actions only change the in-memory model.

import SwiftUI

struct ParkCardModalView: View {
    let model: ParkCardPrototypeModel
    let modal: ParkCardModal

    var body: some View {
        Group {
            switch modal {
            case .correction(let kind):
                if let park = model.selectedPark {
                    CorrectionSheet(model: model, park: park, initialKind: kind)
                }
            case .report(let target):
                ReportContentSheet(target: target)
            case .review:
                WriteReviewSheet(model: model)
            case .addPhoto:
                AddPhotoSheet(model: model)
            }
        }
        .preferredColorScheme(.dark)
        .presentationBackground(Color.appBackground)
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Correction (ticket 014)

private struct CorrectionSheet: View {
    let model: ParkCardPrototypeModel
    let park: CardPark
    @State private var path: [CorrectionKind]
    @Environment(\.dismiss) private var dismiss

    init(model: ParkCardPrototypeModel, park: CardPark, initialKind: CorrectionKind?) {
        self.model = model
        self.park = park
        _path = State(initialValue: initialKind.map { [$0] } ?? [])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    ForEach(CorrectionKind.allCases) { kind in
                        NavigationLink(value: kind) {
                            Label(kind.title, systemImage: kind.symbol)
                                .foregroundStyle(Color.textPrimary)
                        }
                    }
                } footer: {
                    Text("Poprawka trafia do Moderatora, tak jak Zgłoszenie nowego Parku. Do decyzji karta wygląda jak teraz.")
                }
                .listRowBackground(Color.componentBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Co się nie zgadza?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
            }
            .navigationDestination(for: CorrectionKind.self) { kind in
                CorrectionDetail(kind: kind, park: park) { correction in
                    model.sendCorrection(correction)
                    dismiss()
                }
            }
        }
    }
}

private struct CorrectionDetail: View {
    let kind: CorrectionKind
    let park: CardPark
    let onSend: (CardCorrection) -> Void

    @State private var equipment: Set<SubmissionEquipment>
    @State private var note = ""
    @State private var hasPhoto = false

    init(kind: CorrectionKind, park: CardPark, onSend: @escaping (CardCorrection) -> Void) {
        self.kind = kind
        self.park = park
        self.onSend = onSend
        _equipment = State(initialValue: Set(park.equipment.map(\.type)))
    }

    private var prompt: String {
        switch kind {
        case .equipment: "Zaznacz sprzęt, który jest teraz w Parku."
        case .gone: "Drążki zdemontowano albo teren jest zamknięty na stałe?"
        case .location: "W prawdziwej wersji przesuwasz pinezkę na mapie, jak w Zgłoszeniu."
        case .name: "Podaj oficjalną nazwę z tabliczki. Bez nazw wymyślonych."
        case .details: "Co się zmieniło: nawierzchnia, oświetlenie, zadaszenie albo dostęp?"
        case .other: "Opisz krótko, co jest nie tak."
        }
    }

    private var summary: String {
        switch kind {
        case .equipment:
            let titles = SubmissionEquipment.allCases.filter(equipment.contains).map(\.title)
            return "Sprzęt: " + (titles.isEmpty ? "brak" : titles.joined(separator: ", "))
        case .gone: return "Parku już nie ma"
        default:
            let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? kind.title : trimmed
        }
    }

    private var canSend: Bool {
        switch kind {
        case .equipment: equipment != Set(park.equipment.map(\.type))
        case .gone: true
        default: !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(prompt)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)

                switch kind {
                case .equipment:
                    FlowLayout(spacing: 8) {
                        ForEach(SubmissionEquipment.allCases) { item in
                            SelectableChip(title: item.title, symbol: item.symbol, isSelected: equipment.contains(item)) {
                                if equipment.contains(item) { equipment.remove(item) } else { equipment.insert(item) }
                            }
                        }
                    }
                case .gone:
                    Label("Moderator sprawdzi to na zdjęciu albo na miejscu, zanim zdejmie Park z mapy.", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                default:
                    TextField("Np. „Lampy nie działają od lata”", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                        .padding(12)
                        .background(Color.componentBackground, in: .rect(cornerRadius: 14))
                    Text("Widzi to tylko Moderator. Nie publikujemy tego tekstu.")
                        .font(.footnote)
                        .foregroundStyle(Color.textTertiary)
                }

                Button {
                    hasPhoto.toggle()
                } label: {
                    Label(hasPhoto ? "Zdjęcie dodane" : "Dodaj zdjęcie z miejsca (zalecane)",
                          systemImage: hasPhoto ? "checkmark.circle.fill" : "camera")
                        .frame(maxWidth: .infinity)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(hasPhoto ? Color.accent : Color.textPrimary)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08), in: .capsule)

                Text("Wysyłasz jako \(ParkCardSampleData.nickname). Moderator zwykle odpowiada w 24 h, a wynik zobaczysz na tej karcie.")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)

                Button {
                    var affected: Set<SubmissionEquipment> = []
                    if kind == .equipment {
                        affected = equipment.symmetricDifference(Set(park.equipment.map(\.type)))
                    }
                    onSend(CardCorrection(kind: kind, summary: summary, sentAt: ParkCardSampleData.now, affected: affected))
                } label: {
                    Text("Wyślij do moderacji")
                        .frame(maxWidth: .infinity)
                }
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.vertical, 14)
                .background(Color.accent.opacity(canSend ? 1 : 0.35), in: .capsule)
                .disabled(!canSend)
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Content report (DSA art. 16, App Store 1.2)

private enum ReportReason: String, CaseIterable, Identifiable {
    case illegal, abusive, spam, privacy, wrongPark, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .illegal: "Treść niezgodna z prawem"
        case .abusive: "Obraźliwa, nienawistna lub nękająca"
        case .spam: "Spam lub reklama"
        case .privacy: "Widać czyjąś twarz albo dane"
        case .wrongPark: "Nie z tego Parku"
        case .other: "Coś innego"
        }
    }

    /// DSA art. 16 asks for a substantiated explanation for illegal content.
    var needsExplanation: Bool { self == .illegal || self == .other }
}

private struct ReportContentSheet: View {
    let target: ReportTarget
    @State private var reason: ReportReason?
    @State private var explanation = ""
    @State private var email = ""
    @State private var hidesAuthor = false
    @State private var isSent = false
    @Environment(\.dismiss) private var dismiss

    private var noun: String {
        if case .photo = target { "zdjęcie" } else { "opinię" }
    }

    private var author: String {
        switch target {
        case .photo(let photo): photo.author
        case .review(let review): review.author
        }
    }

    private var canSend: Bool {
        guard let reason else { return false }
        return !reason.needsExplanation || !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if isSent {
                    sentView
                } else {
                    form
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Zgłoś \(noun)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isSent ? "Gotowe" : "Anuluj") { dismiss() }
                }
            }
        }
    }

    private var form: some View {
        List {
            Section("Dlaczego?") {
                ForEach(ReportReason.allCases) { item in
                    Button {
                        reason = item
                    } label: {
                        HStack {
                            Text(item.title).foregroundStyle(Color.textPrimary)
                            Spacer()
                            if reason == item {
                                Image(systemName: "checkmark").foregroundStyle(Color.accent)
                            }
                        }
                    }
                }
            }
            .listRowBackground(Color.componentBackground)

            if let reason {
                Section {
                    TextField(reason.needsExplanation ? "Wyjaśnij, dlaczego (wymagane)" : "Dodaj szczegóły (opcjonalnie)",
                              text: $explanation, axis: .vertical)
                        .lineLimit(2...5)
                    TextField("E-mail, żeby dostać decyzję (opcjonalnie)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                } footer: {
                    if reason == .illegal {
                        Text("Wysyłając, potwierdzasz, że zgłoszenie jest zgodne z Twoją najlepszą wiedzą (DSA art. 16).")
                    }
                }
                .listRowBackground(Color.componentBackground)

                Section {
                    Toggle("Ukryj treści od \(author)", isOn: $hidesAuthor)
                        .tint(Color.accent)
                } footer: {
                    Text("Tylko u Ciebie. Autor nie dostanie powiadomienia.")
                }
                .listRowBackground(Color.componentBackground)
            }

            Section {
                Button {
                    isSent = true
                } label: {
                    Text("Wyślij zgłoszenie")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .disabled(!canSend)
                .listRowBackground(Color.accent.opacity(canSend ? 1 : 0.35))
            } footer: {
                Text("Nie potrzebujesz Konta. Moderator sprawdzi zgłoszenie w ciągu 24 h.")
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var sentView: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.accent)
            Text("Dzięki, zgłoszenie wysłane")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.textPrimary)
            Text(hidesAuthor
                 ? "Moderator sprawdzi \(noun) w ciągu 24 h. Treści od \(author) są już u Ciebie ukryte."
                 : "Moderator sprawdzi \(noun) w ciągu 24 h. Jeśli podasz e-mail, napiszemy, co zdecydował.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Review

private struct WriteReviewSheet: View {
    let model: ParkCardPrototypeModel
    @State private var rating = 0
    @State private var text = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text(model.selectedPark?.displayName ?? "")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                HStack(spacing: 10) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            rating = star
                        } label: {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundStyle(star <= rating ? Color.accent : Color.textTertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(star) na 5")
                    }
                }
                TextField("Jak tu się trenuje? Wysokość drążków, nawierzchnia, tłok (opcjonalnie)", text: $text, axis: .vertical)
                    .lineLimit(4...8)
                    .padding(12)
                    .background(Color.componentBackground, in: .rect(cornerRadius: 14))
                Text("Publikujesz jako \(ParkCardSampleData.nickname). Opinia pojawi się od razu, a filtr i Moderator usuwają treści łamiące regulamin.")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Button {
                    model.addReview(rating: rating, text: text)
                    dismiss()
                } label: {
                    Text("Opublikuj opinię")
                        .frame(maxWidth: .infinity)
                }
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.vertical, 14)
                .background(Color.accent.opacity(rating > 0 ? 1 : 0.35), in: .capsule)
                .disabled(rating == 0)
            }
            .padding(20)
            .background(Color.appBackground)
            .navigationTitle("Napisz opinię")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Add photo

private struct AddPhotoSheet: View {
    let model: ParkCardPrototypeModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Text("Dodaj zdjęcie")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.textPrimary)
            SamplePhotoView(index: (model.selectedPark?.photos.count ?? 0) + 1)
                .frame(height: 260)
                .clipShape(.rect(cornerRadius: 20))
                .overlay(alignment: .topLeading) {
                    PhotoTag(text: "Podgląd aparatu (atrapa)", symbol: "camera", tint: .white)
                }
            Text("Aparat w apce, na miejscu, jak w Zgłoszeniu. Przed wysłaniem usuwamy lokalizację GPS i dane EXIF. Zdjęcie pokaże się innym po akceptacji Moderatora.")
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                model.addPhoto()
                dismiss()
            } label: {
                Label("Zrób zdjęcie", systemImage: "camera.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .font(.headline)
            .foregroundStyle(.black)
            .padding(.vertical, 14)
            .background(Color.accent, in: .capsule)
        }
        .padding(20)
        .presentationDetents([.large])
    }
}

// MARK: - Photo viewer

struct PhotoViewer: View {
    let model: ParkCardPrototypeModel
    @State private var currentID: Int
    @State private var reportTarget: ReportTarget?
    @Environment(\.dismiss) private var dismiss

    init(model: ParkCardPrototypeModel, startID: Int) {
        self.model = model
        _currentID = State(initialValue: startID)
    }

    private var photos: [CardPhoto] { model.selectedPark?.photos ?? [] }
    private var current: CardPhoto? { photos.first { $0.id == currentID } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $currentID) {
                ForEach(photos) { photo in
                    SamplePhotoView(index: photo.scene)
                        .aspectRatio(4 / 3, contentMode: .fit)
                        .tag(photo.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Button("Zamknij", systemImage: "xmark") { dismiss() }
                    .labelStyle(.iconOnly)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.12), in: .circle)
                Spacer()
                if let current, !current.isTeamPhoto, !current.isPendingModeration {
                    Button("Zgłoś zdjęcie", systemImage: "flag") {
                        reportTarget = .photo(current)
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(Color.white.opacity(0.12), in: .capsule)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
        }
        .safeAreaInset(edge: .bottom) {
            if let current {
                VStack(alignment: .leading, spacing: 4) {
                    if current.isTeamPhoto {
                        Label("Zdjęcie ekipy CaliPark", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Color.accent)
                    } else if current.isPendingModeration {
                        Label("Twoje zdjęcie czeka na moderację", systemImage: "clock")
                            .foregroundStyle(.orange)
                    } else {
                        Text(current.author).foregroundStyle(.white)
                    }
                    Text(ParkCardFormat.day(current.takenAt))
                        .foregroundStyle(Color.textSecondary)
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: Binding(
            get: { reportTarget.map { ParkCardModal.report($0) } },
            set: { if $0 == nil { reportTarget = nil } }
        )) { modal in
            ParkCardModalView(model: model, modal: modal)
        }
    }
}
#endif
