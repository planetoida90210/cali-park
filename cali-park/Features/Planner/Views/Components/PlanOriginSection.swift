import SwiftUI

// MARK: - PlanOriginSection
/// Which program the plan came from, with the program's credit line.
struct PlanOriginSection: View {
    let line: String
    let credit: String

    var body: some View {
        Section {
            Label(line, systemImage: "list.bullet.clipboard")
                .foregroundStyle(Color.textPrimary)
                .listRowBackground(Color.componentBackground)
        } footer: {
            Text(credit.keptTogether)
        }
    }
}
