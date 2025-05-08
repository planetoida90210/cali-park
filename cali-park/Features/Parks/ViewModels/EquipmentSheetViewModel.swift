import SwiftUI
import Combine

// MARK: - EquipmentSheetViewModel
/// Handles search and filtering logic for `EquipmentSheetView`.
final class EquipmentSheetViewModel: ObservableObject {
    // MARK: Input
    @Published var searchText: String = ""
    @Published var selectedCategory: EquipmentCategory? = nil // nil → all

    // MARK: Output
    @Published private(set) var filteredItems: [EquipmentItem] = []

    // MARK: Private
    private let allItems: [EquipmentItem]
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init
    init(equipments: [String]) {
        self.allItems = EquipmentItem.items(from: equipments)
        bindInputs()
    }

    // MARK: - Binding
    private func bindInputs() {
        Publishers.CombineLatest($searchText.removeDuplicates(), $selectedCategory.removeDuplicates())
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in self?.applyFilters() }
            .store(in: &cancellables)

        // Initial load
        applyFilters()
    }

    // MARK: - Filtering
    private func applyFilters() {
        filteredItems = allItems.filter { item in
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory!
            let matchesSearch = searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    // Helper for segmented picker titles
    var categoryOptions: [EquipmentCategory?] {
        [nil] + EquipmentCategory.allCases
    }
} 