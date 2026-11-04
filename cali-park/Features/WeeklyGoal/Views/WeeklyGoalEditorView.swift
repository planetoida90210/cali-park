import SwiftUI

// MARK: - WeeklyGoalEditorView
/// The weekly goal editor: one to three goals (the starred one is primary) and
/// the pause. Goal changes are a draft saved with "Gotowe"; a pause applies at
/// once. Present it in a sheet; it brings its own `NavigationStack`.
struct WeeklyGoalEditorView: View {
    @State private var viewModel: WeeklyGoalEditorViewModel
    @State private var path: [WeeklyGoal.ID] = []
    @Environment(\.dismiss) private var dismiss

    init(viewModel: WeeklyGoalEditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                WeeklyGoalListSection(viewModel: viewModel, onOpen: { path.append($0) })
                WeeklyGoalPauseSection(viewModel: viewModel)
            }
            .navigationTitle("Cel tygodniowy")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: WeeklyGoal.ID.self) { id in
                WeeklyGoalDetailView(viewModel: viewModel, goalID: id)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    DiscardDraftButton(
                        hasUnsavedChanges: viewModel.hasUnsavedChanges,
                        title: "Odrzucić zmiany celu?",
                        message: "Zmienione cele nie zostaną zapisane.",
                        onDiscard: { dismiss() }
                    )
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gotowe") {
                        if viewModel.save() { dismiss() }
                    }
                    .disabled(viewModel.hasUnsavedChanges && !viewModel.canSave)
                }
            }
            .errorAlert($viewModel.errorMessage)
        }
        // Reads the saved goals when the sheet appears, not when the view
        // model is built; returning from a goal's detail keeps the draft.
        .onAppear { viewModel.load() }
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
    }
}

// MARK: - WeeklyGoalListSection
/// The goals, primary first, with add / remove / make-primary actions.
private struct WeeklyGoalListSection: View {
    let viewModel: WeeklyGoalEditorViewModel
    let onOpen: (WeeklyGoal.ID) -> Void

    var body: some View {
        Section {
            ForEach(viewModel.goals) { goal in
                let isPrimary = viewModel.isPrimary(goal.id)
                NavigationLink(value: goal.id) {
                    WeeklyGoalEditorRow(goal: goal, isPrimary: isPrimary)
                }
                .disabled(!viewModel.canEdit)
                .swipeActions(edge: .leading) {
                    if !isPrimary && viewModel.canEdit {
                        Button("Główny", systemImage: "star.fill") { viewModel.makePrimary(goal.id) }
                            .tint(Color.accent)
                    }
                }
                .swipeActions(edge: .trailing) {
                    if viewModel.canRemoveGoals {
                        Button("Usuń", systemImage: "trash", role: .destructive) { viewModel.removeGoal(goal.id) }
                    }
                }
                .accessibilityActions {
                    if !isPrimary && viewModel.canEdit {
                        Button("Ustaw jako główny") { viewModel.makePrimary(goal.id) }
                    }
                    if viewModel.canRemoveGoals {
                        Button("Usuń cel") { viewModel.removeGoal(goal.id) }
                    }
                }
            }

            if viewModel.canAddGoal {
                Menu("Dodaj cel", systemImage: "plus.circle.fill") {
                    ForEach(WeeklyGoal.Kind.allCases) { kind in
                        Button(kind.displayName, systemImage: kind.symbolName) {
                            if let id = viewModel.addGoal(kind) { onOpen(id) }
                        }
                    }
                }
                .foregroundStyle(Color.accent)
            }
        } header: {
            Text("Cele (\(viewModel.goals.count) z \(WeeklyGoal.maximumCount))")
        } footer: {
            Text(footer)
        }
    }

    private var footer: String {
        let text = String(localized: """
            Cel z gwiazdką jest główny: wypełnia pierścień na starcie i liczy serię tygodni. \
            Zmiana działa od razu na bieżący tydzień, zamknięte tygodnie zostają bez zmian. \
            Tydzień trwa od poniedziałku do niedzieli.
            """)
        guard viewModel.isDefault else { return text }
        return text + " " + String(localized: "Na razie obowiązuje cel domyślny.")
    }
}

// MARK: - WeeklyGoalEditorRow
private struct WeeklyGoalEditorRow: View {
    let goal: WeeklyGoal
    let isPrimary: Bool

    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 28

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: goal.metric.kind.symbolName)
                .foregroundStyle(Color.accent)
                .frame(width: iconWidth)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(WeeklyGoalFormat.title(goal.metric))
                    .foregroundStyle(Color.textPrimary)
                Text(goal.metric.kind.displayName)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 8)

            if isPrimary {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.accent)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let title = WeeklyGoalFormat.spokenTitle(goal.metric)
        return isPrimary ? String(localized: "\(title), cel główny") : title
    }
}

// MARK: - Preview
#Preview {
    WeeklyGoalEditorView(viewModel: AppEnvironment.previewEmpty.makeWeeklyGoalEditorViewModel())
        .preferredColorScheme(.dark)
}
