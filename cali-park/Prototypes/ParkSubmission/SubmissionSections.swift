#if DEBUG
// PROTOTYPE — throwaway. Form sections shared by both layouts. Each layout arranges them
// differently; the sections themselves only edit the draft.

import SwiftUI

// MARK: - Equipment

struct EquipmentSection: View {
    @Bindable var model: ParkSubmissionPrototypeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ChipGroup(
                title: "Drążek albo poręcze",
                caption: "Bez jednego z nich miejsce nie trafi na mapę.",
                items: SubmissionEquipment.core,
                model: model
            )
            if !model.draft.equipment.isEmpty && !model.draft.hasCoreEquipment {
                NotAParkNotice()
            }
            if model.draft.equipment.contains(.horizontalBar) {
                BarDetails(model: model)
            }
            if model.draft.equipment.contains(.parallelBars) {
                CountPicker(title: "Ile poręczy?", value: $model.draft.parallelBarsCount)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.componentBackground, in: .rect(cornerRadius: AppRadius.large))
            }
            ChipGroup(
                title: "Coś jeszcze? (opcjonalnie)",
                caption: nil,
                items: SubmissionEquipment.extra,
                model: model
            )
            Toggle(isOn: $model.draft.hasMachines) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Obok są też maszyny")
                        .foregroundStyle(Color.textPrimary)
                    Text("Orbitrek, wioślarz, wyciąg i podobne. Nie wpisujemy ich jako sprzętu.")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .tint(Color.accent)
        }
    }
}

private struct ChipGroup: View {
    let title: String
    let caption: String?
    let items: [SubmissionEquipment]
    @Bindable var model: ParkSubmissionPrototypeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                if let caption {
                    Text(caption)
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            FlowLayout(spacing: 8) {
                ForEach(items) { item in
                    SelectableChip(
                        title: item.title,
                        symbol: item.symbol,
                        isSelected: model.draft.equipment.contains(item)
                    ) {
                        model.toggle(item)
                    }
                }
            }
        }
    }
}

struct SelectableChip: View {
    let title: String
    var symbol: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: isSelected ? "checkmark" : symbol)
                        .font(.footnote.weight(.semibold))
                }
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isSelected ? Color.black : Color.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isSelected ? Color.accent : Color.componentBackground, in: .capsule)
            .overlay(Capsule().stroke(Color.white.opacity(isSelected ? 0 : 0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct NotAParkNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color.warning)
            VStack(alignment: .leading, spacing: 4) {
                Text("To jeszcze nie Park")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Na mapie są tylko miejsca, gdzie zrobisz pełny trening: z drążkiem albo poręczami. Same kółka, drabinki czy maszyny nie wystarczą. Jeśli jest tu drążek albo poręcze, zaznacz je wyżej.")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warning.opacity(0.12), in: .rect(cornerRadius: AppRadius.large))
    }
}

private struct BarDetails: View {
    @Bindable var model: ParkSubmissionPrototypeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CountPicker(title: "Ile drążków?", value: $model.draft.barCount)
            VStack(alignment: .leading, spacing: 8) {
                Text("Jakie wysokości?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                HStack(spacing: 8) {
                    ForEach(BarHeight.allCases) { height in
                        SelectableChip(title: height.title, isSelected: model.draft.barHeights.contains(height)) {
                            if model.draft.barHeights.contains(height) {
                                model.draft.barHeights.remove(height)
                            } else {
                                model.draft.barHeights.insert(height)
                            }
                        }
                    }
                }
                Text("Niski: do pasa. Średni: chwytasz stojąc. Wysoki: trzeba podskoczyć.")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(14)
        .background(Color.componentBackground, in: .rect(cornerRadius: AppRadius.large))
    }
}

private struct CountPicker: View {
    let title: String
    @Binding var value: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(title) (opcjonalnie)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { count in
                    SelectableChip(title: count == 4 ? "4+" : "\(count)", isSelected: value == count) {
                        value = value == count ? nil : count
                    }
                }
            }
        }
    }
}

// MARK: - Photos

struct PhotosSection: View {
    @Bindable var model: ParkSubmissionPrototypeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if model.draft.photos.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "camera.viewfinder")
                        .font(.appLargeTitle)
                        .foregroundStyle(Color.accent)
                    Text("Zrób zdjęcie drążka albo poręczy")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    Text("To dowód dla Moderatora, że ten Park istnieje. Zdjęcie robisz teraz, na miejscu, w aplikacji.")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.componentBackground, in: .rect(cornerRadius: AppRadius.large))
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(model.draft.photos, id: \.self) { photo in
                            SamplePhotoView(index: photo)
                                .frame(width: 128, height: 170)
                                .clipShape(.rect(cornerRadius: AppRadius.medium))
                                .overlay(alignment: .topTrailing) {
                                    Button("Usuń zdjęcie", systemImage: "xmark") {
                                        model.removePhoto(photo)
                                    }
                                    .labelStyle(.iconOnly)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 26, height: 26)
                                    .background(.black.opacity(0.6), in: .circle)
                                    .padding(6)
                                }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            if model.draft.photos.count < SubmissionDraft.maxPhotos {
                Button {
                    model.isCameraPresented = true
                } label: {
                    Label(model.draft.photos.isEmpty ? "Zrób zdjęcie" : "Zrób kolejne zdjęcie", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .font(.headline)
                .foregroundStyle(model.draft.photos.isEmpty ? Color.black : Color.accent)
                .padding(.vertical, 14)
                .background(model.draft.photos.isEmpty ? Color.accent : Color.componentBackground, in: .capsule)
            }

            Label {
                Text("Przed wysłaniem usuwamy ze zdjęć lokalizację GPS i inne dane EXIF. Unikaj ludzi w kadrze.")
            } icon: {
                Image(systemName: "lock.shield")
            }
            .font(.footnote)
            .foregroundStyle(Color.textSecondary)

            Text("\(SubmissionFormat.photos(model.draft.photos.count)) z \(SubmissionDraft.maxPhotos)")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(Color.textTertiary)
        }
    }
}

// MARK: - Name

struct NameSection: View {
    @Bindable var model: ParkSubmissionPrototypeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Na mapie będzie się nazywał")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                Text(model.draft.generatedName)
                    .font(.appTitle3.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Nazwę tworzymy sami z okolicy i sprzętu, żeby na mapie nie było nazw typu „Mój park”.")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.componentBackground, in: .rect(cornerRadius: AppRadius.large))

            VStack(alignment: .leading, spacing: 8) {
                Text("Nazwa z tabliczki (opcjonalnie)")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                TextField("np. Strefa Street Workout Kamionek", text: $model.draft.plaqueName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.componentBackground, in: .rect(cornerRadius: AppRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.medium)
                            .stroke(model.draft.plaqueNameProblem == nil ? Color.divider : Color.danger, lineWidth: 1)
                    )
                if let problem = model.draft.plaqueNameProblem {
                    Label(problem, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.danger)
                } else {
                    Text("Tylko oficjalna nazwa, np. z tabliczki przy wejściu. Moderator ją sprawdzi, zanim pojawi się na mapie.")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
}

// MARK: - Optional details

struct DetailsSection: View {
    @Bindable var model: ParkSubmissionPrototypeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Nawierzchnia pod sprzętem")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                FlowLayout(spacing: 8) {
                    ForEach(SubmissionSurface.allCases) { surface in
                        SelectableChip(title: surface.title, isSelected: model.draft.surface == surface) {
                            model.draft.surface = model.draft.surface == surface ? nil : surface
                        }
                    }
                }
            }
            TriStateRow(title: "Oświetlenie po zmroku", value: $model.draft.lit)
            TriStateRow(title: "Zadaszenie", value: $model.draft.covered)
            VStack(alignment: .leading, spacing: 10) {
                Text("Kto może tu ćwiczyć?")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                HStack(spacing: 8) {
                    ForEach(SubmissionAccess.allCases) { access in
                        SelectableChip(title: access.title, isSelected: model.draft.access == access) {
                            model.draft.access = access
                        }
                    }
                }
                Text("Np. drążki przy hotelu albo w szkole otwartej po lekcjach. Miejsc całkiem prywatnych nie dodajemy.")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}

private struct TriStateRow: View {
    let title: String
    @Binding var value: TriState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            HStack(spacing: 8) {
                ForEach(TriState.allCases) { option in
                    SelectableChip(title: option.title, isSelected: value == option) {
                        value = option
                    }
                }
            }
        }
    }
}

// MARK: - Requirements checklist

/// The three required things, ticked as they are done.
struct RequirementsChecklist: View {
    let draft: SubmissionDraft

    var body: some View {
        HStack(spacing: 14) {
            RequirementTick(title: "Miejsce", isDone: true)
            RequirementTick(title: "Drążek lub poręcze", isDone: draft.hasCoreEquipment)
            RequirementTick(title: "Zdjęcie", isDone: draft.hasPhoto)
        }
        .font(.footnote.weight(.medium))
    }
}

private struct RequirementTick: View {
    let title: String
    let isDone: Bool

    var body: some View {
        Label(title, systemImage: isDone ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(isDone ? Color.accent : Color.textSecondary)
    }
}

// MARK: - Flow layout

/// Wraps chips onto new lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews: subviews, width: proposal.width ?? .infinity)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(subviews: subviews, width: bounds.width)
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }

    private struct Row {
        var indices: [Int] = []
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width && !current.indices.isEmpty {
                rows.append(current)
                current = Row(y: current.y + current.height + spacing)
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
#endif
