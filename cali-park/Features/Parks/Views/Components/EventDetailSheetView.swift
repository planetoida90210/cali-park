import SwiftUI

// MARK: - EventDetailSheetView
struct EventDetailSheetView: View {
    let event: ParkEvent
    let onJoin: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.gray.opacity(0.4)).frame(width: 40, height: 4)
                .padding(.top, 8)
            Text(event.title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.accent)
                .padding(.horizontal)
            Text(event.formattedDate)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
            HStack(spacing: 6) {
                Image(systemName: "person.3.fill")
                Text("\(event.attendeeCount) uczestników")
            }
            .font(.caption)
            .foregroundColor(.textSecondary)
            Spacer()
            Button(action: {
                dismiss(); onJoin()
            }) {
                Text("Dołącz do wydarzenia")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accent)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

#Preview {
    EventDetailSheetView(event: .mock.first!, onJoin: {})
        .preferredColorScheme(.dark)
} 