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
        currentEvent.isAttending ? "Dołączono" : "Dołącz do wydarzenia"
    }

    private var joinDisabled: Bool { currentEvent.isAttending }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(currentEvent.title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .foregroundColor(.accent)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                Text(currentEvent.formattedDate)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                HStack(spacing: 6) {
                    Image(systemName: "person.3.fill")
                    Text("\(currentEvent.attendeeCount) osób planuje być")
                }
                .font(.caption)
                .foregroundColor(.textSecondary)

                // ACTIONS ROW (join/share/chat)
                buttonsRow

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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Uczestnicy (\(currentEvent.attendeeCount))")
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
            .padding(.top, 32) // below drag indicator
            .padding(.bottom, 40) // regular bottom spacing
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - Buttons Row (horizontal)
    private var buttonsRow: some View {
        HStack(spacing: 12) {
            // Join / joined capsule
            if currentEvent.isAttending {
                Label("Dołączono", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .clipShape(Capsule())

                Button {
                    Task { await eventsVM.leave(currentEvent) }
                } label: {
                    Text("Wypisz się")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .clipShape(Capsule())
            } else {
                Button {
                    onJoin(); dismiss()
                } label: {
                    Text("Dołącz")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accent)
                .clipShape(Capsule())
            }

            // Share chip
            ShareLink(item: shareMessage) {
                Image(systemName: "square.and.arrow.up")
            }
            .font(.caption)
            .padding(8)
            .background(Color.componentBackground)
            .foregroundColor(.textSecondary)
            .clipShape(Capsule())

            // Chat chip (only if attending)
            if currentEvent.isAttending {
                Button {
                    // TODO: navigate to chat view
                } label: {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                }
                .font(.caption)
                .padding(8)
                .background(Color.componentBackground)
                .foregroundColor(.accent)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Share message helper
    private var shareMessage: String {
        "Będę na wydarzeniu \(currentEvent.title) w CaliParku – dołączysz? \n\(currentEvent.formattedDate)"
    }
}

#Preview {
    EventDetailSheetView(event: .mock.first!, onJoin: {})
        .environmentObject(ParkEventsViewModel(parkID: Park.mock.first!.id))
        .preferredColorScheme(.dark)
} 