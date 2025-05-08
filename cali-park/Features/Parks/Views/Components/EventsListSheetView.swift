import SwiftUI

// MARK: - EventsListSheetView
struct EventsListSheetView: View {
    let events: [ParkEvent]
    let onJoin: (ParkEvent) -> Void
    let onSelectDetails: (ParkEvent) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.gray.opacity(0.4)).frame(width: 40, height: 4)
                .padding(.top, 8)
            Text("Wszystkie wydarzenia")
                .font(.headline)
                .padding(.vertical, 8)
            Divider().background(Color.divider)
            List {
                ForEach(events) { event in
                    EventListRow(event: event,
                                 onJoin: { joinAndDismiss(event) },
                                 onDetails: { selectAndDismiss(event) })
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .padding(.horizontal)
        }
        .background(Color.appBackground)
        .ignoresSafeArea(edges: .bottom)
    }

    private func joinAndDismiss(_ event: ParkEvent) {
        dismiss(); onJoin(event)
    }

    private func selectAndDismiss(_ event: ParkEvent) {
        dismiss(); onSelectDetails(event)
    }
}

#Preview {
    EventsListSheetView(events: ParkEvent.mock) { _ in } onSelectDetails: { _ in }
} 