import Foundation

// MARK: - ProgramCatalog
/// The ready-made programs of CaliPark 1.0, a 1:1 encoding of
/// `docs/PROGRAMS.md` (ticket 016). Change a program only together with that
/// document, and bump its `version` when its content changes.
///
/// Every item points at a ladder, not a fixed exercise, wherever one exists:
/// the created plan then trains the athlete's current rung and grows with
/// them. All wording is our own Polish text; the credit lines name the
/// sources without suggesting any endorsement.
nonisolated enum ProgramCatalog {
    // MARK: Lookup
    /// Every program, in the order the Planner lists them.
    static let all: [TrainingProgram] = [minimum, fundamentals, firstPullUp, skills]

    static func program(withID id: ProgramID) -> TrainingProgram? {
        all.first { $0.id == id }
    }

    /// The program a plan was created from, or `nil` for a plan the user built
    /// (or one from a program this build doesn't know).
    static func program(for plan: WorkoutPlan) -> TrainingProgram? {
        plan.programID.flatMap(ProgramID.init(rawValue:)).flatMap(program(withID:))
    }

    // MARK: Shared values
    /// Monday, Wednesday, Friday: three days with a rest day between them.
    private static let mondayWednesdayFriday: Set<Weekday> = [.monday, .wednesday, .friday]
    /// Rest after each set of a pair (RR).
    private static let pairRest = 90

    // MARK: Minimum
    static let minimum = TrainingProgram(
        id: .minimum,
        version: 1,
        name: "Minimum",
        tagline: "Krótki obwód na całe ciało, gdy masz mało czasu.",
        audience: "Na start, na zdrowie albo na dni, w których masz 20 minut.",
        details: [
            "Jeden obwód z czterech ćwiczeń: nogi, pompki, wiosłowanie i deska z dotknięciem barku. Robisz je jedno po drugim, bez przerwy.",
            "Powtarzasz obwód od 2 do 6 razy. Między obwodami odpoczywasz tyle, ile trzeba, zwykle 1–2 minuty.",
            "Każdą serię kończysz 1–2 powtórzenia przed upadkiem mięśniowym. Gdy na swoim szczeblu zrobisz 3 serie po 8, przechodzisz na następny.",
            "Na siłę trenuj 3 razy w tygodniu. Dla zdrowia możesz robić obwód codziennie."
        ],
        frequency: "3 × w tygodniu",
        sessionLength: "ok. 15–25 min",
        creditLine: "Na podstawie Minimalist Routine z wiki r/bodyweightfitness. CaliPark nie jest z nią powiązany.",
        symbolName: "timer",
        weekdays: mondayWednesdayFriday,
        sessions: [
            ProgramSession(
                name: "Minimum",
                items: [
                    ProgramItem(.ladder(.legs), dose: .circuit(rounds: 2...6, repsInReserve: 2), group: 1),
                    ProgramItem(.ladder(.pushUp), dose: .circuit(rounds: 2...6, repsInReserve: 2), group: 1),
                    ProgramItem(.ladder(.row), dose: .circuit(rounds: 2...6, repsInReserve: 2), group: 1),
                    ProgramItem(
                        .exercise(ExerciseCatalog.plankShoulderTapsID),
                        dose: .circuit(rounds: 2...6, repsInReserve: 2), group: 1)
                ])
        ]
    )

    // MARK: Fundamenty
    static let fundamentals = TrainingProgram(
        id: .fundamentals,
        version: 1,
        name: "Fundamenty",
        tagline: "Pełny trening siłowy całego ciała w trzech parach.",
        audience: "Dla początkujących i średniozaawansowanych, którzy chcą trenować całe ciało.",
        details: [
            "Zaczynasz od 5–10 minut rozgrzewki. Potem trzy pary ćwiczeń: podciąganie z nogami, dipy z core, wiosłowanie z pompkami.",
            "W parze robisz serię pierwszego ćwiczenia, odpoczywasz 90 s, robisz serię drugiego i znowu 90 s przerwy. Tak trzy razy.",
            "Na nowym szczeblu zaczynasz od 3 serii po 5. Na każdym treningu dokładasz po jednym powtórzeniu na serię. Przy 3 × 8 przechodzisz na następny szczebel. Holdy robisz 3 × 10–30 s.",
            "Każdą serię kończysz z około jednym powtórzeniem w zapasie. Jeśli powtórzenia spadają z serii na serię, odpocznij dłużej, nawet do 3 minut.",
            "Nie masz poręczy? Zamiast dipów możesz robić pompki pike i trudniejsze szczeble z drabiny stania na rękach."
        ],
        frequency: "3 × w tygodniu, z dniem przerwy",
        sessionLength: "ok. 45–60 min",
        creditLine:
            "Inspirowane Recommended Routine społeczności r/bodyweightfitness. Program nie jest oficjalny ani zatwierdzony przez jej autorów.",
        symbolName: "figure.strengthtraining.traditional",
        weekdays: mondayWednesdayFriday,
        sessions: [
            ProgramSession(
                name: "Fundamenty",
                items: [
                    ProgramItem(.ladder(.pullUp), group: 1, restSeconds: pairRest),
                    ProgramItem(.ladder(.legs), group: 1, restSeconds: pairRest),
                    ProgramItem(.ladder(.dip), group: 2, restSeconds: pairRest),
                    ProgramItem(.ladder(.core), group: 2, restSeconds: pairRest),
                    ProgramItem(.ladder(.row), group: 3, restSeconds: pairRest),
                    ProgramItem(.ladder(.pushUp), group: 3, restSeconds: pairRest)
                ])
        ]
    )

    // MARK: Pierwsze podciągnięcie
    static let firstPullUp = TrainingProgram(
        id: .firstPullUp,
        version: 1,
        name: "Pierwsze podciągnięcie",
        tagline: "Od zwisu do pierwszych czystych podciągnięć.",
        audience: "Dla osób, które robią od 0 do 3 czystych podciągnięć.",
        details: [
            "Na początku treningu, na świeżo, robisz swój szczebel podciągania: zwis, ściąganie łopatek, zwis z wygięciem, negatywy albo pełne podciągnięcia.",
            "Potem wiosłowanie. Ciągnięcie poziome pomaga w podciąganiu, więc go nie pomijaj.",
            "Na koniec para: pompki i nogi na przemian, 90 s przerwy po każdej serii.",
            "Na nowym szczeblu zaczynasz od 3 serii po 5 i dokładasz po powtórzeniu, aż dojdziesz do 3 × 8. Negatywy robisz powoli, zjazd trwa 5–10 s.",
            "Gdy zrobisz 3 serie po 8 pełnych podciągnięć, czas przejść na Fundamenty."
        ],
        frequency: "3 × w tygodniu, z dniem przerwy",
        sessionLength: "ok. 30–40 min",
        creditLine: "Program CaliPark oparty na zasadach z Recommended Routine (r/bodyweightfitness), StartBodyweight i Cali Move.",
        symbolName: "figure.climbing",
        weekdays: mondayWednesdayFriday,
        sessions: [
            ProgramSession(
                name: "Pierwsze podciągnięcie",
                items: [
                    ProgramItem(.ladder(.pullUp)),
                    ProgramItem(.ladder(.row)),
                    ProgramItem(.ladder(.pushUp), group: 1, restSeconds: pairRest),
                    ProgramItem(.ladder(.legs), group: 1, restSeconds: pairRest)
                ])
        ]
    )

    // MARK: Skille
    static let skills = TrainingProgram(
        id: .skills,
        version: 1,
        name: "Skille",
        tagline: "Dodatek: stanie na rękach i L-sit.",
        audience: "Dodatek do Fundamentów albo Pierwszego podciągnięcia dla osób, które chcą stać na rękach i trzymać L-sit.",
        details: [
            "Najpierw do 10 minut praktyki stania na rękach na swoim szczeblu: podpór przy ścianie albo stanie przy ścianie. Przerwy robisz wtedy, kiedy potrzebujesz.",
            "Potem L-sit na swoim szczeblu: holdy po 10–30 s, łącznie około 2–3 minut.",
            "Szczebel zaliczasz jak na drabinie: 3 × 30 s przy ścianie, 3 × 20 s w L-sicie.",
            "Zanim zaczniesz stać na rękach, dobrze utrzymać 30 s deski.",
            "Trenuj w dni wolne od siły albo tuż przed treningiem siłowym."
        ],
        frequency: "2 × w tygodniu",
        sessionLength: "ok. 15–20 min",
        creditLine: "Bloki stania na rękach i L-situ na podstawie Skill Day z wiki r/bodyweightfitness. CaliPark nie jest z nią powiązany.",
        symbolName: "figure.gymnastics",
        weekdays: [.tuesday, .thursday],
        sessions: [
            ProgramSession(
                name: "Skille",
                items: [
                    ProgramItem(.ladder(.handstand, holdRungsOnly: true), dose: .timeBox(minutes: 10)),
                    ProgramItem(.ladder(.lSit), dose: .totalHold(seconds: 180, perHold: 10...30))
                ])
        ]
    )
}
