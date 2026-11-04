#if DEBUG
// PROTOTYPE — throwaway. Summary before sending, and the confirmation after.

import SwiftUI

struct SubmissionSummaryView: View {
    @Bindable var model: ParkSubmissionPrototypeModel

    private var draft: SubmissionDraft { model.draft }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sprawdź i wyślij")
                        .font(.appTitle)
                        .foregroundStyle(Color.textPrimary)
                    Text("Do akceptacji Moderatora Zgłoszenie widzisz tylko Ty.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    SummaryRow(label: "Źródło", value: "zgłoszenie użytkownika")
                    SummaryRow(label: "Wysyłasz jako", value: SubmissionSampleData.nickname)
                    Text("Fakty o Parku (miejsce, sprzęt, szczegóły) trafią do otwartej bazy Parków na licencji ODbL. Zdjęcia i Twój Pseudonim nie.")
                        .font(.footnote)
                        .foregroundStyle(Color.textTertiary)
                        .padding(.top, 2)
                }
                .padding(14)
                .background(Color.componentBackground, in: .rect(cornerRadius: AppRadius.large))

                SummaryBlock(title: "Miejsce", onEdit: { model.editLocation() }) {
                    LocationPreview(model: model)
                }

                SummaryBlock(title: "Sprzęt", onEdit: { model.edit(.equipment) }) {
                    FlowLayout(spacing: 6) {
                        ForEach(draft.sortedEquipment) { item in
                            Label(item.title, systemImage: item.symbol)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.controlFill, in: .capsule)
                        }
                    }
                }

                SummaryBlock(title: SubmissionFormat.photos(draft.photos.count), onEdit: { model.edit(.photos) }) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(draft.photos, id: \.self) { photo in
                                SamplePhotoView(index: photo)
                                    .frame(width: 72, height: 96)
                                    .clipShape(.rect(cornerRadius: AppRadius.small))
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }

                SummaryBlock(title: "Nazwa", onEdit: { model.edit(.name) }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(draft.generatedName)
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        if let proposed = draft.trimmedPlaqueName {
                            Text("Proponujesz nazwę z tabliczki: „\(proposed)”. Moderator ją sprawdzi.")
                                .font(.footnote)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }

                SummaryBlock(title: "Szczegóły", onEdit: { model.edit(.details) }) {
                    if draft.filledDetails.isEmpty {
                        Text("Nie podano. Możesz je dodać później jako poprawkę.")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(draft.filledDetails, id: \.label) { row in
                                SummaryRow(label: row.label, value: row.value)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("Wyślij do moderacji", systemImage: "paperplane.fill") {
                model.send()
            }
            .buttonStyle(.accent)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(Color.appBackground)
            .disabled(!draft.canSend)
        }
    }
}

private struct SummaryBlock<Content: View>: View {
    let title: String
    let onEdit: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Button("Zmień", action: onEdit)
                    .font(.subheadline.weight(.semibold))
            }
            content
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

struct SubmissionSentView: View {
    let model: ParkSubmissionPrototypeModel

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.appLargeTitle)
                .imageScale(.large)
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)
            Text("Dzięki! Zgłoszenie wysłane")
                .font(.appTitle2)
                .foregroundStyle(Color.textPrimary)
            Text("Czeka na moderację. Moderator sprawdzi zdjęcia i sprzęt, a po akceptacji Park pojawi się na mapie. Status znajdziesz w „Moje zgłoszenia”.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                model.finish(showingMine: true)
            } label: {
                Text("Moje zgłoszenia")
                    .frame(maxWidth: .infinity)
            }
            .font(.headline)
            .foregroundStyle(.black)
            .padding(.vertical, 14)
            .background(Color.accent, in: .capsule)
            Button("Wróć do mapy") { model.finish(showingMine: false) }
                .font(.headline)
                .padding(.vertical, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.appBackground)
        .navigationBarBackButtonHidden()
    }
}
#endif
