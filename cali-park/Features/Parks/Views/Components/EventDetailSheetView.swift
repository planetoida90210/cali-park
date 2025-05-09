import SwiftUI

// MARK: - EventDetailSheetView
struct EventDetailSheetView: View {
    let event: ParkEvent
    let onJoin: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var eventsVM: ParkEventsViewModel

    // Returns up-to-date copy from shared VM (optimistic updates)
    private var currentEvent: ParkEvent {
        eventsVM.events.first(where: { $0.id == event.id }) ?? event
    }

    private var joinTitle: String {
        if currentEvent.isAttending { return "Dołączono" }
        if currentEvent.isFull { return "Brak miejsc" }
        return "Dołącz do wydarzenia"
    }

    private var joinDisabled: Bool { currentEvent.isAttending || currentEvent.isFull }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(currentEvent.title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .foregroundColor(.accent)
                    .padding(.horizontal)
                Text(currentEvent.formattedDate)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                HStack(spacing: 6) {
                    Image(systemName: "person.3.fill")
                    Text("\(currentEvent.attendeeCount) uczestników")
                }
                .font(.caption)
                .foregroundColor(.textSecondary)

                // Capacity status & progress
                CapacityStatusChip(event: currentEvent)
                ProgressView(value: Float(currentEvent.attendeeCount), total: Float(currentEvent.capacity ?? max(currentEvent.attendeeCount,1)))
                    .progressViewStyle(.linear)
                    .tint(Color.accent)
                    .scaleEffect(x: 1, y: 2, anchor: .center)

                // Organizer
                if let organizer = currentEvent.organizer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Organizator")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.textSecondary)
                        HStack(spacing: 12) {
                            AvatarStackView(participants: [organizer], maxVisible: 1, size: 48)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(organizer.name)
                                    .font(.bodyMedium)
                                    .foregroundColor(.textPrimary)
                                if let bio = organizer.bio {
                                    Text(bio)
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                    }
                }

                // Participants preview & action
                if !currentEvent.participants.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Uczestnicy (") + Text(String(currentEvent.attendeeCount)) + Text(")")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.textSecondary)
                        HStack(spacing: 8) {
                            AvatarStackView(participants: currentEvent.participants, size: 32)
                            Button("Zobacz listę") {}
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.accent)
                        }
                    }
                }

                // Location
                if let location = currentEvent.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(location)
                    }
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                }

                if let desc = currentEvent.description {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Opis")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.textSecondary)
                        ScrollView {
                            Text(desc)
                                .font(.bodySmall)
                                .foregroundColor(.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 120)
                    }
                }

                if !currentEvent.requiredEquipment.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sprzęt")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.textSecondary)
                        ForEach(currentEvent.requiredEquipment, id: \.self) { item in
                            Text("• \(item)")
                                .font(.caption)
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 32) // keeps content below drag indicator
            .padding(.bottom, 120) // extra space so last element not hidden by CTA inset
        }
        .safeAreaInset(edge: .bottom) {
            joinButton
                .padding(.vertical, 16)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - Join CTA
    private var joinButton: some View {
        Button(action: {
            guard !joinDisabled else { return }
            onJoin(); dismiss()
        }) {
            Text(joinTitle)
                .font(.body.weight(.semibold))
                .foregroundColor(joinDisabled ? .textSecondary : .black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(joinDisabled ? Color.componentBackground : Color.accent)
                .clipShape(Capsule())
        }
        .disabled(joinDisabled)
    }
}

#Preview {
    EventDetailSheetView(event: .mock.first!, onJoin: {})
        .environmentObject(ParkEventsViewModel(parkID: Park.mock.first!.id))
        .preferredColorScheme(.dark)
} 