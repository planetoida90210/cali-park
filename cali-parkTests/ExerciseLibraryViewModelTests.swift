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
        #expect(viewModel.displayedExercises == ExerciseCatalog.all)
    }
}
