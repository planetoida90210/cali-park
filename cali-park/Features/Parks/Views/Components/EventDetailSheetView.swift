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

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.gray.opacity(0.4)).frame(width: 40, height: 4)
                .padding(.top, 8)
            Text(currentEvent.title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
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
            Spacer()
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
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

#Preview {
    EventDetailSheetView(event: .mock.first!, onJoin: {})
        .environmentObject(ParkEventsViewModel(parkID: Park.mock.first!.id))
        .preferredColorScheme(.dark)
} 