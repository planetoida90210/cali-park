import SwiftUI

// MARK: - EventsListSheetView
struct EventsListSheetView: View {
    let events: [ParkEvent]
    let onSelect: (ParkEvent) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.gray.opacity(0.4)).frame(width: 40, height: 4)
                .padding(.top, 8)
            Text("Wszystkie wydarzenia")
                .font(.headline)
                .padding(.vertical, 8)
            Divider().background(Color.divider)
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(events) { event in
                        EventListRow(event: event,
                                     onJoin: { onSelectAndDismiss(event) },
                                     onDetails: { onSelectAndDismiss(event) })
                    }
                }
                .padding()
            }
        }
        .background(Color.appBackground)
        .ignoresSafeArea(edges: .bottom)
    }

    private func onSelectAndDismiss(_ event: ParkEvent) {
        dismiss()
        onSelect(event)
    }
}

#Preview {
    EventsListSheetView(events: ParkEvent.mock) { _ in }
} 