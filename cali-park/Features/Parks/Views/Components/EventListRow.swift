import SwiftUI

// MARK: - EventListRow
/// Compact card representing single park event.
struct EventListRow: View {
    let event: ParkEvent
    let onJoin: () -> Void
    let onDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(event.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.accent)
                .lineLimit(2)
            Text(event.formattedDate)
                .font(.caption)
                .foregroundColor(.textSecondary)
            HStack(spacing: 4) {
                Image(systemName: "person.3.fill")
                    .imageScale(.small)
                Text("\(event.attendeeCount)\(event.capacity != nil ? "/\(event.capacity!)" : "")")
                    .font(.caption2)
            }
            .foregroundColor(.textPrimary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.componentBackground)
        .cornerRadius(12)
        .contextMenu {
            Button("Dołącz") { onJoin() }
            Button("Szczegóły") { onDetails() }
        }
        .accessibilityElement()
        .accessibilityLabel(event.title)
        .accessibilityHint("Przesuń w prawo, aby dołączyć")
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onJoin()
            } label: {
                Label("Dołącz", systemImage: "checkmark.circle.fill")
            }
            .tint(.accent)
        }
    }
}

#Preview {
    EventListRow(event: .mock.first!, onJoin: {}, onDetails: {})
        .padding()
        .preferredColorScheme(.dark)
} 