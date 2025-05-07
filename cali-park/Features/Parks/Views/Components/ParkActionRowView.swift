import SwiftUI

// MARK: - ActionRowOffsetKey
struct ActionRowOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - ParkActionRowView
/// Horizontal row with three large action buttons.
struct ParkActionRowView: View {
    @ObservedObject var viewModel: ParkActionRowViewModel

    var body: some View {
        HStack(spacing: 12) {
            actionButton(icon: "map", label: "Nawiguj", action: viewModel.handleNavigate)
            actionButton(icon: "plus.circle", label: "Dodaj log", action: viewModel.handleAddLog)
            actionButton(icon: "exclamationmark.bubble", label: "Zgłoś", action: viewModel.handleReport)
        }
        .padding(16)
        .background(Color.componentBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accent.opacity(0.5), lineWidth: 1)
        )
        // Publish global Y offset for scroll handling
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: ActionRowOffsetKey.self, value: proxy.frame(in: .global).minY)
            }
        )
    }

    // MARK: - Subviews
    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.accent.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ParkActionRowView(viewModel: ParkActionRowViewModel())
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 