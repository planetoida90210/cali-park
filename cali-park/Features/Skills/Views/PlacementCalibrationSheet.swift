import SwiftUI

// MARK: - PlacementCalibrationSheet
/// The placement form as a sheet, for athletes who did not set their level at
/// onboarding or want to adjust it later.
///
/// Presented on first contact with the Skills tab and from "Ustaw poziom" in a
/// path's detail (SK5 wires those entry points). Saving re-declares placement;
/// re-calibrating down never erases rungs already earned from logs, because the
/// engine takes the max of declaration and logs.
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
            .alert("Błąd", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // Bridges the optional `errorMessage` to a Bool binding for `.alert`.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
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
