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

    // MARK: Stable identifiers — progression variants
    // Appended (never reordered) so log entries keep resolving. Each variant's
    // `variantOf` names one of the 19 main movements above.
    static let deadHangID = UUID(uuidString: "E0000000-0000-4000-8000-000000000020")!
    static let scapularPullsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000021")!
    static let negativePullUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000022")!
    static let bandPullUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000023")!
    static let chestToBarPullUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000024")!
    static let lPullUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000025")!
    static let inclineRowsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000026")!
    static let wideRowsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000027")!
    static let archerRowsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000028")!
    static let tuckFrontLeverRowsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000029")!
    static let wallPushUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000030")!
    static let inclinePushUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000031")!
    static let kneePushUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000032")!
    static let diamondPushUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000033")!
    static let pseudoPlanchePushUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000034")!
    static let parallelBarSupportID = UUID(uuidString: "E0000000-0000-4000-8000-000000000035")!
    static let negativeDipsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000036")!
    static let assistedSquatsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000037")!
    static let stepUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000038")!
    static let assistedPistolSquatsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000039")!
    static let hangingKneeRaisesID = UUID(uuidString: "E0000000-0000-4000-8000-000000000040")!
    static let toesToBarID = UUID(uuidString: "E0000000-0000-4000-8000-000000000041")!
    static let negativeMuscleUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000042")!
    static let kippingMuscleUpsID = UUID(uuidString: "E0000000-0000-4000-8000-000000000043")!
    static let footSupportedLSitID = UUID(uuidString: "E0000000-0000-4000-8000-000000000044")!
    static let oneLegLSitID = UUID(uuidString: "E0000000-0000-4000-8000-000000000045")!
    static let tuckLSitID = UUID(uuidString: "E0000000-0000-4000-8000-000000000046")!
    static let tuckFrontLeverID = UUID(uuidString: "E0000000-0000-4000-8000-000000000047")!
    static let advancedTuckFrontLeverID = UUID(uuidString: "E0000000-0000-4000-8000-000000000048")!
    static let straddleFrontLeverID = UUID(uuidString: "E0000000-0000-4000-8000-000000000049")!
    static let halfLayFrontLeverID = UUID(uuidString: "E0000000-0000-4000-8000-000000000050")!
    static let germanHangID = UUID(uuidString: "E0000000-0000-4000-8000-000000000051")!
    static let skinTheCatID = UUID(uuidString: "E0000000-0000-4000-8000-000000000052")!
    static let tuckBackLeverID = UUID(uuidString: "E0000000-0000-4000-8000-000000000053")!
    static let advancedTuckBackLeverID = UUID(uuidString: "E0000000-0000-4000-8000-000000000054")!
    static let straddleBackLeverID = UUID(uuidString: "E0000000-0000-4000-8000-000000000055")!
    static let halfLayBackLeverID = UUID(uuidString: "E0000000-0000-4000-8000-000000000056")!
    static let frogStandID = UUID(uuidString: "E0000000-0000-4000-8000-000000000057")!
    static let tuckPlancheID = UUID(uuidString: "E0000000-0000-4000-8000-000000000058")!
    static let advancedTuckPlancheID = UUID(uuidString: "E0000000-0000-4000-8000-000000000059")!
    static let straddlePlancheID = UUID(uuidString: "E0000000-0000-4000-8000-000000000060")!
    static let verticalFlagSupportID = UUID(uuidString: "E0000000-0000-4000-8000-000000000061")!
    static let tuckFlagID = UUID(uuidString: "E0000000-0000-4000-8000-000000000062")!
    static let straddleFlagID = UUID(uuidString: "E0000000-0000-4000-8000-000000000063")!
    static let wallPlankID = UUID(uuidString: "E0000000-0000-4000-8000-000000000064")!
    static let wallHandstandHoldID = UUID(uuidString: "E0000000-0000-4000-8000-000000000065")!

    // MARK: Lookup
    /// Fast lookup used by log history and Home modules.
    static func exercise(withID id: UUID) -> Exercise? {
        byID[id]
    }

    private static let byID: [UUID: Exercise] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )

    /// The main movements shown in the exercise library: the original 19,
    /// with progression variants (`variantOf != nil`) filtered out. Variants
    /// stay reachable through skill ladders and each movement's detail screen,
    /// so the library stays the same size the catalog grows.
    static let mainMovements: [Exercise] = all.filter { $0.variantOf == nil }

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
            symbolName: "figure.core.training",
            measurement: .seconds
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
            equipment: ["Parallel bars", "Push-up handles"],
            measurement: .seconds
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
            equipment: ["Pull-up bar", "Rings"],
            measurement: .seconds
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
            equipment: ["Pull-up bar"],
            measurement: .seconds
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
            equipment: ["Push-up handles", "Parallel bars"],
            measurement: .seconds
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
            equipment: ["Pull-up bar", "Rings"],
            measurement: .seconds
        ),

        // MARK: Warianty progresji
        // Appended after the original 19 movements so their catalog indices and
        // stable IDs never shift. Every variant carries `variantOf` pointing at
        // one of the 19 main movements, so it stays out of the library list and
        // lives only on its skill ladder.

        // MARK: Warianty — Podciąganie
        Exercise(
            id: deadHangID,
            name: "Zwis na drążku",
            category: .basic,
            muscleGroups: [.back, .arms],
            description: "Aktywny zwis budujący siłę chwytu i wytrzymałość barków — pierwszy krok do podciągnięcia.",
            instructions: [
                "Chwyć drążek nachwytem na szerokość barków.",
                "Zwiśnij z wyprostowanych ramion, ściągnij barki od uszu.",
                "Napnij brzuch, nie bujaj się.",
                "Utrzymaj zwis przez zaplanowany czas."
            ],
            symbolName: "figure.play",
            equipment: ["Pull-up bar"],
            measurement: .seconds,
            variantOf: pullUpsID
        ),
        Exercise(
            id: scapularPullsID,
            name: "Ściąganie łopatek w zwisie",
            category: .basic,
            muscleGroups: [.back],
            description: "Krótki ruch łopatek w zwisie. Uczy aktywacji pleców, od której zaczyna się każde podciągnięcie.",
            instructions: [
                "Zwiśnij na drążku z wyprostowanych ramion.",
                "Bez zginania łokci ściągnij łopatki w dół i do siebie.",
                "Unieś klatkę o kilka centymetrów.",
                "Wróć powoli do pełnego zwisu i powtórz."
            ],
            symbolName: "figure.climbing",
            equipment: ["Pull-up bar"],
            variantOf: pullUpsID
        ),
        Exercise(
            id: negativePullUpsID,
            name: "Negatywy podciągnięć",
            category: .basic,
            muscleGroups: [.back, .arms],
            description: "Powolne opuszczanie z góry drążka. Buduje siłę do pierwszego pełnego podciągnięcia.",
            instructions: [
                "Wejdź brodą nad drążek z podskoku lub podpórki.",
                "Napnij plecy i ramiona.",
                "Opuszczaj się jak najwolniej — celuj w 3–5 sekund.",
                "Zejdź do pełnego zwisu i powtórz."
            ],
            symbolName: "figure.climbing",
            equipment: ["Pull-up bar"],
            variantOf: pullUpsID
        ),
        Exercise(
            id: bandPullUpsID,
            name: "Podciągnięcia z gumą",
            category: .basic,
            muscleGroups: [.back, .arms],
            description: "Podciągnięcia z gumą odciążającą. Tor równoległy — pomaga, ale nie jest obowiązkowy.",
            instructions: [
                "Zaczep gumę o drążek i oprzyj na niej stopę lub kolano.",
                "Chwyć drążek nachwytem na szerokość barków.",
                "Podciągnij się brodą nad drążek, ściągając łopatki.",
                "Opuść się powoli do pełnego zwisu."
            ],
            symbolName: "figure.climbing",
            equipment: ["Pull-up bar", "Resistance bands"],
            variantOf: pullUpsID
        ),
        Exercise(
            id: chestToBarPullUpsID,
            name: "Podciągnięcia do klatki",
            category: .advanced,
            muscleGroups: [.back, .arms],
            description: "Wysokie podciągnięcia z klatką do drążka. Buduje moc potrzebną do muscle-upa.",
            instructions: [
                "Chwyć drążek nachwytem, lekko szerzej niż barki.",
                "Podciągnij się dynamicznie, aż klatka dotknie drążka.",
                "Trzymaj łokcie ciągnięte w dół i do tyłu.",
                "Opuść się z kontrolą do pełnego zwisu."
            ],
            symbolName: "figure.climbing",
            equipment: ["Pull-up bar"],
            variantOf: pullUpsID
        ),
        Exercise(
            id: lPullUpsID,
            name: "L-pull-ups",
            category: .advanced,
            muscleGroups: [.back, .arms, .core],
            description: "Podciągnięcia z nogami trzymanymi w poziomie. Łączą siłę pleców z napięciem core.",
            instructions: [
                "Zwiśnij na drążku i unieś proste nogi do poziomu (pozycja L).",
                "Utrzymując nogi w poziomie, podciągnij się brodą nad drążek.",
                "Nie opuszczaj nóg podczas ruchu.",
                "Opuść się powoli, wciąż trzymając L."
            ],
            symbolName: "figure.climbing",
            equipment: ["Pull-up bar"],
            variantOf: pullUpsID
        ),

        // MARK: Warianty — Wiosłowanie
        Exercise(
            id: inclineRowsID,
            name: "Wiosłowanie na podwyższeniu",
            category: .basic,
            muscleGroups: [.back, .arms],
            description: "Poziome przyciąganie z drążkiem wysoko. Najłagodniejszy wariant wiosłowania.",
            instructions: [
                "Ustaw drążek na wysokości bioder lub wyżej.",
                "Chwyć go i odejdź stopami tak, by ciało było proste i pochylone.",
                "Przyciągnij klatkę do drążka, ściągając łopatki.",
                "Opuść się powoli do wyprostu ramion."
            ],
            symbolName: "figure.play",
            equipment: ["Pull-up bar", "Parallel bars"],
            variantOf: australianPullUpsID
        ),
        Exercise(
            id: wideRowsID,
            name: "Wiosłowanie szerokie",
            category: .advanced,
            muscleGroups: [.back, .arms],
            description: "Australijskie wiosłowanie szerokim chwytem. Mocniej angażuje górę pleców.",
            instructions: [
                "Wejdź pod niski drążek, chwyć go szeroko nachwytem.",
                "Ciało proste, pięty na ziemi.",
                "Przyciągnij klatkę do drążka, łokcie na boki.",
                "Opuść się powoli do wyprostu ramion."
            ],
            symbolName: "figure.play",
            equipment: ["Pull-up bar", "Parallel bars"],
            variantOf: australianPullUpsID
        ),
        Exercise(
            id: archerRowsID,
            name: "Wiosłowanie łucznicze",
            category: .advanced,
            muscleGroups: [.back, .arms],
            description: "Wiosłowanie z przeniesieniem ciężaru na jedną rękę. Krok w stronę wiosłowania jednorącz.",
            instructions: [
                "Chwyć niski drążek szeroko, ciało proste.",
                "Przyciągnij się w stronę jednej ręki, druga prostuje się w bok.",
                "Klatka zbliża się do dłoni pracującej.",
                "Opuść się powoli i zmień stronę."
            ],
            symbolName: "figure.play",
            equipment: ["Pull-up bar", "Parallel bars"],
            variantOf: australianPullUpsID
        ),
        Exercise(
            id: tuckFrontLeverRowsID,
            name: "Wiosłowanie w tuck front lever",
            category: .expert,
            muscleGroups: [.back, .core, .arms],
            description: "Wiosłowanie w podkurczonej pozycji front levera. Pomost między wiosłowaniem a front leverem.",
            instructions: [
                "Zwiśnij na drążku i podkurcz kolana do klatki.",
                "Odchyl tułów do poziomu w pozycji tuck.",
                "Przyciągnij się, prowadząc mostek do drążka.",
                "Opuść się z kontrolą, trzymając tuck."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"],
            variantOf: australianPullUpsID
        ),

        // MARK: Warianty — Pompki
        Exercise(
            id: wallPushUpsID,
            name: "Pompki od ściany",
            category: .basic,
            muscleGroups: [.chest, .arms],
            description: "Pompki w pionie o ścianę. Najłagodniejszy start dla klatki i tricepsów.",
            instructions: [
                "Stań twarzą do ściany, dłonie na wysokości barków.",
                "Odejdź stopami, ciało proste i lekko pochylone.",
                "Ugnij łokcie, zbliżając klatkę do ściany.",
                "Wypchnij się do pełnego wyprostu ramion."
            ],
            symbolName: "figure.strengthtraining.traditional",
            variantOf: pushUpsID
        ),
        Exercise(
            id: inclinePushUpsID,
            name: "Pompki na podwyższeniu",
            category: .basic,
            muscleGroups: [.chest, .arms, .core],
            description: "Pompki z rękami na ławce lub schodku. Lżejsze niż pełne, cięższe niż od ściany.",
            instructions: [
                "Oprzyj dłonie na stabilnym podwyższeniu, pod barkami.",
                "Ciało w linii prostej od głowy do pięt.",
                "Opuść klatkę do krawędzi podwyższenia.",
                "Wypchnij się do pełnego wyprostu ramion."
            ],
            symbolName: "figure.strengthtraining.traditional",
            variantOf: pushUpsID
        ),
        Exercise(
            id: kneePushUpsID,
            name: "Pompki z kolan",
            category: .basic,
            muscleGroups: [.chest, .arms, .core],
            description: "Pompki z podparciem na kolanach. Skracają dźwignię, zachowując wzorzec ruchu.",
            instructions: [
                "Podpór przodem z kolanami na ziemi, stopy w górze.",
                "Dłonie pod barkami, linia prosta od głowy do kolan.",
                "Opuść klatkę tuż nad ziemię, łokcie blisko tułowia.",
                "Wypchnij się do pełnego wyprostu ramion."
            ],
            symbolName: "figure.strengthtraining.traditional",
            variantOf: pushUpsID
        ),
        Exercise(
            id: diamondPushUpsID,
            name: "Pompki diamentowe",
            category: .advanced,
            muscleGroups: [.arms, .chest],
            description: "Pompki z dłońmi blisko siebie. Mocno akcentują triceps.",
            instructions: [
                "Podpór przodem, dłonie stykające się kciukami i palcami.",
                "Ciało w linii prostej, brzuch napięty.",
                "Opuść klatkę do dłoni, łokcie blisko tułowia.",
                "Wypchnij się do pełnego wyprostu ramion."
            ],
            symbolName: "figure.strengthtraining.functional",
            variantOf: pushUpsID
        ),
        Exercise(
            id: pseudoPlanchePushUpsID,
            name: "Pompki pseudo-planche",
            category: .expert,
            muscleGroups: [.shoulders, .arms, .core],
            description: "Pompki z dłońmi przy biodrach i ciężarem przed rękami. Pomost do planche.",
            instructions: [
                "Podpór przodem, dłonie na wysokości bioder, palce na boki lub do tyłu.",
                "Pochyl barki mocno przed dłonie.",
                "Opuść się, utrzymując ciężar z przodu.",
                "Wypchnij się, nie cofając barków za dłonie."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Push-up handles"],
            variantOf: pushUpsID
        ),

        // MARK: Warianty — Dipy
        Exercise(
            id: parallelBarSupportID,
            name: "Podpór na poręczach",
            category: .basic,
            muscleGroups: [.chest, .arms, .shoulders],
            description: "Stabilny podpór na wyprostowanych ramionach. Buduje bazę siły i pewności do dipów.",
            instructions: [
                "Wejdź w podpór na poręczach, ramiona wyprostowane.",
                "Ściągnij barki od uszu, napnij brzuch.",
                "Trzymaj ciało pionowo i nieruchomo.",
                "Utrzymaj podpór przez zaplanowany czas."
            ],
            symbolName: "figure.strengthtraining.traditional",
            equipment: ["Dip bar", "Parallel bars"],
            measurement: .seconds,
            variantOf: dipsID
        ),
        Exercise(
            id: negativeDipsID,
            name: "Negatywy dipów",
            category: .basic,
            muscleGroups: [.chest, .arms, .shoulders],
            description: "Powolne opuszczanie w dipie. Buduje siłę do pierwszego pełnego dipa.",
            instructions: [
                "Wejdź w podpór na poręczach, ramiona wyprostowane.",
                "Pochyl tułów lekko do przodu.",
                "Opuszczaj się jak najwolniej — celuj w 3–5 sekund.",
                "Zejdź na dół i wróć na górę nogami lub podskokiem."
            ],
            symbolName: "figure.strengthtraining.traditional",
            equipment: ["Dip bar", "Parallel bars"],
            variantOf: dipsID
        ),

        // MARK: Warianty — Nogi
        Exercise(
            id: assistedSquatsID,
            name: "Przysiad z asystą",
            category: .basic,
            muscleGroups: [.legs],
            description: "Przysiad z przytrzymaniem się podpory. Uczy głębokości i kontroli.",
            instructions: [
                "Złap stabilną podporę na wysokości klatki.",
                "Zejdź biodrami w dół, pomagając sobie rękami.",
                "Zatrzymaj się poniżej równoległej, plecy proste.",
                "Wstań, napinając pośladki i minimalnie wspierając się rękami."
            ],
            symbolName: "figure.strengthtraining.functional",
            variantOf: squatsID
        ),
        Exercise(
            id: stepUpsID,
            name: "Wejścia na podwyższenie",
            category: .basic,
            muscleGroups: [.legs, .core],
            description: "Wchodzenie na skrzynię jedną nogą. Buduje jednostronną siłę nóg do pistoletu.",
            instructions: [
                "Stań przed stabilnym podwyższeniem do wysokości kolana.",
                "Postaw całą stopę na podwyższeniu.",
                "Wejdź, prostując przednią nogę bez odbicia tylną.",
                "Zejdź powoli i powtórz, zmieniając nogę."
            ],
            symbolName: "figure.strengthtraining.functional",
            variantOf: lungesID
        ),
        Exercise(
            id: assistedPistolSquatsID,
            name: "Pistolet z asystą",
            category: .advanced,
            muscleGroups: [.legs, .core],
            description: "Przysiad na jednej nodze z przytrzymaniem. Prowadzi do pełnego pistoletu.",
            instructions: [
                "Złap stabilną podporę i stań na jednej nodze.",
                "Wyprostuj drugą nogę przed sobą.",
                "Zejdź do pełnego przysiadu, wspierając się rękami.",
                "Wstań na jednej nodze, minimalnie pomagając rękami."
            ],
            symbolName: "figure.strengthtraining.functional",
            variantOf: pistolSquatsID
        ),

        // MARK: Warianty — Core
        Exercise(
            id: hangingKneeRaisesID,
            name: "Unoszenie kolan w zwisie",
            category: .basic,
            muscleGroups: [.core, .arms],
            description: "Unoszenie kolan w zwisie. Łagodniejszy wstęp do wznosów nóg.",
            instructions: [
                "Zwiśnij na drążku z wyprostowanych ramion.",
                "Unieś kolana do klatki, zwijając miednicę.",
                "Kontroluj ruch — bez bujania.",
                "Opuść nogi powoli do zwisu."
            ],
            symbolName: "figure.core.training",
            equipment: ["Pull-up bar"],
            variantOf: hangingLegRaisesID
        ),
        Exercise(
            id: toesToBarID,
            name: "Nogi do drążka",
            category: .advanced,
            muscleGroups: [.core, .arms],
            description: "Wznos prostych nóg aż do drążka. Pełny zakres pracy brzucha w zwisie.",
            instructions: [
                "Zwiśnij na drążku z wyprostowanych ramion.",
                "Unieś proste nogi aż palce dotkną drążka.",
                "Prowadź ruch brzuchem, nie bujaniem.",
                "Opuść nogi powoli do zwisu."
            ],
            symbolName: "figure.core.training",
            equipment: ["Pull-up bar"],
            variantOf: hangingLegRaisesID
        ),

        // MARK: Warianty — Muscle-up
        Exercise(
            id: negativeMuscleUpsID,
            name: "Negatywy muscle-upa",
            category: .expert,
            muscleGroups: [.back, .chest, .arms],
            description: "Powolne zejście z podporu nad drążkiem do zwisu. Uczy przejścia muscle-upa.",
            instructions: [
                "Wejdź w podpór nad drążkiem (z podskoku lub podpórki).",
                "Opuść się powoli przez fazę przejścia do zwisu.",
                "Kontroluj obrót nadgarstków i barków.",
                "Zejdź do pełnego zwisu i powtórz."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"],
            variantOf: muscleUpID
        ),
        Exercise(
            id: kippingMuscleUpsID,
            name: "Muscle-up z kipem",
            category: .expert,
            muscleGroups: [.back, .chest, .arms],
            description: "Muscle-up wspomagany zamachem nóg. Pierwsze pełne przejście nad drążek.",
            instructions: [
                "Zwiśnij na drążku nachwytem, lekko szerzej niż barki.",
                "Wykonaj zamach nóg i eksplozywne podciągnięcie.",
                "Przejdź nadgarstkami nad drążek, pochyl się do przodu.",
                "Dokończ ruch wyprostem ramion jak w dipie."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"],
            variantOf: muscleUpID
        ),

        // MARK: Warianty — L-sit
        Exercise(
            id: footSupportedLSitID,
            name: "L-sit z podporem stóp",
            category: .basic,
            muscleGroups: [.core, .arms],
            description: "L-sit z piętami na ziemi. Uczy depresji barków i napięcia bez pełnego obciążenia.",
            instructions: [
                "Podpór na poręczach lub uchwytach, ramiona wyprostowane.",
                "Wciśnij barki w dół, wypchnij klatkę.",
                "Trzymaj proste nogi z piętami lekko opartymi o ziemię.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.core.training",
            equipment: ["Parallel bars", "Push-up handles"],
            measurement: .seconds,
            variantOf: lSitID
        ),
        Exercise(
            id: oneLegLSitID,
            name: "L-sit na jednej nodze",
            category: .advanced,
            muscleGroups: [.core, .arms],
            description: "L-sit z jedną nogą uniesioną, drugą podkurczoną. Krok do pełnego L-sit.",
            instructions: [
                "Podpór na poręczach, ramiona wyprostowane, barki w dół.",
                "Unieś jedną prostą nogę do poziomu.",
                "Drugą nogę podkurcz, by odciążyć pozycję.",
                "Utrzymaj pozycję i zmieniaj nogi między seriami."
            ],
            symbolName: "figure.core.training",
            equipment: ["Parallel bars", "Push-up handles"],
            measurement: .seconds,
            variantOf: lSitID
        ),
        Exercise(
            id: tuckLSitID,
            name: "Tuck L-sit",
            category: .advanced,
            muscleGroups: [.core, .arms],
            description: "L-sit z podkurczonymi kolanami. Skraca dźwignię przed pełną pozycją.",
            instructions: [
                "Podpór na poręczach, ramiona wyprostowane, barki w dół.",
                "Oderwij biodra i podkurcz kolana do klatki.",
                "Utrzymaj uda równolegle do ziemi.",
                "Trzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.core.training",
            equipment: ["Parallel bars", "Push-up handles"],
            measurement: .seconds,
            variantOf: lSitID
        ),

        // MARK: Warianty — Front lever
        Exercise(
            id: tuckFrontLeverID,
            name: "Tuck front lever",
            category: .advanced,
            muscleGroups: [.back, .core],
            description: "Front lever w pełnym podkurczu. Pierwszy szczebel dźwigni przodem.",
            instructions: [
                "Zwiśnij na drążku, napnij łopatki.",
                "Podkurcz kolana do klatki, zaokrąglij dolne plecy.",
                "Odchyl tułów do poziomu, plecy równolegle do ziemi.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"],
            measurement: .seconds,
            variantOf: frontLeverID
        ),
        Exercise(
            id: advancedTuckFrontLeverID,
            name: "Advanced tuck front lever",
            category: .advanced,
            muscleGroups: [.back, .core],
            description: "Tuck front lever z otwartymi biodrami i płaskimi plecami. Cięższa dźwignia.",
            instructions: [
                "Wejdź w tuck front lever w poziomie.",
                "Otwórz biodra do kąta prostego, wypłaszcz plecy.",
                "Trzymaj kolana podkurczone, ale odsunięte od klatki.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"],
            measurement: .seconds,
            variantOf: frontLeverID
        ),
        Exercise(
            id: straddleFrontLeverID,
            name: "Front lever w rozkroku",
            category: .expert,
            muscleGroups: [.back, .core],
            description: "Front lever z prostymi, rozstawionymi nogami. Tuż przed pełną dźwignią.",
            instructions: [
                "Wejdź w dźwignię przodem z prostymi nogami.",
                "Rozstaw nogi szeroko, by skrócić dźwignię.",
                "Trzymaj ciało w poziomie, biodra w linii z barkami.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"],
            measurement: .seconds,
            variantOf: frontLeverID
        ),
        Exercise(
            id: halfLayFrontLeverID,
            name: "Half-lay front lever",
            category: .expert,
            muscleGroups: [.back, .core],
            description: "Front lever ze złączonymi nogami zgiętymi w biodrach. Ostatni krok do pełnej dźwigni.",
            instructions: [
                "Wejdź w dźwignię przodem, nogi złączone.",
                "Zegnij biodra, skracając dźwignię w połowie.",
                "Trzymaj plecy i klatkę w poziomie.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"],
            measurement: .seconds,
            variantOf: frontLeverID
        ),

        // MARK: Warianty — Back lever
        Exercise(
            id: germanHangID,
            name: "German hang",
            category: .basic,
            muscleGroups: [.shoulders, .back, .chest],
            description: "Zwis w pełnym wyproście barków za plecami. Otwiera barki do back levera.",
            instructions: [
                "Zwiśnij na drążku i przełóż nogi między rękami.",
                "Opuść się dalej, aż zawiśniesz plecami do drążka.",
                "Trzymaj ramiona wyprostowane, rozluźnij barki.",
                "Utrzymaj zwis przez zaplanowany czas."
            ],
            symbolName: "figure.play",
            equipment: ["Pull-up bar", "Rings"],
            measurement: .seconds,
            variantOf: backLeverID
        ),
        Exercise(
            id: skinTheCatID,
            name: "Skin the cat",
            category: .basic,
            muscleGroups: [.back, .shoulders, .core],
            description: "Pełny obrót przez zwis do german hang i z powrotem. Buduje mobilność do dźwigni tyłem.",
            instructions: [
                "Zwiśnij na drążku, podkurcz kolana.",
                "Przełóż nogi między rękami i opuść do german hang.",
                "Odwróć ruch, wracając kontrolowanie do zwisu.",
                "Powtórz płynnie zaplanowaną liczbę razy."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"],
            variantOf: backLeverID
        ),
        Exercise(
            id: tuckBackLeverID,
            name: "Tuck back lever",
            category: .advanced,
            muscleGroups: [.back, .chest, .core],
            description: "Back lever w pełnym podkurczu. Pierwszy szczebel dźwigni tyłem.",
            instructions: [
                "Z german hang podkurcz kolana do klatki.",
                "Obróć się do zwisu tyłem, twarzą do ziemi.",
                "Unieś ciało do poziomu w pozycji tuck.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"],
            measurement: .seconds,
            variantOf: backLeverID
        ),
        Exercise(
            id: advancedTuckBackLeverID,
            name: "Advanced tuck back lever",
            category: .advanced,
            muscleGroups: [.back, .chest, .core],
            description: "Tuck back lever z otwartymi biodrami. Cięższa dźwignia tyłem.",
            instructions: [
                "Wejdź w tuck back lever w poziomie.",
                "Otwórz biodra do kąta prostego, wypłaszcz plecy.",
                "Trzymaj kolana odsunięte od klatki.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"],
            measurement: .seconds,
            variantOf: backLeverID
        ),
        Exercise(
            id: straddleBackLeverID,
            name: "Back lever w rozkroku",
            category: .expert,
            muscleGroups: [.back, .chest, .core],
            description: "Back lever z prostymi, rozstawionymi nogami. Tuż przed pełną dźwignią tyłem.",
            instructions: [
                "Wejdź w dźwignię tyłem z prostymi nogami.",
                "Rozstaw nogi szeroko, by skrócić dźwignię.",
                "Trzymaj ciało w poziomie, twarzą do ziemi.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"],
            measurement: .seconds,
            variantOf: backLeverID
        ),
        Exercise(
            id: halfLayBackLeverID,
            name: "Half-lay back lever",
            category: .expert,
            muscleGroups: [.back, .chest, .core],
            description: "Back lever ze złączonymi nogami zgiętymi w biodrach. Ostatni krok do pełnej dźwigni.",
            instructions: [
                "Wejdź w dźwignię tyłem, nogi złączone.",
                "Zegnij biodra, skracając dźwignię w połowie.",
                "Trzymaj plecy i klatkę w poziomie.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Pull-up bar", "Rings"],
            measurement: .seconds,
            variantOf: backLeverID
        ),

        // MARK: Warianty — Planche
        Exercise(
            id: frogStandID,
            name: "Stanie żabki",
            category: .basic,
            muscleGroups: [.shoulders, .arms, .core],
            description: "Balans na dłoniach z kolanami opartymi o łokcie. Wstęp do planche.",
            instructions: [
                "Kucnij i oprzyj dłonie na ziemi, palce do przodu.",
                "Oprzyj kolana o zewnętrzną stronę łokci.",
                "Przenieś ciężar na dłonie i oderwij stopy.",
                "Utrzymaj balans przez zaplanowany czas."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Push-up handles"],
            measurement: .seconds,
            variantOf: plancheID
        ),
        Exercise(
            id: tuckPlancheID,
            name: "Tuck planche",
            category: .advanced,
            muscleGroups: [.shoulders, .arms, .core],
            description: "Planche w pełnym podkurczu, bez oparcia kolan. Pierwszy prawdziwy szczebel planche.",
            instructions: [
                "Podpór na dłoniach lub uchwytach, palce do przodu.",
                "Pochyl barki mocno przed dłonie (protrakcja).",
                "Oderwij stopy i podkurcz kolana do klatki.",
                "Utrzymaj biodra uniesione przez zaplanowany czas."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Push-up handles", "Parallel bars"],
            measurement: .seconds,
            variantOf: plancheID
        ),
        Exercise(
            id: advancedTuckPlancheID,
            name: "Advanced tuck planche",
            category: .advanced,
            muscleGroups: [.shoulders, .arms, .core],
            description: "Tuck planche z otwartymi biodrami i płaskimi plecami. Cięższa dźwignia pchająca.",
            instructions: [
                "Wejdź w tuck planche z protrakcją łopatek.",
                "Otwórz biodra do kąta prostego, wypłaszcz plecy.",
                "Trzymaj kolana odsunięte od klatki.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Push-up handles", "Parallel bars"],
            measurement: .seconds,
            variantOf: plancheID
        ),
        Exercise(
            id: straddlePlancheID,
            name: "Planche w rozkroku",
            category: .expert,
            muscleGroups: [.shoulders, .arms, .core],
            description: "Planche z prostymi, rozstawionymi nogami. Tuż przed pełną planche.",
            instructions: [
                "Wejdź w podpór z mocną protrakcją i ciężarem z przodu.",
                "Wyprostuj nogi i rozstaw je szeroko.",
                "Trzymaj ciało równolegle do ziemi.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.gymnastics",
            equipment: ["Push-up handles", "Parallel bars"],
            measurement: .seconds,
            variantOf: plancheID
        ),

        // MARK: Warianty — Flaga
        Exercise(
            id: verticalFlagSupportID,
            name: "Podpór na pionowym drążku",
            category: .advanced,
            muscleGroups: [.shoulders, .core, .back],
            description: "Utrzymanie ciała pionowo przy drążku z rękami w chwycie flagi. Uczy ustawienia do flagi.",
            instructions: [
                "Chwyć pionowy drążek: górna ręka nachwytem, dolna podchwytem.",
                "Wypchnij się dolną ręką, przyciągnij górną.",
                "Trzymaj ciało pionowo z uniesionymi stopami.",
                "Utrzymaj napięcie przez zaplanowany czas."
            ],
            symbolName: "figure.climbing",
            equipment: ["Pull-up bar"],
            measurement: .seconds,
            variantOf: humanFlagID
        ),
        Exercise(
            id: tuckFlagID,
            name: "Tuck flaga",
            category: .advanced,
            muscleGroups: [.core, .shoulders, .back],
            description: "Flaga z podkurczonymi kolanami. Pierwszy szczebel z ciałem oderwanym w poziom.",
            instructions: [
                "Ustaw ręce na pionowym drążku jak do flagi.",
                "Wypchnij biodra w bok i oderwij stopy.",
                "Podkurcz kolana do klatki, biodra w poziomie.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.climbing",
            equipment: ["Pull-up bar"],
            measurement: .seconds,
            variantOf: humanFlagID
        ),
        Exercise(
            id: straddleFlagID,
            name: "Flaga w rozkroku",
            category: .expert,
            muscleGroups: [.core, .shoulders, .back],
            description: "Flaga z prostymi, rozstawionymi nogami. Tuż przed pełną flagą.",
            instructions: [
                "Ustaw ręce na pionowym drążku jak do flagi.",
                "Wypchnij ciało do poziomu, dolna ręka prosta.",
                "Wyprostuj nogi i rozstaw je szeroko.",
                "Utrzymaj linię ciała przez zaplanowany czas."
            ],
            symbolName: "figure.climbing",
            equipment: ["Pull-up bar"],
            measurement: .seconds,
            variantOf: humanFlagID
        ),

        // MARK: Warianty — Stanie na rękach
        Exercise(
            id: wallPlankID,
            name: "Podpór przy ścianie",
            category: .basic,
            muscleGroups: [.shoulders, .core, .arms],
            description: "Podpór w skosie z nogami na ścianie. Buduje siłę barków do stania na rękach.",
            instructions: [
                "Podpór przodem stopami przy ścianie.",
                "Wejdź stopami po ścianie, zbliżając dłonie do niej.",
                "Ustaw barki nad dłońmi, napnij całe ciało.",
                "Utrzymaj podpór przez zaplanowany czas."
            ],
            symbolName: "figure.gymnastics",
            measurement: .seconds,
            variantOf: wallHandstandPushUpsID
        ),
        Exercise(
            id: wallHandstandHoldID,
            name: "Stanie na rękach przy ścianie",
            category: .advanced,
            muscleGroups: [.shoulders, .core, .arms],
            description: "Utrzymanie stania na rękach z podparciem ściany. Baza do pompek w staniu.",
            instructions: [
                "Wejdź w stanie na rękach przodem lub tyłem do ściany.",
                "Wyprostuj ramiona, palce rozłożone szeroko.",
                "Napnij brzuch i pośladki, trzymaj ciało w linii.",
                "Utrzymaj pozycję przez zaplanowany czas."
            ],
            symbolName: "figure.gymnastics",
            measurement: .seconds,
            variantOf: wallHandstandPushUpsID
        )
    ]
}
