import SwiftUI

// MARK: - QuickWorkoutSessionList
/// The workout's exercises. Exercises done on their own share a section; each
/// pair or circuit of the plan gets its own, with how it is done and a round
/// counter. Tapping an exercise opens its sets; swiping removes it.
struct QuickWorkoutSessionList: View {
    let viewModel: QuickWorkoutViewModel
    let onEdit: (QuickWorkoutViewModel.DraftItem) -> Void

    var body: some View {
        let blocks = viewModel.blocks
        List {
            ForEach(blocks) { block in
                Section {
                    ForEach(block.items) { item in
                        Button {
                            onEdit(item)
                        } label: {
                            QuickWorkoutItemRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("quickWorkout.item.\(item.exercise.id.uuidString)")
                        .listRowBackground(Color.componentBackground)
                        .listRowSeparatorTint(Color.divider)
                    }
                    .onDelete { offsets in
                        let doomed = offsets.map { block.items[$0] }
                        for item in doomed { viewModel.remove(item) }
                    }

                    if case .group(let number) = block.kind, let tracker = viewModel.groups[number]?.tracker {
                        RoundTrackerRow(
                            tracker: tracker,
                            onFinishRound: { viewModel.finishRound(inGroup: number) },
                            onEndRest: { viewModel.endRest(inGroup: number) }
                        )
                        .listRowBackground(Color.componentBackground)
                    }
                } header: {
                    if case .group(let number) = block.kind, let group = viewModel.groups[number] {
                        SessionGroupHeader(group: group)
                    }
                } footer: {
                    if block.id == blocks.last?.id {
                        Text("\(PolishPlural.exercises(viewModel.exerciseCount)) · \(PolishPlural.sets(viewModel.totalSets))")
                            .font(.bodySmall)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}
