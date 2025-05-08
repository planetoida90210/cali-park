import SwiftUI

// MARK: - EventsListSheetView
struct EventsListSheetView: View {
    let events: [ParkEvent]
    let onSelect: (ParkEvent) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(events) { event in
                EventListRow(event: event,
                             onJoin: {
                                 dismiss(); onSelect(event)
                             },
                             onDetails: {
                                 dismiss(); onSelect(event)
                             })
                .listRowInsets(EdgeInsets())
            }
            .listStyle(.plain)
            .navigationTitle("Wydarzenia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Zamknij") { dismiss() } } }
        }
    }
}

#Preview {
    EventsListSheetView(events: ParkEvent.mock) { _ in }
} 