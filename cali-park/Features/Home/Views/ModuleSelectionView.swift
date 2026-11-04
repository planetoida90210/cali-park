import SwiftUI

// MARK: - ModuleSelectionView
/// Shows, hides and reorders the Home modules. "Zmień kolejność" puts the
/// list in edit mode, where shown modules move by their handles (VoiceOver
/// supports this too). Each shown module also has "Przesuń wyżej" /
/// "Przesuń niżej" actions.
struct ModuleSelectionView: View {
    let preferences: ModulePreferences

    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if preferences.enabledModules.isEmpty {
                        Text("Na starcie nie ma żadnego modułu. Włącz moduł poniżej.")
                            .font(.bodySmall)
                            .foregroundStyle(Color.textSecondary)
                    }
                    ForEach(preferences.enabledModules) { module in
                        moduleRow(module)
                            .accessibilityActions {
                                if preferences.canMoveUp(module.id) {
                                    Button("Przesuń wyżej") { move(module, up: true) }
                                }
                                if preferences.canMoveDown(module.id) {
                                    Button("Przesuń niżej") { move(module, up: false) }
                                }
                            }
                    }
                    .onMove { source, destination in
                        preferences.move(fromOffsets: source, toOffset: destination)
                    }
                } header: {
                    Text("Na starcie")
                } footer: {
                    Text(
                        "Moduły widać na starcie w tej kolejności. Zmienisz ją przyciskiem „Zmień kolejność” albo przeciągając moduł na starcie."
                    )
                }

                if !preferences.disabledModules.isEmpty {
                    Section("Ukryte") {
                        ForEach(preferences.disabledModules) { module in
                            moduleRow(module)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.editMode, $editMode)
            .navigationTitle("Wybierz moduły")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(editMode.isEditing ? "Gotowe" : "Zmień kolejność") {
                        withAnimation {
                            editMode = editMode.isEditing ? .inactive : .active
                        }
                    }
                    .bold(editMode.isEditing)
                    .disabled(!editMode.isEditing && preferences.enabledModules.count < 2)
                }
                if !editMode.isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Gotowe") {
                            dismiss()
                        }
                    }
                }
            }
            .tint(Color.accent)
        }
    }

    private func move(_ module: HomeModule, up: Bool) {
        withAnimation {
            if up {
                preferences.moveUp(module.id)
            } else {
                preferences.moveDown(module.id)
            }
        }
        guard let index = preferences.enabledModules.firstIndex(of: module.id) else { return }
        AccessibilityNotification.Announcement(
            String(localized: "\(module.name): pozycja \(index + 1) z \(preferences.enabledModules.count)")
        ).post()
    }

    private func moduleRow(_ module: HomeModule) -> some View {
        Toggle(
            isOn: Binding(
                get: { preferences.isEnabled(module.id) },
                set: { isOn in
                    withAnimation {
                        preferences.setEnabled(isOn, for: module.id)
                    }
                }
            )
        ) {
            HStack {
                Image(systemName: module.iconName)
                    .font(.appTitle3)
                    .foregroundStyle(Color.accent)
                    .scaledIconFrame(32, relativeTo: .title3)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(module.name)
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textPrimary)

                    Text(module.description)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    ModuleSelectionView(preferences: AppEnvironment.seeded().modulePreferences)
        .preferredColorScheme(.dark)
}
