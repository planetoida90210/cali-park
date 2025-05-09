import SwiftUI

// MARK: - EventsListSheetView
/// Bottom sheet presenting full list of events for a given park.
struct EventsListSheetView: View {
    let events: [ParkEvent]
    let onJoin: (ParkEvent) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isRefreshing = false
    @State private var detailItem: ParkEvent?

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
                isRefreshing = true
                // Simulate network refresh; in real impl hook into VM
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                isRefreshing = false
            }
            .navigationTitle("Wydarzenia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Zamknij") { dismiss() } } }
            .sheet(item: $detailItem) { event in
                EventDetailSheetView(event: event, onJoin: { quickJoin(event) })
                    .presentationDetents([.fraction(0.5), .large])
            }
        }
    }

    private func quickJoin(_ event: ParkEvent) {
        onJoin(event)
        dismiss()
    }
}

#Preview {
    EventsListSheetView(events: ParkEvent.mock, onJoin: { _ in })
        .preferredColorScheme(.dark)
} 