import Foundation

// MARK: - ExerciseCatalog
/// Built-in, production catalog of calisthenics exercises (not mock data).
/// Identifiers are fixed UUIDs so `WorkoutLogEntry.exerciseID` references stay
/// valid across app launches and future catalog additions — never reorder or
/// reuse an ID, only append new ones.
///
/// SF Symbols come from the `figure.*` family; there is no dedicated pull-up
/// symbol, so the closest match is picked per exercise.
enum ExerciseCatalog {
    // MARK: Stable identifiers
    static let pullUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000001")!
    static let pushUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000002")!
    static let dipsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000003")!
    static let squatsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000004")!
    static let lungesID = UUID(uuidString: "E0000000-0000-4000-8000-000000000005")!
    static let plankID = UUID(uuidString: "E0000000-0000-4000-8000-000000000006")!
    static let australianPullUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000007")!
    static let hangingLegRaisesID = UUID(uuidString: "E0000000-0000-4000-8000-000000000008")!
    static let pistolSquatsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000009")!
    static let wallHandstandPushUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000010")!
    static let lSitID = UUID(uuidString: "E0000000-0000-4000-8000-000000000011")!
    static let archerPullUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000012")!
    static let ringDipsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000013")!
    static let bridgeID = UUID(uuidString: "E0000000-0000-4000-8000-000000000014")!
    static let muscleUpID = UUID(uuidString: "E0000000-0000-4000-8000-000000000015")!
    static let frontLeverID = UUID(uuidString: "E0000000-0000-4000-8000-000000000016")!
    static let humanFlagID = UUID(uuidString: "E0000000-0000-4000-8000-000000000017")!
    static let plancheID = UUID(uuidString: "E0000000-0000-4000-8000-000000000018")!
    static let backLeverID = UUID(uuidString: "E0000000-0000-4000-8000-000000000019")!

    // MARK: Lookup
    /// Fast lookup used by log history and Home modules.
    static func exercise(withID id: UUID) -> Exercise? {
        byID[id]
    }

    private static let byID: [UUID: Exercise] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )

    // MARK: Catalog
    static let all: [Exercise] = [
        // MARK: Podstawowe
        Exercise(
            id: pullUpsID,
            name: "Podciągnięcia",
            category: .basic,
            muscleGroups: [.back, .arms],
            description: "Fundament kalisteniki. Buduje siłę pleców, bicepsów i chwytu.",
            instructions: [
                "Chwyć drążek nachwytem na szerokość barków.",
                "Zwis z wyprostowanych ramion, napnij łopatki.",
                "Podciągnij się, aż broda znajdzie się nad drążkiem.",
                "Opuść się powoli do pełnego zwisu."
            ],
            symbolName: "figure.climbing",
            equipment: ["Pull-up bar"]
        ),
        Exercise(
            id: pushUpsID,
            name: "Pompki",
            category: .basic,
            muscleGroups: [.chest, .arms, .core],
            description: "Klasyka pracy z masą ciała. Wzmacnia klatkę, triceps i core.",
            instructions: [
                "Podpór przodem, dłonie pod barkami, ciało w linii prostej.",
                "Napnij brzuch i pośladki.",
                "Opuść klatkę tuż nad ziemię, łokcie blisko tułowia.",
                "Wypchnij się do pełnego wyprostu ramion."
            ],
            symbolName: "figure.strengthtraining.functional"
        ),
        Exercise(
            id: dipsID,
            name: "Dipy",
            category: .basic,
            muscleGroups: [.chest, .arms, .shoulders],
            description: "Podstawowe ćwiczenie pchające na poręczach. Mocno angażuje triceps i dolną część klatki.",
            instructions: [
                "Podpór na poręczach z wyprostowanymi ramionami.",
                "Pochyl tułów lekko do przodu.",
                "Opuść się, aż ramiona będą równolegle do ziemi.",
                "Wypchnij się dynamicznie do góry."
            ],
            symbolName: "figure.strengthtraining.traditional",
            equipment: ["Dip bar", "Parallel bars"]
        ),
        Exercise(
            id: squatsID,
            name: "Przysiady",
            category: .basic,
            muscleGroups: [.legs],
            description: "Podstawa treningu nóg bez sprzętu. Wzmacnia uda i pośladki.",
            instructions: [
                "Stań na szerokość bioder, stopy lekko na zewnątrz.",
                "Zejdź biodrami w dół, kolana podążają za palcami stóp.",
                "Zatrzymaj się poniżej równoległej, plecy proste.",
                "Wstań, napinając pośladki."
            ],
            symbolName: "figure.strengthtraining.functional"
        ),
        Exercise(
            id: lungesID,
            name: "Wykroki",
            category: .basic,
            muscleGroups: [.legs, .core],
            description: "Jednostronna praca nóg poprawiająca siłę i równowagę.",
            instructions: [
                "Zrób długi krok do przodu.",
                "Opuść tylne kolano tuż nad ziemię.",
                "Tułów pionowo, przednie kolano nad stopą.",
                "Odepchnij się i wróć do pozycji wyjściowej."
            ],
            symbolName: "figure.strengthtraining.functional"
        ),
        Exercise(
            id: plankID,
            name: "Deska",
            category: .basic,
            muscleGroups: [.core],
            description: "Izometryczny fundament stabilizacji tułowia.",
            instructions: [
                "Podpór na przedramionach, łokcie pod barkami.",
                "Ciało w linii prostej od głowy do pięt.",
                "Napnij brzuch i pośladki, nie opuszczaj bioder.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.core.training"
        ),
        Exercise(
            id: australianPullUpsID,
            name: "Podciągnięcia australijskie",
            category: .basic,
            muscleGroups: [.back, .arms],
            description: "Poziome przyciąganie na niskim drążku. Idealny wstęp do pełnych podciągnięć.",
            instructions: [
                "Wejdź pod niski drążek, chwyć go nachwytem.",
                "Ciało proste, pięty na ziemi.",
                "Przyciągnij klatkę do drążka, ściągając łopatki.",
                "Opuść się powoli do wyprostu ramion."
            ],
            symbolName: "figure.play",
            equipment: ["Pull-up bar", "Parallel bars"]
        ),

        // MARK: Zaawansowane
        Exercise(
            id: hangingLegRaisesID,
            name: "Wznosy nóg w zwisie",
            category: .advanced,
            muscleGroups: [.core, .arms],
            description: "Dynamiczna praca brzucha w zwisie na drążku. Buduje siłę core i chwytu.",
            instructions: [
                "Zwis na drążku z wyprostowanych ramion.",
                "Unieś proste nogi do poziomu lub wyżej.",
                "Kontroluj ruch — bez bujania.",
                "Opuść nogi powoli do zwisu."
            ],
            symbolName: "figure.core.training",
            equipment: ["Pull-up bar"]
        ),
        Exercise(
            id: pistolSquatsID,
            name: "Pistolety",
            category: .advanced,
            muscleGroups: [.legs, .core],
            description: "Przysiad na jednej nodze. Wymaga siły, mobilności i równowagi.",
            instructions: [
                "Stań na jednej nodze, drugą wyprostuj przed sobą.",
                "Zejdź powoli do pełnego przysiadu.",
                "Ręce przed sobą dla równowagi.",
                "Wstań bez odbicia i dotykania ziemi drugą nogą."
            ],
            symbolName: "figure.strengthtraining.functional"
        ),
        Exercise(
            id: wallHandstandPushUpsID,
            name: "Pompki w staniu na rękach",
            category: .advanced,
            muscleGroups: [.shoulders, .arms, .core],
            description: "Pionowe pchanie przy ścianie. Najskuteczniejszy budulec siły barków w kalistenice.",
            instructions: [
                "Wejdź w stanie na rękach przodem lub tyłem do ściany.",
                "Napnij całe ciało, palce rozłożone szeroko.",
                "Opuść głowę tuż nad ziemię.",
                "Wypchnij się do pełnego wyprostu ramion."
            ],
            symbolName: "figure.gymnastics"
        ),
        Exercise(
            id: lSitID,
            name: "L-sit",
            category: .advanced,
            muscleGroups: [.core, .arms],
            description: "Izometryczny podpór z nogami w poziomie. Wymaga silnego core i tricepsów.",
            instructions: [
                "Podpór na poręczach z wyprostowanymi ramionami.",
                "Unieś proste nogi do poziomu.",
                "Wciśnij barki w dół, nie garb się.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.core.training",
            equipment: ["Parallel bars", "Push-up handles"]
        ),
        Exercise(
            id: archerPullUpsID,
            name: "Podciągnięcia łucznicze",
            category: .advanced,
            muscleGroups: [.back, .arms],
            description: "Podciągnięcia z przenoszeniem ciężaru na jedną rękę. Krok w stronę podciągnięć jednorącz.",
            instructions: [
                "Chwyć drążek szerokim nachwytem.",
                "Podciągnij się w stronę jednej ręki, druga prostuje się w bok.",
                "Broda nad drążkiem przy ręce pracującej.",
                "Opuść się powoli i zmień stronę."
            ],
            symbolName: "figure.climbing",
            equipment: ["Pull-up bar"]
        ),
        Exercise(
            id: ringDipsID,
            name: "Dipy na kółkach",
            category: .advanced,
            muscleGroups: [.chest, .arms, .shoulders],
            description: "Dipy na niestabilnych kółkach. Znacznie trudniejsze niż na poręczach.",
            instructions: [
                "Podpór na kółkach, dłonie przy biodrach.",
                "Ustabilizuj kółka przy tułowiu.",
                "Opuść się kontrolowanie do kąta prostego w łokciach.",
                "Wypchnij się, obracając dłonie na zewnątrz w górze."
            ],
            symbolName: "figure.strengthtraining.traditional",
            equipment: ["Rings"]
        ),
        Exercise(
            id: bridgeID,
            name: "Mostek",
            category: .advanced,
            muscleGroups: [.back, .shoulders, .legs],
            description: "Głębokie otwarcie klatki i barków. Buduje mobilność i siłę całego łańcucha tylnego.",
            instructions: [
                "Połóż się na plecach, stopy przy pośladkach.",
                "Dłonie przy uszach, palce w stronę stóp.",
                "Wypchnij biodra i klatkę w górę do pełnego wyprostu ramion.",
                "Zejdź powoli, odcinek po odcinku."
            ],
            symbolName: "figure.flexibility"
        ),

        // MARK: Ekspert
        Exercise(
            id: muscleUpID,
            name: "Muscle-up",
            category: .expert,
            muscleGroups: [.back, .chest, .arms],
            description: "Podciągnięcie przechodzące w dipa nad drążkiem. Wizytówka street workoutu.",
            instructions: [
                "Chwyć drążek nachwytem, lekko szerzej niż barki.",
                "Wykonaj eksplozywne podciągnięcie z klatką do drążka.",
                "Przejdź nadgarstkami nad drążek i pochyl się do przodu.",
                "Dokończ ruch wyprostem ramion jak w dipie."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"]
        ),
        Exercise(
            id: frontLeverID,
            name: "Front lever",
            category: .expert,
            muscleGroups: [.back, .core],
            description: "Poziomy zwis przodem z ciałem w linii prostej. Ekstremalna siła pleców i core.",
            instructions: [
                "Zwis na drążku nachwytem.",
                "Napnij łopatki i całe ciało.",
                "Unieś ciało do poziomu, biodra w linii z barkami.",
                "Utrzymaj linię prostą — bez zwieszania bioder."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"]
        ),
        Exercise(
            id: humanFlagID,
            name: "Flaga",
            category: .expert,
            muscleGroups: [.core, .shoulders, .back],
            description: "Poziome utrzymanie ciała na pionowym drążku. Ikona kalisteniki.",
            instructions: [
                "Chwyć pionowy drążek: górna ręka nachwytem, dolna podchwytem.",
                "Wypchnij się dolną ręką, przyciągnij górną.",
                "Unieś nogi do poziomu, ciało w jednej linii.",
                "Utrzymaj napięcie całego ciała."
            ],
            symbolName: "figure.climbing",
            equipment: ["Pull-up bar"]
        ),
        Exercise(
            id: plancheID,
            name: "Planche",
            category: .expert,
            muscleGroups: [.shoulders, .arms, .core],
            description: "Poziomy podpór na samych rękach. Szczyt siły pchającej w kalistenice.",
            instructions: [
                "Podpór na ziemi lub poręczach, ramiona wyprostowane.",
                "Przenieś ciężar mocno przed dłonie.",
                "Unieś nogi, ciało równolegle do ziemi.",
                "Utrzymaj protrakcję łopatek i napięcie core."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Push-up handles", "Parallel bars"]
        ),
        Exercise(
            id: backLeverID,
            name: "Back lever",
            category: .expert,
            muscleGroups: [.back, .chest, .core],
            description: "Poziomy zwis tyłem pod drążkiem. Buduje siłę do planche i front levera.",
            instructions: [
                "Zwis na drążku, przełóż nogi między rękami.",
                "Obróć się do zwisu tyłem.",
                "Opuść ciało do poziomu, twarzą do ziemi.",
                "Utrzymaj ciało w linii prostej."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"]
        )
    ]
}
