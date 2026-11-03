#if DEBUG
// PROTOTYPE — throwaway. "Moje zgłoszenia": the author's view of the 012 statuses.

import SwiftUI

struct MySubmissionsView: View {
    @Bindable var model: ParkSubmissionPrototypeModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack(path: $model.minePath) {
            List {
                Section {
                    ForEach(model.submissions) { submission in
                        NavigationLink(value: submission) {
                            SubmissionRow(submission: submission, isNew: submission.id == model.lastSentID)
                        }
                        .listRowBackground(Color.componentBackground)
                    }
                } footer: {
                    Text("Zgłoszenia widzisz tylko Ty i Moderatorzy. Szkic jest tylko na tym telefonie, dopóki go nie wyślesz.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Moje zgłoszenia")
            .navigationDestination(for: PrototypeSubmission.self) { submission in
                SubmissionDetailView(submission: submission)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gotowe") { dismiss() }
                }
            }
        }
        .tint(Color.accent)
        .preferredColorScheme(.dark)
    }
}

private struct SubmissionRow: View {
    let submission: PrototypeSubmission
    let isNew: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(submission.name)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                if isNew {
                    Text("Nowe")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accent, in: .capsule)
                }
            }
            StatusPill(status: submission.status)
            Text(rowCaption)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }

    private var rowCaption: String {
        switch submission.status {
        case .draft: "Zaczęty \(SubmissionFormat.day(submission.sentAt)). Brakuje zdjęcia."
        case .pending: "Wysłane \(SubmissionFormat.day(submission.sentAt))"
        case .published: "Na mapie od \(SubmissionFormat.day(submission.decidedAt ?? submission.sentAt))"
        case .rejected(let reason, _), .removed(let reason, _): reason
        }
    }
}

struct StatusPill: View {
    let status: SubmissionStatus

    private var color: Color {
        switch status {
        case .draft: Color.textSecondary
        case .pending: Color.statusOrange
        case .published: Color.accent
        case .rejected: Color.statusRed
        case .removed: Color.textSecondary
        }
    }

    var body: some View {
        Label(status.title, systemImage: status.symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.14), in: .capsule)
    }
}

private struct SubmissionDetailView: View {
    let submission: PrototypeSubmission

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(submission.name)
                        .font(.title2)
                        .foregroundStyle(Color.textPrimary)
                    StatusPill(status: submission.status)
                }

                StatusExplanation(submission: submission)

                VStack(alignment: .leading, spacing: 8) {
                    SummaryRow(label: "Wysłane", value: submission.status == .draft ? "jeszcze nie" : SubmissionFormat.day(submission.sentAt))
                    if let decidedAt = submission.decidedAt {
                        SummaryRow(label: "Decyzja", value: SubmissionFormat.day(decidedAt))
                    }
                    SummaryRow(label: "Sprzęt", value: submission.equipment.map(\.title).joined(separator: ", "))
                    SummaryRow(label: "Zdjęcia", value: SubmissionFormat.photos(submission.photoCount))
                    if let proposed = submission.proposedName {
                        SummaryRow(label: "Nazwa z tabliczki", value: "„\(proposed)”")
                    }
                    SummaryRow(label: "Źródło", value: "zgłoszenie użytkownika")
                }
                .padding(14)
                .background(Color.componentBackground, in: .rect(cornerRadius: 18))
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StatusExplanation: View {
    let submission: PrototypeSubmission

    var body: some View {
        switch submission.status {
        case .draft:
            InfoCard(
                text: "Szkic jest zapisany tylko na tym telefonie. Nikt go nie widzi, dopóki go nie wyślesz.",
                actionTitle: "Dokończ zgłoszenie"
            )
        case .pending:
            InfoCard(
                text: "Moderator sprawdzi zdjęcia i sprzęt. Damy znać, gdy podejmie decyzję. Do tego czasu Park nie jest widoczny na mapie.",
                actionTitle: nil
            )
        case .published:
            InfoCard(
                text: "Park jest na mapie i każdy może go znaleźć. Dzięki za pomoc!",
                actionTitle: "Otwórz Park"
            )
        case .rejected(let reason, let explanation), .removed(let reason, let explanation):
            DecisionCard(reason: reason, explanation: explanation, isRemoval: submission.status.isRemoval)
        }
    }
}

private struct InfoCard: View {
    let text: String
    let actionTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
            if let actionTitle {
                Button(actionTitle) {}
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accent, in: .capsule)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.componentBackground, in: .rect(cornerRadius: 18))
    }
}

/// Statement of reasons for a rejection or removal (DSA art. 17, proposal 012 §5).
private struct DecisionCard: View {
    let reason: String
    let explanation: String
    let isRemoval: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isRemoval ? "Dlaczego usunęliśmy Park" : "Dlaczego odrzuciliśmy Zgłoszenie")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            VStack(alignment: .leading, spacing: 4) {
                Text(reason)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.statusRed)
                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(Color.textPrimary)
            }
            VStack(alignment: .leading, spacing: 6) {
                SummaryRow(label: "Podstawa", value: "Regulamin, zasady Zgłoszeń")
                SummaryRow(label: "Decyzję podjął", value: "Moderator (nie automat)")
            }
            Divider()
            Text("Nie zgadzasz się? Odwołaj się, a Moderator sprawdzi to jeszcze raz. Możesz też dochodzić swoich praw w sądzie.")
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
            Button("Odwołaj się") {}
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(Capsule().stroke(Color.accent, lineWidth: 1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.componentBackground, in: .rect(cornerRadius: 18))
    }
}

private extension SubmissionStatus {
    var isRemoval: Bool {
        if case .removed = self { return true }
        return false
    }
}
#endif
