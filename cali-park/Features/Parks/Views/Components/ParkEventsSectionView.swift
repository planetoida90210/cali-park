import SwiftUI

// MARK: - ParkEventsSectionView
/// Section inside ParkDetailView displaying upcoming events carousel or upsell when no events.
struct ParkEventsSectionView: View {
    let park: Park
    let isPremiumUser: Bool

    // Local state
    @State private var selectedEvent: ParkEvent?

    // Derived data
    private var events: [ParkEvent] { ParkEvent.events(for: park.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nadchodzące wydarzenia")
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)

            if let first = events.first {
                ParkEventCardView(event: first, onJoinTap: { selectedEvent = first }, fullWidth: true)
            } else {
                emptyStateView
            }
        }
        .sheet(item: $selectedEvent) { event in
            JoinEventSheetView(event: event)
                .presentationDetents([.height(220)])
        }
    }

    // MARK: - Empty State / Upsell
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Brak zaplanowanych treningów")
                .font(.caption)
                .foregroundColor(.textSecondary)
            if isPremiumUser {
                Button(action: {}) {
                    Text("Zaproponuj trening grupowy")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.accent)
                        .clipShape(Capsule())
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.accent)
                    Text("Funkcja Premium")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.componentBackground)
        .cornerRadius(8)
    }
}

// MARK: - JoinEventSheetView (bottom sheet)
private struct JoinEventSheetView: View {
    let event: ParkEvent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.gray.opacity(0.4)).frame(width: 40, height: 4)
                .padding(.top, 8)
            Text("Dołącz do wydarzenia")
                .font(.headline)
            Text(event.title)
                .font(.subheadline)
                .foregroundColor(.accent)
            Text(event.formattedDate)
                .font(.caption)
                .foregroundColor(.textSecondary)
            Button {
                // TODO: integrate Add to Calendar deep link when backend ready
                dismiss()
            } label: {
                Text("Potwierdź i dodaj do kalendarza")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accent)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.appBackground)
    }
}

// MARK: - Preview
#Preview {
    VStack(alignment: .leading, spacing: 16) {
        ParkEventsSectionView(park: .mock.first!, isPremiumUser: false)
        ParkEventsSectionView(park: .mock.first!, isPremiumUser: true)
    }
    .padding()
    .preferredColorScheme(.dark)
} 