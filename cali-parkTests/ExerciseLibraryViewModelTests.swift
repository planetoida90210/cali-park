//
//  ExerciseLibraryViewModelTests.swift
//  cali-parkTests
//
//  Sprint 2 — category filter and search in the exercise library.
//

import Foundation
import Testing
@testable import cali_park

@MainActor
struct ExerciseLibraryViewModelTests {
    /// Small fixed catalog so expectations don't shift when the real
    /// catalog grows.
    private static let fixtures: [Exercise] = [
        Exercise(
            id: UUID(uuidString: "F0000000-0000-4000-8000-000000000001")!,
            name: "Podciągnięcia",
            category: .basic,
            muscleGroups: [.back, .arms],
            description: "Test",
            instructions: ["a", "b", "c"],
            symbolName: "figure.climbing"
        ),
        Exercise(
            id: UUID(uuidString: "F0000000-0000-4000-8000-000000000002")!,
            name: "Pompki",
            category: .basic,
            muscleGroups: [.chest],
            description: "Test",
            instructions: ["a", "b", "c"],
            symbolName: "figure.strengthtraining.functional"
        ),
        Exercise(
            id: UUID(uuidString: "F0000000-0000-4000-8000-000000000003")!,
            name: "Podciągnięcia łucznicze",
            category: .advanced,
            muscleGroups: [.back, .arms],
            description: "Test",
            instructions: ["a", "b", "c"],
            symbolName: "figure.climbing"
        ),
        Exercise(
            id: UUID(uuidString: "F0000000-0000-4000-8000-000000000004")!,
            name: "Muscle-up",
            category: .expert,
            muscleGroups: [.back, .chest, .arms],
            description: "Test",
            instructions: ["a", "b", "c"],
            symbolName: "figure.gymnastics"
        )
    ]

    private func makeViewModel() -> ExerciseLibraryViewModel {
        ExerciseLibraryViewModel(exercises: Self.fixtures)
    }

    // MARK: Defaults

    @Test
    func showsFullCatalogByDefault() {
        let viewModel = makeViewModel()
        #expect(viewModel.displayedExercises == Self.fixtures)
    }

    // MARK: Category filter

    @Test(arguments: [
        (ExerciseCategory.basic, ["Podciągnięcia", "Pompki"]),
        (ExerciseCategory.advanced, ["Podciągnięcia łucznicze"]),
        (ExerciseCategory.expert, ["Muscle-up"])
    ])
    func filtersByCategory(category: ExerciseCategory, expectedNames: [String]) {
        let viewModel = makeViewModel()
        viewModel.selectedCategory = category
        #expect(viewModel.displayedExercises.map(\.name) == expectedNames)
    }

    @Test
    func clearingCategoryRestoresFullList() {
        let viewModel = makeViewModel()
        viewModel.selectedCategory = .expert
        viewModel.selectedCategory = nil
        #expect(viewModel.displayedExercises == Self.fixtures)
    }

    // MARK: Search

    @Test(arguments: [
        ("pompki", ["Pompki"]),
        ("podciągnięcia", ["Podciągnięcia", "Podciągnięcia łucznicze"]),
        ("podciagniecia", ["Podciągnięcia", "Podciągnięcia łucznicze"]),  // diacritic-insensitive
        ("MUSCLE", ["Muscle-up"]),                                        // case-insensitive
        ("  pompki  ", ["Pompki"]),                                       // trims whitespace
        ("kettlebell", [])
    ])
    func filtersBySearchText(query: String, expectedNames: [String]) {
        let viewModel = makeViewModel()
        viewModel.searchText = query
        #expect(viewModel.displayedExercises.map(\.name) == expectedNames)
    }

    @Test
    func whitespaceOnlySearchShowsEverything() {
        let viewModel = makeViewModel()
        viewModel.searchText = "   "
        #expect(viewModel.displayedExercises == Self.fixtures)
    }

    // MARK: Combined

    @Test
    func categoryAndSearchCombine() {
        let viewModel = makeViewModel()
        viewModel.selectedCategory = .basic
        viewModel.searchText = "podciągnięcia"
        #expect(viewModel.displayedExercises.map(\.name) == ["Podciągnięcia"])
    }

    @Test
    func productionCatalogIsTheDefaultSource() {
        let viewModel = ExerciseLibraryViewModel()
        #expect(viewModel.displayedExercises == ExerciseCatalog.mainMovements)
    }

    @Test
    func variantsAreHiddenFromTheLibrary() {
        // A variant injected alongside main movements must not surface — the
        // library only lists movements with `variantOf == nil`.
        let variant = Exercise(
            id: UUID(uuidString: "F0000000-0000-4000-8000-0000000000FF")!,
            name: "Negatywy podciągnięć",
            category: .basic,
            muscleGroups: [.back],
            description: "Test",
            instructions: ["a", "b", "c"],
            symbolName: "figure.climbing",
            variantOf: Self.fixtures[0].id
        )
        let viewModel = ExerciseLibraryViewModel(exercises: Self.fixtures + [variant])
        #expect(viewModel.displayedExercises == Self.fixtures)
    }
}

// MARK: - Quick-workout picker (variant-aware)

@MainActor
struct ExercisePickerSearchTests {
    private static let pullUps = Exercise(
        id: UUID(uuidString: "F1000000-0000-4000-8000-000000000001")!,
        name: "Podciągnięcia",
        category: .basic,
        muscleGroups: [.back, .arms],
        description: "Test",
        instructions: ["a"],
        symbolName: "figure.climbing"
    )

    private static let pushUps = Exercise(
        id: UUID(uuidString: "F1000000-0000-4000-8000-000000000002")!,
        name: "Pompki",
        category: .basic,
        muscleGroups: [.chest],
        description: "Test",
        instructions: ["a"],
        symbolName: "figure.strengthtraining.functional"
    )

    private static let negatives = Exercise(
        id: UUID(uuidString: "F1000000-0000-4000-8000-000000000003")!,
        name: "Negatywy podciągnięć",
        category: .basic,
        muscleGroups: [.back],
        description: "Test",
        instructions: ["a"],
        symbolName: "figure.climbing",
        variantOf: pullUps.id
    )

    private static let chestToBar = Exercise(
        id: UUID(uuidString: "F1000000-0000-4000-8000-000000000004")!,
        name: "Podciągnięcia do klatki",
        category: .advanced,
        muscleGroups: [.back, .arms],
        description: "Test",
        instructions: ["a"],
        symbolName: "figure.climbing",
        variantOf: pullUps.id
    )

    private func makeViewModel() -> ExerciseLibraryViewModel {
        ExerciseLibraryViewModel(exercises: [Self.pullUps, Self.pushUps, Self.negatives, Self.chestToBar])
    }

    @Test
    func emptySearchListsOnlyMainMovements() {
        let viewModel = makeViewModel()
        #expect(viewModel.pickerExercises == [Self.pullUps, Self.pushUps])
    }

    @Test
    func searchFindsVariantsTheLibraryHides() {
        let viewModel = makeViewModel()
        viewModel.searchText = "negatywy"

        #expect(viewModel.pickerExercises == [Self.negatives])
        #expect(viewModel.displayedExercises.isEmpty)
    }

    @Test
    func searchListsMovementsAndVariantsInCatalogOrder() {
        let viewModel = makeViewModel()
        viewModel.searchText = "podciag"   // diacritic-insensitive

        #expect(viewModel.pickerExercises == [Self.pullUps, Self.negatives, Self.chestToBar])
    }

    @Test
    func categoryFilterAppliesToVariantResults() {
        let viewModel = makeViewModel()
        viewModel.searchText = "podciąg"
        viewModel.selectedCategory = .advanced

        #expect(viewModel.pickerExercises == [Self.chestToBar])
    }

    @Test
    func variantsNameTheirParentMovement() {
        let viewModel = makeViewModel()

        #expect(viewModel.parent(of: Self.negatives) == Self.pullUps)
        #expect(viewModel.parent(of: Self.pullUps) == nil)
    }

    @Test
    func onlyMovementsWithVariantsAskForOne() {
        let viewModel = makeViewModel()

        #expect(viewModel.hasVariants(Self.pullUps))
        #expect(!viewModel.hasVariants(Self.pushUps))
        #expect(!viewModel.hasVariants(Self.negatives))
    }

    @Test
    func variantChoicesPutTheBaseMovementFirst() {
        let viewModel = makeViewModel()

        #expect(viewModel.variantChoices(for: Self.pullUps) == [Self.pullUps, Self.negatives, Self.chestToBar])
        #expect(viewModel.variantChoices(for: Self.pushUps) == [Self.pushUps])
    }

    @Test
    func productionCatalogFindsDiamondPushUps() throws {
        let viewModel = ExerciseLibraryViewModel()
        viewModel.searchText = "diamentowe"

        let result = try #require(viewModel.pickerExercises.first)
        #expect(result.id == ExerciseCatalog.diamondPushUpsID)
        #expect(viewModel.parent(of: result)?.id == ExerciseCatalog.pushUpsID)
    }
}
