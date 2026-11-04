import SwiftUI

// MARK: - PlanNameSection
struct PlanNameSection: View {
    @Binding var name: String

    var body: some View {
        Section {
            TextField("Nazwa planu", text: $name)
                .foregroundStyle(Color.textPrimary)
                .listRowBackground(Color.componentBackground)
        } header: {
            Text("Nazwa")
        }
    }
}
