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
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contextMenu {
            Button("Dołącz") { onJoin() }
            Button("Szczegóły") { onDetails() }
        }
        .accessibilityElement()
        .accessibilityLabel(event.title)
        .accessibilityHint("Przesuń w prawo, aby dołączyć")
        .onTapGesture { onDetails() }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onJoin()
            } label: {
                Label("Dołącz", systemImage: "checkmark.circle.fill")
            }
            .tint(.accent)
        }
        // Subtle swipe hint arrow (one-time animated)
        .overlay(alignment: .trailing) {
            SwipeHintArrow()
                .allowsHitTesting(false)
        }
    }
}

// MARK: - SwipeHintArrow helper
private struct SwipeHintArrow: View {
    @State private var offset: CGFloat = 0
    @AppStorage("hasSeenSwipeHint") private var hasSeenHint: Bool = false

    var body: some View {
        Image(systemName: "arrow.right")
            .font(.caption)
            .foregroundColor(.textSecondary)
            .opacity(hasSeenHint ? 0 : 0.6)
            .offset(x: offset)
            .onAppear {
                guard !hasSeenHint else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    offset = -8
                }
                // Auto-hide after 3 sec
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeOut) { hasSeenHint = true }
                }
            }
    }
}

#Preview {
    EventListRow(event: .mock.first!, onJoin: {}, onDetails: {})
        .padding()
        .preferredColorScheme(.dark)
} 