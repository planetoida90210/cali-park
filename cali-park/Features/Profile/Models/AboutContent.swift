import Foundation

// MARK: - SupportContact
/// Where "Pomoc i opinie" sends mail.
nonisolated enum SupportContact {
    /// PLACEHOLDER: the owner replaces this with the real support address
    /// before TestFlight. `.example` is a reserved domain, so mail sent to it
    /// bounces instead of reaching a stranger.
    static let email = "kontakt@calipark.example"

    /// A `mailto:` link with a subject that carries the app version, so a
    /// message says which build it is about.
    static func mailURL(version: AppVersion = .current) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [URLQueryItem(name: "subject", value: String(localized: "CaliPark \(version.text): opinia"))]
        return components.url
    }
}

// MARK: - AboutSource
/// One credited source in "O apce", linked to the page we used.
nonisolated struct AboutSource: Identifiable, Hashable, Sendable {
    let name: String
    /// What we take from it, in a few words.
    let usage: String
    let url: URL

    var id: String { name }

    /// The name as shown, never broken after "r/".
    var displayName: String { name.keptTogether }
}

// MARK: - AboutContent
/// The sources behind the ladders (`docs/PROGRESSIONS.md`, "Źródła") and the
/// programs (`docs/PROGRAMS.md`), plus the map data attribution. Keep these
/// lists in step with those documents.
nonisolated enum AboutContent {
    static let ladderSources: [AboutSource] = [
        AboutSource(
            name: "Recommended Routine (r/bodyweightfitness)",
            usage: String(localized: "Drabiny dynamiczne i zasada 3 × 8"),
            url: url("https://www.reddit.com/r/bodyweightfitness/wiki/kb/recommended_routine/")),
        AboutSource(
            name: String(localized: "Overcoming Gravity, 2. wydanie (Steven Low)"),
            usage: String(localized: "Kolejność szczebli statyk, chart poziomów"),
            url: url("https://docs.google.com/spreadsheets/d/19l4tVfdTJLheLMwZBYqcw1oeEBPRh8mxngqrCz2YnVg/")),
        AboutSource(
            name: String(localized: "Tabela izometrii Overcoming Gravity"),
            usage: String(localized: "Podstawa kryterium 3 × 20 s"),
            url: url("https://stevenlow.org/prilepin-tables-for-bodyweight-strength-isometric-and-eccentric-exercises/")),
        AboutSource(
            name: "GMB: L-sit",
            usage: String(localized: "Kroki L-situ"),
            url: url("https://web.archive.org/web/20260718150020/https://gmb.io/l-sit/")),
        AboutSource(
            name: "StartBodyweight",
            usage: String(localized: "Progresja podciągnięć"),
            url: url("http://www.startbodyweight.com/p/start-bodyweight-basic-routine.html")),
        AboutSource(
            name: String(localized: "Cali Move: 8 tygodni podciągnięć"),
            usage: String(localized: "Guma i negatywy"),
            url: url("https://blog.calimove.com/2023/05/11/8-weeks-pull-up-challenge/"))
    ]

    static let programSources: [AboutSource] = [
        AboutSource(
            name: "Recommended Routine (r/bodyweightfitness)",
            usage: String(localized: "Fundamenty, Pierwsze podciągnięcie"),
            url: url("https://www.reddit.com/r/bodyweightfitness/wiki/kb/recommended_routine/")),
        AboutSource(
            name: "Minimalist Routine (r/bodyweightfitness)",
            usage: String(localized: "Minimum"),
            url: url("https://www.reddit.com/r/bodyweightfitness/wiki/minroutine")),
        AboutSource(
            name: "Skill Day (r/bodyweightfitness)",
            usage: String(localized: "Skille"),
            url: url("https://www.reddit.com/r/bodyweightfitness/wiki/kb/skillday"))
    ]

    /// OpenStreetMap data (Parks on the map) is under the ODbL, which
    /// requires this credit wherever the data is shown or used.
    static let mapAttribution = AboutSource(
        name: ParkFormat.attribution,
        usage: String(localized: "Dane o Parkach na mapie, licencja ODbL"),
        url: url("https://www.openstreetmap.org/copyright")
    )

    static let disclaimer = String(localized: "CaliPark nie jest powiązany z autorami tych źródeł. Opisy programów i szczebli są nasze.")

    /// The app gives training advice, so it says plainly that it is not
    /// medical advice (App Review guideline 1.4.1).
    static let healthNote = String(localized: "CaliPark podpowiada trening, ale nie zastąpi lekarza. Jeśli masz uraz, chorobę albo wątpliwości, zanim zaczniesz, porozmawiaj z lekarzem lub fizjoterapeutą. Gdy poczujesz ból, przerwij ćwiczenie.")

    private static func url(_ string: String) -> URL {
        guard let url = URL(string: string) else { preconditionFailure("Invalid source URL: \(string)") }
        return url
    }
}
