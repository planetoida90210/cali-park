import SwiftUI

// MARK: - ParkEventsSectionView
/// Section inside ParkDetailView displaying upcoming events carousel or upsell when no events.
struct ParkEventsSectionView: View {
    let park: Park
    let isPremiumUser: Bool
    let onJoin: (ParkEvent) -> Void

    @Namespace private var cardNS
    // Local state
    @State private var showList: Bool = false
    @State private var selectedEventForDetails: ParkEvent?

    // Shared events view model injected from parent
    @EnvironmentObject private var eventsVM: ParkEventsViewModel

    private var events: [ParkEvent] { eventsVM.events }
    private var joinedEvents: [ParkEvent] { events.filter { $0.isAttending } }

    private var dateDescriptor: String? {
        guard let first = events.first else { return nil }
        let cal = Calendar.current
        if cal.isDateInToday(first.date) { return "Dziś" }
        if cal.isDateInTomorrow(first.date) { return "Jutro" }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title Row
            HStack(alignment: .center, spacing: 6) {
                Text("Nadchodzące wydarzenia")
                    .font(.bodyMedium)
                    .foregroundColor(.textPrimary)
                if let chip = dateDescriptor {
                    Text(chip)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accent)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                        .transition(.scale)
                }

                Spacer()

                if events.count > 1 {
                    Button(action: { showList = true }) {
                        HStack(spacing: 4) {
                            Text("Wszystkie \(events.count)")
                            Image(systemName: "chevron.right")
                        }
                        .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accent)
                    .accessibilityLabel("Pokaż wszystkie wydarzenia")
                }
            }

            // Joined events quick view
            if !joinedEvents.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Twoje wydarzenia")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.textSecondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(joinedEvents) { ev in
                                Button {
                                    selectedEventForDetails = ev
                                } label: {
                                    Text(ev.title)
                                        .font(.caption2.weight(.semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.componentBackground)
                                        .foregroundColor(.accent)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }

            if let first = events.first {
                List {
                    EventListRow(event: first,
                                 onJoin: { onJoin(first) },
                                 onDetails: { selectedEventForDetails = first })
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .frame(height: 120)
                .listStyle(.plain)
                .scrollDisabled(true)
                .padding(.trailing, 80)
            } else {
                emptyStateView
            }
        }
        .sheet(isPresented: $showList) {
            EventsListSheetView(onJoin: { onJoin($0) })
                .environmentObject(eventsVM)
                .presentationDetents([.fraction(0.45), .large])
        }
        .sheet(item: $selectedEventForDetails) { event in
            EventDetailSheetView(event: event, onJoin: { onJoin(event) })
                .environmentObject(eventsVM)
                .presentationDetents([.fraction(0.5), .large])
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

    // MARK: - Join Logic
    private func joinAndDismiss(_ event: ParkEvent) {
        onJoin(event)
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
        ParkEventsSectionView(park: .mock.first!, isPremiumUser: false, onJoin: { _ in })
        ParkEventsSectionView(park: .mock.first!, isPremiumUser: true, onJoin: { _ in })
    }
    .environmentObject(ParkEventsViewModel(parkID: Park.mock.first!.id))
    .padding()
    .preferredColorScheme(.dark)
} 