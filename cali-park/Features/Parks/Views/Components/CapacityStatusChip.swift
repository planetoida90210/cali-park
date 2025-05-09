import SwiftUI

// MARK: - CapacityStatusChip
/// Shows remaining spots or full indicator with color coding.
struct CapacityStatusChip: View {
    let event: ParkEvent

    private var text: String {
        if event.isFull {
            return "Brak miejsc"
        }
        if let capacity = event.capacity {
            let left = max(0, capacity - event.attendeeCount)
            return left == 0 ? "Brak miejsc" : "\(left) z \(capacity) miejsc"
        }
        return "Otwarte"
    }

    private var background: Color {
        event.isFull ? .red.opacity(0.8) : .accent
    }

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background)
            .foregroundColor(.black)
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 8) {
        CapacityStatusChip(event: ParkEvent.mock[0])
        CapacityStatusChip(event: ParkEvent.mock[1])
        CapacityStatusChip(event: ParkEvent.mock[0].withFull)
    }
    .padding()
    .preferredColorScheme(.dark)
}

private extension ParkEvent {
    var withFull: ParkEvent {
        var e = self
        e.attendeeCount = e.capacity ?? 10
        return e
    }
} 