import SwiftUI

// MARK: - ParkEventWideCardView
/// Full-width card with information on the left and a slim CTA stripe on the right (avoids FAB collision).
struct ParkEventWideCardView: View {
    let event: ParkEvent
    let onJoinTap: () -> Void

    private let stripeWidth: CGFloat = 56

    var body: some View {
        HStack(spacing: 0) {
            // Info
            VStack(alignment: .leading, spacing: 6) {
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
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Divider
            Rectangle()
                .fill(Color.componentBackground.opacity(0.6))
                .frame(width: 1)

            // CTA stripe – subtle: dark background + accent arrow
            Button(action: onJoinTap) {
                Image(systemName: "chevron.right")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .frame(width: stripeWidth)
            .background(Color.componentBackground)
            .overlay(
                Rectangle()
                    .stroke(Color.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .frame(height: 120)
        .background(Color.componentBackground)
        .cornerRadius(10)
    }
}

#Preview {
    ParkEventWideCardView(event: .mock.first!) {}
        .padding()
        .preferredColorScheme(.dark)
} 