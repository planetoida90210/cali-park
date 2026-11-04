#if DEBUG
// PROTOTYPE — throwaway. Layout B "Jeden arkusz": everything on one scrolling screen with a
// checklist of the required parts on top and a sticky button that says what is missing.

import MapKit
import SwiftUI

struct SubmissionSheetLayout: View {
    @Bindable var model: ParkSubmissionPrototypeModel
    @State private var showsDetails = false

    init(model: ParkSubmissionPrototypeModel) {
        self.model = model
        _showsDetails = State(initialValue: model.scrollTarget == "details")
    }

    var body: some View {
        NavigationStack(path: $model.path) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        RequirementsChecklist(draft: model.draft)
                        SheetBlock(title: "Miejsce", badge: .required) {
                            LocationPreview(model: model)
                        }
                        .id("location")
                        SheetBlock(title: "Sprzęt", badge: .required) {
                            EquipmentSection(model: model)
                        }
                        .id("equipment")
                        SheetBlock(title: "Zdjęcie z miejsca", badge: .required) {
                            PhotosSection(model: model)
                        }
                        .id("photos")
                        SheetBlock(title: "Nazwa", badge: .optional) {
                            NameSection(model: model)
                        }
                        .id("name")
                        SheetBlock(title: "Szczegóły", badge: .optional) {
                            DisclosureGroup(isExpanded: $showsDetails) {
                                DetailsSection(model: model)
                                    .padding(.top, 12)
                            } label: {
                                Text("Nawierzchnia, oświetlenie, zadaszenie, dostęp")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                        .id("details")
                        Color.clear.frame(height: 1).id("send")
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    if let target = model.scrollTarget { proxy.scrollTo(target, anchor: .top) }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Nowy Park")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { model.finish(showingMine: false) }
                }
            }
            .safeAreaInset(edge: .bottom) {
                SheetFooter(draft: model.draft) { model.path.append(.summary) }
            }
            .navigationDestination(for: SubmissionStep.self) { step in
                switch step {
                case .sent: SubmissionSentView(model: model)
                default: SubmissionSummaryView(model: model)
                }
            }
        }
        .tint(Color.accent)
    }
}

private enum SheetBadge {
    case required, optional

    var title: String { self == .required ? "Wymagane" : "Opcjonalne" }
}

private struct SheetBlock<Content: View>: View {
    let title: String
    let badge: SheetBadge
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.appTitle3)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(badge.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(badge == .required ? Color.accent : Color.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((badge == .required ? Color.accent : Color.white).opacity(0.12), in: .capsule)
            }
            content
        }
    }
}

/// A non-interactive map of the pin with a "change" button.
struct LocationPreview: View {
    let model: ParkSubmissionPrototypeModel

    var body: some View {
        Map(
            initialPosition: .region(
                MKCoordinateRegion(
                    center: model.draft.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                )), interactionModes: []
        ) {
            Annotation("Nowy Park", coordinate: model.draft.coordinate, anchor: .bottom) {
                SubmissionNewPin()
                    .scaleEffect(0.7, anchor: .bottom)
            }
            .annotationTitles(.hidden)
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .frame(height: 140)
        .clipShape(.rect(cornerRadius: AppRadius.large))
        .overlay(alignment: .bottomTrailing) {
            Button("Zmień", systemImage: "mappin.and.ellipse") { model.editLocation() }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .mapLookGlass(in: .capsule)
                .padding(8)
        }
    }
}

private struct SheetFooter: View {
    let draft: SubmissionDraft
    let onReview: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if !draft.missing.isEmpty {
                Text("Brakuje: \(draft.missing.joined(separator: " i "))")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
            Button(action: onReview) {
                Text("Sprawdź i wyślij")
                    .frame(maxWidth: .infinity)
            }
            .font(.headline)
            .foregroundStyle(draft.canSend ? Color.black : Color.textTertiary)
            .padding(.vertical, 14)
            .background(draft.canSend ? Color.accent : Color.componentBackground, in: .capsule)
            .disabled(!draft.canSend || draft.plaqueNameProblem != nil)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(Color.appBackground)
    }
}
#endif
