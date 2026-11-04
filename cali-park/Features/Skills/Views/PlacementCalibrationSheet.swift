import SwiftUI

// MARK: - PlacementCalibrationSheet
/// The placement form as a sheet, for athletes who did not set their level at
/// onboarding or want to adjust it later.
///
/// Presented on first contact with the Skills tab and from "Ustaw poziom" in a
/// path's detail (SK5 wires those entry points). The form opens pre-filled
/// from the saved placement, and saving re-declares only the paths answered in
/// this session. Re-calibrating down never erases rungs already earned from
/// logs, because the engine takes the max of declaration and logs.
struct PlacementCalibrationSheet: View {
    @State private var viewModel: PlacementCalibrationViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: PlacementCalibrationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                PlacementFormView(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Ustaw poziom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz") { viewModel.save() }
                }
            }
            .onChange(of: viewModel.didSave) { _, didSave in
                if didSave { dismiss() }
            }
            .errorAlert($viewModel.errorMessage, hint: "Spróbuj ponownie.")
        }
    }
}

// MARK: - Preview
#Preview {
    Color.appBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PlacementCalibrationSheet(
                viewModel: PlacementCalibrationViewModel(store: InMemorySkillPlacementStore())
            )
        }
        .preferredColorScheme(.dark)
}
