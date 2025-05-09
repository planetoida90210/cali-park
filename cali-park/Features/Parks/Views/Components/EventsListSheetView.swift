import SwiftUI

// MARK: - EventsListSheetView
/// Bottom sheet presenting full list of events for a given park.
struct EventsListSheetView: View {
    let onJoin: (ParkEvent) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var detailItem: ParkEvent?
    @EnvironmentObject private var eventsVM: ParkEventsViewModel

    private var events: [ParkEvent] { eventsVM.events }

    var body: some View {
        NavigationStack {
            List {
                ForEach(events) { event in
                    EventListRow(event: event,
                                 onJoin: { quickJoin(event) },
                                 onDetails: { detailItem = event })
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .refreshable {
                await eventsVM.refresh()
            }
            .navigationTitle("Wydarzenia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Zamknij") { dismiss() } } }
            .sheet(item: $detailItem) { event in
                EventDetailSheetView(event: event, onJoin: { quickJoin(event) })
                    .presentationDetents([.fraction(0.5), .large])
                    .environmentObject(eventsVM)
            }
        }
    }

    private func quickJoin(_ event: ParkEvent) {
        onJoin(event)
        dismiss()
    }
}

#Preview {
    EventsListSheetView(onJoin: { _ in })
        .environmentObject(ParkEventsViewModel(parkID: Park.mock.first!.id))
        .preferredColorScheme(.dark)
} 