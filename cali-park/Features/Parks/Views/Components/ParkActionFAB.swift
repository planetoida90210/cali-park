import SwiftUI

// MARK: - ParkActionFAB
struct ParkActionFAB: View {
    @ObservedObject var viewModel: ParkActionRowViewModel

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Expanded row when FAB tapped
            if viewModel.isExpanded {
                expandedRow
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            // Main FAB button
            Button(action: viewModel.toggleFABExpansion) {
                Image(systemName: viewModel.isExpanded ? "xmark" : "ellipsis")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.black)
                    .frame(width: 56, height: 56)
                    .background(Color.accent)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isExpanded)
    }

    // MARK: - Expanded Row
    private var expandedRow: some View {
        HStack(spacing: 12) {
            miniActionButton(icon: "map", action: viewModel.handleNavigate)
            miniActionButton(icon: "plus", action: viewModel.handleAddLog)
            miniActionButton(icon: "exclamationmark.bubble", action: viewModel.handleReport)
        }
        .padding(.trailing, 72) // leave space for main FAB
    }

    private func miniActionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(Color.componentBackground)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        ParkActionFAB(viewModel: {
            let vm = ParkActionRowViewModel()
            return vm
        }())
        .padding(24)
    }
    .preferredColorScheme(.dark)
} 