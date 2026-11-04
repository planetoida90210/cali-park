#if DEBUG
// PROTOTYPE — throwaway. Layout A "Kroki": one question per screen. Required steps first
// (equipment, photo), then optional ones with "Pomiń", then the summary.

import SwiftUI

struct SubmissionStepsLayout: View {
    @Bindable var model: ParkSubmissionPrototypeModel

    var body: some View {
        NavigationStack(path: $model.path) {
            StepPage(model: model, step: .equipment)
                .navigationDestination(for: SubmissionStep.self) { step in
                    switch step {
                    case .summary: SubmissionSummaryView(model: model)
                    case .sent: SubmissionSentView(model: model)
                    default: StepPage(model: model, step: step)
                    }
                }
        }
        .tint(Color.accent)
    }
}

private struct StepPage: View {
    @Bindable var model: ParkSubmissionPrototypeModel
    let step: SubmissionStep

    private static let order: [SubmissionStep] = [.equipment, .photos, .name, .details, .summary]

    /// Step 1 is the pin on the map, so the form starts at 2.
    private var number: Int { (Self.order.firstIndex(of: step) ?? 0) + 2 }
    private var total: Int { Self.order.count + 1 }
    private var next: SubmissionStep { Self.order[(Self.order.firstIndex(of: step) ?? 0) + 1] }

    private var title: String {
        switch step {
        case .equipment: "Jaki sprzęt tu jest?"
        case .photos: "Zdjęcie z miejsca"
        case .name: "Nazwa"
        case .details: "Szczegóły"
        default: ""
        }
    }

    private var subtitle: String {
        switch step {
        case .equipment: "Zaznacz wszystko, co widzisz. Wystarczy jedno: drążek albo poręcze."
        case .photos: "Przynajmniej jedno zdjęcie, na którym widać sprzęt."
        case .name: "Opcjonalne. Możesz pominąć."
        case .details: "Opcjonalne. Pomagają wybrać Park, np. zimą po zmroku."
        default: ""
        }
    }

    private var isOptional: Bool { step == .name || step == .details }

    private var blocker: String? {
        switch step {
        case .equipment: model.draft.hasCoreEquipment ? nil : "Zaznacz drążek albo poręcze"
        case .photos: model.draft.hasPhoto ? nil : "Zrób przynajmniej jedno zdjęcie"
        case .name: model.draft.plaqueNameProblem == nil ? nil : "Popraw nazwę albo ją usuń"
        default: nil
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StepProgress(number: number, total: total)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.appTitle)
                        .foregroundStyle(Color.textPrimary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                switch step {
                case .equipment: EquipmentSection(model: model)
                case .photos: PhotosSection(model: model)
                case .name: NameSection(model: model)
                case .details: DetailsSection(model: model)
                default: EmptyView()
                }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if step == .equipment {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { model.finish(showingMine: false) }
                }
            }
            if isOptional {
                ToolbarItem(placement: .primaryAction) {
                    Button("Pomiń") { model.path.append(next) }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            StepFooter(blocker: blocker) { model.path.append(next) }
        }
    }
}

private struct StepProgress: View {
    let number: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Krok \(number) z \(total)")
                .font(.footnote.weight(.semibold).monospacedDigit())
                .foregroundStyle(Color.accent)
            HStack(spacing: 4) {
                ForEach(1...total, id: \.self) { index in
                    Capsule()
                        .fill(index <= number ? Color.accent : Color.divider)
                        .frame(height: 4)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct StepFooter: View {
    let blocker: String?
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if let blocker {
                Text(blocker)
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
            Button(action: onNext) {
                Text("Dalej")
                    .frame(maxWidth: .infinity)
            }
            .font(.headline)
            .foregroundStyle(blocker == nil ? Color.black : Color.textTertiary)
            .padding(.vertical, 14)
            .background(blocker == nil ? Color.accent : Color.componentBackground, in: .capsule)
            .disabled(blocker != nil)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(Color.appBackground)
    }
}
#endif
