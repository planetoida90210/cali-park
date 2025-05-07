import SwiftUI

// MARK: - EquipmentSheetView
/// Prosty arkusz z listą pełnego wyposażenia parku.
struct EquipmentSheetView: View {
    // MARK: Properties
    let equipments: [String]
    @Environment(\.dismiss) private var dismiss

    // ViewModel
    @StateObject private var viewModel: EquipmentSheetViewModel

    // Sheet presentation
    @State private var selectedItem: EquipmentItem?

    // Init to inject equipments into VM
    init(equipments: [String]) {
        self.equipments = equipments
        _viewModel = StateObject(wrappedValue: EquipmentSheetViewModel(equipments: equipments))
    }

    // Grid 2 × n
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    // Grouped view-model items
    private var grouped: [(EquipmentCategory, [EquipmentItem])] {
        Dictionary(grouping: viewModel.filteredItems, by: \.category)
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
    }

    // MARK: Body
    var body: some View {
        NavigationStack {
            Group {
                if equipments.isEmpty {
                    ContentUnavailableView("Brak danych", systemImage: "exclamationmark.triangle")
                } else {
                    ScrollView {
                        // Category Picker
                        Picker("Kategoria", selection: $viewModel.selectedCategory) {
                            Text("Wszystkie").tag(Optional<EquipmentCategory>.none)
                            ForEach(EquipmentCategory.allCases) { cat in
                                Text(cat.title).tag(Optional(cat))
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(grouped, id: \.0) { category, items in
                                if !items.isEmpty {
                                    Text(category.title)
                                        .font(.headline)
                                        .padding(.horizontal, 16)
                                        .accessibilityAddTraits(.isHeader)

                                    CategorySection(items: items) { selected in
                                        selectedItem = selected
                                    }
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("Wyposażenie")
            .searchable(text: $viewModel.searchText, prompt: "Szukaj drążka…")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zamknij") { dismiss() } }
            }
            .sheet(item: $selectedItem) { item in
                NavigationStack {
                    EquipmentDetailSheetView(item: item)
                }
            }
        }
    }
}

// MARK: - EquipmentGridCell
private struct EquipmentGridCell: View {
    let item: EquipmentItem

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: item.symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accent)
            Text(item.name)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.textPrimary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - SwipeableEquipmentTile
/// Wraps `EquipmentGridCell` with custom horizontal swipe to reveal action buttons (works outside List).
private struct SwipeableEquipmentTile: View {
    let item: EquipmentItem
    let onReportMissing: () -> Void
    let onReportDamaged: () -> Void
    let onLongPress: () -> Void

    // gesture state
    @State private var offset: CGFloat = 0
    @GestureState private var translation: CGFloat = 0

    private let actionWidth: CGFloat = 140.0 // 2 × 70

    init(item: EquipmentItem,
         onReportMissing: @escaping () -> Void,
         onReportDamaged: @escaping () -> Void,
         onLongPress: @escaping () -> Void) {
        self.item = item
        self.onReportMissing = onReportMissing
        self.onReportDamaged = onReportDamaged
        self.onLongPress = onLongPress
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            actionButtons
            draggableTile
        }
    }

    // MARK: Subviews
    private var actionButtons: some View {
        HStack(spacing: 0) {
            Button {
                onReportDamaged(); close()
            } label: {
                Label("Uszk.", systemImage: "wrench.adjustable")
                    .font(.caption2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundColor(.white)
            }
            .frame(width: 70)
            .background(Color.orange)

            Button {
                onReportMissing(); close()
            } label: {
                Label("Brak", systemImage: "xmark")
                    .font(.caption2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundColor(.white)
            }
            .frame(width: 70)
            .background(Color.red)
        }
        .frame(height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .updating($translation) { value, state, _ in
                if abs(value.translation.width) > abs(value.translation.height) {
                    let raw = -value.translation.width
                    state = clamp(raw + offset, 0, actionWidth)
                }
            }
            .onEnded { value in
                let newOffset = clamp(offset + -value.translation.width, 0, actionWidth)
                let shouldOpen = newOffset > actionWidth * 0.5
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    offset = shouldOpen ? actionWidth : 0
                }
            }
    }

    private var draggableTile: some View {
        EquipmentGridCell(item: item)
            .offset(x: -offset + translation)
            .gesture(drag)
            .onLongPressGesture { onLongPress() }
    }

    private func close() {
        withAnimation(.easeOut) { offset = 0 }
    }

    private func clamp(_ value: CGFloat, _ min: CGFloat, _ max: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, min), max)
    }
}

// MARK: - Preview
#Preview {
    EquipmentSheetView(equipments: [
        "Pull-up bar", "Dip bar", "Monkey bars", "Rings", "Push-up handles",
        "Resistance bands", "Kettlebell", "Tires"
    ])
        .preferredColorScheme(.dark)
}

// MARK: - CategorySection
private struct CategorySection: View {
    let items: [EquipmentItem]
    let onSelect: (EquipmentItem) -> Void

    // Grid 2 × n locally
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
            ForEach(items) { item in
                SwipeableEquipmentTile(
                    item: item,
                    onReportMissing: {},
                    onReportDamaged: {},
                    onLongPress: { onSelect(item) }
                )
            }
        }
        .padding(.horizontal, 16)
    }
} 