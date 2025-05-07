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

                                    LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                                        ForEach(items) { item in
                                            EquipmentGridCell(item: item)
                                                .onTapGesture { /* simple tap reserved */ }
                                                .onLongPressGesture {
                                                    selectedItem = item
                                                }
                                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                    Button {
                                                        // Report missing
                                                    } label: {
                                                        Label("Brak", systemImage: "xmark")
                                                    }
                                                    .tint(.red)

                                                    Button {
                                                        // Report damaged
                                                    } label: {
                                                        Label("Uszkodzone", systemImage: "wrench.adjustable")
                                                    }
                                                    .tint(.orange)
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 16)
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

// MARK: - Preview
#Preview {
    EquipmentSheetView(equipments: [
        "Pull-up bar", "Dip bar", "Monkey bars", "Rings", "Push-up handles",
        "Resistance bands", "Kettlebell", "Tires"
    ])
        .preferredColorScheme(.dark)
} 