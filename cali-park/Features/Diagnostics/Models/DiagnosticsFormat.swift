import Foundation

// MARK: - DiagnosticsFormat
/// The Polish texts of "Diagnostyka": kind titles, fact labels and the row
/// subtitle. MetricKit's own values (signals, durations, frames) stay as
/// MetricKit wrote them.
nonisolated enum DiagnosticsFormat {
    static func title(for kind: DiagnosticKind?) -> String {
        switch kind {
        case .crash: String(localized: "Awaria")
        case .hang: String(localized: "Zawieszenie")
        case .cpuException: String(localized: "Duże użycie procesora")
        case .diskWriteException: String(localized: "Duży zapis na dysk")
        case .appLaunch: String(localized: "Wolne uruchomienie")
        case .metrics: String(localized: "Dzienne metryki")
        case nil: String(localized: "Raport diagnostyczny")
        }
    }

    static func label(for key: DiagnosticFact.Key) -> String {
        switch key {
        case .signal: String(localized: "Sygnał")
        case .exceptionType: String(localized: "Wyjątek")
        case .terminationReason: String(localized: "Powód zakończenia")
        case .objectiveCException: String(localized: "Wyjątek Objective-C")
        case .hangDuration: String(localized: "Czas zawieszenia")
        case .cpuTime: String(localized: "Czas procesora")
        case .sampledTime: String(localized: "Czas pomiaru")
        case .writesCaused: String(localized: "Zapisane dane")
        case .launchDuration: String(localized: "Czas uruchomienia")
        case .foregroundTime: String(localized: "Czas na ekranie")
        case .backgroundTime: String(localized: "Czas w tle")
        case .peakMemory: String(localized: "Szczyt pamięci")
        case .diskWrites: String(localized: "Zapis na dysk")
        case .unexpectedExits: String(localized: "Nieoczekiwane zamknięcia")
        }
    }

    /// The report's title: its most severe kind.
    static func title(for report: DiagnosticReport) -> String {
        title(for: report.primaryKind)
    }

    /// "4 lis 2026, 14:03 · wersja 1.0 (5)", plus "· 3 zdarzenia" when the
    /// payload holds more than one diagnostic.
    static func subtitle(for report: DiagnosticReport, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        var style = Date.FormatStyle(date: .abbreviated, time: .shortened, locale: locale)
        style.timeZone = timeZone
        var parts = [report.date.formatted(style)]
        if let version = report.appVersion {
            parts.append(String(localized: "wersja \(version.text)"))
        }
        if report.entries.count > 1 {
            parts.append(events(report.entries.count))
        }
        return parts.joined(separator: " · ")
    }

    /// "1 zdarzenie", "3 zdarzenia", "5 zdarzeń".
    static func events(_ count: Int) -> String {
        "\(count) \(PolishPlural.form(for: count, one: "zdarzenie", few: "zdarzenia", many: "zdarzeń"))"
    }

    /// The detail screen shows at most this much of MetricKit's JSON; the
    /// file that gets sent always holds all of it.
    static let previewCharacterLimit = 20_000

    static let loadFailureMessage = String(localized: "Nie udało się odczytać raportów diagnostycznych.")
    static let deleteFailureMessage = String(localized: "Nie udało się usunąć raportów.")
}
