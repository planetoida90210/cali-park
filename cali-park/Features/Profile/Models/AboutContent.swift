import Foundation

// MARK: - SupportContact
/// Where "Pomoc i opinie" sends mail.
enum SupportContact {
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
        components.queryItems = [URLQueryItem(name: "subject", value: "CaliPark \(version.text): opinia")]
        return components.url
    }
}

// MARK: - AboutSource
/// One credited source in "O apce", linked to the page we used.
struct AboutSource: Identifiable, Hashable, Sendable {
    let name: String
    /// What we take from it, in a few words.
    let usage: String
    let url: URL

    var id: String { name }
}

// MARK: - AboutContent
/// The sources behind the ladders (`docs/PROGRESSIONS.md`, "Źródła") and the
/// programs (`docs/PROGRAMS.md`), plus the map data attribution. Keep these
/// lists in step with those documents.
enum AboutContent {
    static let ladderSources: [AboutSource] = [
        AboutSource(name: "Recommended Routine (r/bodyweightfitness)",
                    usage: "Drabiny dynamiczne i zasada 3 × 8",
                    url: url("https://www.reddit.com/r/bodyweightfitness/wiki/kb/recommended_routine/")),
        AboutSource(name: "Overcoming Gravity, 2. wydanie (Steven Low)",
                    usage: "Kolejność szczebli statyk, chart poziomów",
                    url: url("https://docs.google.com/spreadsheets/d/19l4tVfdTJLheLMwZBYqcw1oeEBPRh8mxngqrCz2YnVg/")),
        AboutSource(name: "Tabela izometrii Overcoming Gravity",
                    usage: "Podstawa kryterium 3 × 20 s",
                    url: url("https://stevenlow.org/prilepin-tables-for-bodyweight-strength-isometric-and-eccentric-exercises/")),
        AboutSource(name: "GMB: L-sit",
                    usage: "Kroki L-situ",
                    url: url("https://web.archive.org/web/20260718150020/https://gmb.io/l-sit/")),
        AboutSource(name: "StartBodyweight",
                    usage: "Progresja podciągnięć",
                    url: url("http://www.startbodyweight.com/p/start-bodyweight-basic-routine.html")),
        AboutSource(name: "Cali Move: 8 tygodni podciągnięć",
                    usage: "Guma i negatywy",
                    url: url("https://blog.calimove.com/2023/05/11/8-weeks-pull-up-challenge/"))
    ]

    static let programSources: [AboutSource] = [
        AboutSource(name: "Recommended Routine (r/bodyweightfitness)",
                    usage: "Fundamenty, Pierwsze podciągnięcie",
                    url: url("https://www.reddit.com/r/bodyweightfitness/wiki/kb/recommended_routine/")),
        AboutSource(name: "Minimalist Routine (r/bodyweightfitness)",
                    usage: "Minimum",
                    url: url("https://www.reddit.com/r/bodyweightfitness/wiki/minroutine")),
        AboutSource(name: "Skill Day (r/bodyweightfitness)",
                    usage: "Skille",
                    url: url("https://www.reddit.com/r/bodyweightfitness/wiki/kb/skillday"))
    ]

    /// OpenStreetMap data (Parks on the map) is under the ODbL, which
    /// requires this credit wherever the data is shown or used.
    static let mapAttribution = AboutSource(
        name: ParkFormat.attribution,
        usage: "Dane o Parkach na mapie, licencja ODbL",
        url: url("https://www.openstreetmap.org/copyright")
    )

    static let disclaimer = "CaliPark nie jest powiązany z autorami tych źródeł. Opisy programów i szczebli są nasze."

    private static func url(_ string: String) -> URL {
        guard let url = URL(string: string) else { preconditionFailure("Invalid source URL: \(string)") }
        return url
    }
}
