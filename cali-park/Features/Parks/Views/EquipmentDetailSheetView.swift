import SwiftUI

// MARK: - EquipmentDetailSheetView
/// Presents details about a piece of equipment (placeholder content for now).
struct EquipmentDetailSheetView: View {
    let item: EquipmentItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: item.symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accent)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.componentBackground)
                    )

                Text(item.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.textPrimary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Opis")
                        .font(.headline)
                    Text("Krótki opis działania sprzętu. Tutaj w przyszłości pobierzemy dane z backendu, wraz z linkiem do wideo instruktażowego.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }

                // Actions
                VStack(spacing: 12) {
                    Button(action: openDemoVideo) {
                        Label("Zobacz instruktaż (YouTube)", systemImage: "play.circle")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button(action: { /* TODO: integrate */ }) {
                        Label("Zgłoś uszkodzenie", systemImage: "wrench.adjustable")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button(action: { /* TODO: integrate */ }) {
                        Label("Nie ma tego sprzętu", systemImage: "xmark")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openDemoVideo() {
        // Placeholder – future deep link.
    }
}

// MARK: - Preview
#Preview {
    EquipmentDetailSheetView(item: EquipmentItem(name: "Pull-up bar", category: .strength, symbol: "figure.pullup"))
        .preferredColorScheme(.dark)
} 