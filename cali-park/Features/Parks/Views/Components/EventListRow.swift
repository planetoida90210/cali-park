import SwiftUI

// MARK: - EventListRow v2
/// Sleek Silicon-Valley style row for park events.
/// Shows status chip, avatars, CTA button + swipe shortcut.
struct EventListRow: View {
    let event: ParkEvent
    let onJoin: () -> Void
    let onDetails: () -> Void

    // Local glow animation for newly joined state
    @State private var joinedHighlight: Bool = false

    private var capacityText: String {
        if let capacity = event.capacity {
            return "\(event.attendeeCount)/\(capacity)"
        } else {
            return "\(event.attendeeCount)"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // MAIN INFO
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.accent)
                    .lineLimit(2)
                Text(event.formattedDate)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                HStack(spacing: 10) {
                    AvatarStackView(participants: event.participants)
                    HStack(spacing: 4) {
                        Image(systemName: "person.3.fill")
                            .imageScale(.small)
                        Text(capacityText)
                    }
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                }
            }
            Spacer()
            // Trailing status icon
            Image(systemName: event.isAttending ? "checkmark.circle.fill" : "chevron.right")
                .foregroundColor(event.isAttending ? .green : .textSecondary)
                .imageScale(.medium)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                withAnimation { handleJoin() }
            } label: {
                Label("Dołącz", systemImage: "checkmark.circle")
            }
            .tint(.accent)
        }
        .onTapGesture { onDetails() }
        .overlay(joinedHighlight ? RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 2) : nil)
        .overlay(alignment: .trailing) {
            SwipeHintArrow()
                .allowsHitTesting(false)
        }
    }

    private var background: Color {
        Color.componentBackground.opacity(event.isAttending ? 0.9 : 1.0)
    }

    private func handleJoin() {
        onJoin()
        joinedHighlight = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            joinedHighlight = false
        }
    }
}

// MARK: - SwipeHintArrow helper (one-time animated cue for swipe-to-join)
private struct SwipeHintArrow: View {
    @State private var offset: CGFloat = 0
    @AppStorage("hasSeenSwipeHint") private var hasSeenHint: Bool = false

    var body: some View {
        Image(systemName: "arrow.left")
            .font(.caption)
            .foregroundColor(.textSecondary)
            .opacity(hasSeenHint ? 0 : 0.6)
            .offset(x: offset)
            .onAppear {
                guard !hasSeenHint else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    offset = 8
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeOut) { hasSeenHint = true }
                }
            }
    }
}

#Preview {
    VStack(spacing: 12) {
        EventListRow(event: ParkEvent.mock[0], onJoin: {}, onDetails: {})
        EventListRow(event: ParkEvent.mock[0].withJoined, onJoin: {}, onDetails: {})
    }
    .padding()
    .preferredColorScheme(.dark)
}

private extension ParkEvent {
    var withJoined: ParkEvent {
        var e = self
        e.isAttending = true
        return e
    }
} 