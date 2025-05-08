import SwiftUI

// MARK: - ParkEventCardView
/// Single horizontally scrollable card representing upcoming park event.
/// Keeps footprint small to stay within soft-limit; heavy UI in Section view.
struct ParkEventCardView: View {
    let event: ParkEvent
    let onJoinTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.accent)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

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

            Spacer(minLength: 0)

            Button(action: onJoinTap) {
                Text(event.isFull ? "Lista pełna" : "Dołącz")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(event.isFull ? .textSecondary : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(event.isFull ? Color.componentBackground : Color.accent)
                    .clipShape(Capsule())
            }
            .disabled(event.isFull)
        }
        .padding(12)
        .frame(width: 180, height: 140)
        .background(Color.componentBackground)
        .cornerRadius(10)
    }
}

// MARK: - Preview
#Preview {
    ParkEventCardView(event: .mock.first!, onJoinTap: {})
        .preferredColorScheme(.dark)
} 