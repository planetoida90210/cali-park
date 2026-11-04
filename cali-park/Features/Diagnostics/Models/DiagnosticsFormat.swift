import Foundation

// MARK: - DiagnosticsFormat
/// The Polish texts of "Diagnostyka": kind titles, fact labels and values,
/// the OS name and the row subtitle. Only what is shown changes: the stored
/// summary and MetricKit's JSON keep MetricKit's own English text, and
/// signals, exception names and stack frames show as MetricKit wrote them.
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

    // MARK: Values

    /// A fact's value for the screen. MetricKit's durations and sizes read in
    /// Polish: "2.4 sec" → "2,4 s", "1,260 sec" → "21 min", "450 ms" →
    /// "450 ms", "2,400 kB" → "2,4 MB". Anything else, or a value that doesn't
    /// parse, shows as MetricKit wrote it.
    static func value(of fact: DiagnosticFact, locale: Locale = .current) -> String {
        guard let measured = measurement(fact.value) else { return fact.value }
        if let scale = secondsPerUnit[measured.unit] {
            return duration(seconds: measured.number * scale, locale: locale)
        }
        if let scale = bytesPerUnit[measured.unit] {
            return size(bytes: measured.number * scale, locale: locale)
        }
        return fact.value
    }

    /// The OS as Apple names it now: MetricKit's "iPhone OS 26.1 (23B85)"
    /// reads "iOS 26.1 (23B85)".
    static func osVersion(_ raw: String) -> String {
        let legacyName = "iPhone OS "
        guard raw.hasPrefix(legacyName) else { return raw }
        return "iOS " + raw.dropFirst(legacyName.count)
    }

    /// MetricKit's measurement text, "1,260 sec": the number (its "," groups
    /// thousands, MetricKit writes in English) and the unit symbol.
    private static func measurement(_ text: String) -> (number: Double, unit: String)? {
        let parts = text.split(separator: " ")
        guard parts.count == 2,
              let number = Double(parts[0].replacingOccurrences(of: ",", with: ""))
        else { return nil }
        return (number: number, unit: String(parts[1]))
    }

    /// The duration symbols MetricKit writes, in seconds.
    private static let secondsPerUnit: [String: Double] = [
        "ms": 0.001, "s": 1, "sec": 1, "min": 60, "h": 3_600, "hr": 3_600
    ]

    /// The size symbols MetricKit writes, in bytes (its "kB" is 1000 bytes).
    private static let bytesPerUnit: [String: Double] = [
        "B": 1, "bytes": 1, "kB": 1_000, "KB": 1_000, "MB": 1_000_000, "GB": 1_000_000_000,
        "TB": 1_000_000_000_000
    ]

    /// "450 ms" under a second, "2,4 s" under a minute, then whole hours,
    /// minutes and seconds: "1 min 32 s", "21 min", "1 godz. 2 min". The
    /// seconds unit is "s", as everywhere in the app; numbers never wrap away
    /// from their units.
    static func duration(seconds: Double, locale: Locale = .current) -> String {
        let space = String(String.noBreakSpace)
        if seconds < 1 {
            return "\((seconds * 1_000).rounded().formatted(.number.locale(locale)))\(space)ms"
        }
        if seconds < 60 {
            let number = seconds.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
            return "\(number)\(space)\(MeasureFormat.secondsUnit)"
        }
        let total = Int(seconds.rounded())
        let hours = total / 3_600
        let minutes = total % 3_600 / 60
        let rest = total % 60
        var parts: [String] = []
        if hours > 0 { parts.append(String(localized: "\(hours) godz.", comment: "Hours, abbreviated: \"2 godz.\"")) }
        if minutes > 0 { parts.append(String(localized: "\(minutes) min", comment: "Minutes, abbreviated: \"21 min\"")) }
        if hours == 0, rest > 0 { parts.append("\(rest) \(MeasureFormat.secondsUnit)") }
        return parts.map { $0.replacingOccurrences(of: " ", with: space) }.joined(separator: " ")
    }

    /// "2,4 MB", "182 MB", "1,07 GB": decimal units, like the Files app.
    static func size(bytes: Double, locale: Locale = .current) -> String {
        Int64(bytes.rounded())
            .formatted(.byteCount(style: .file).locale(locale))
            .replacingOccurrences(of: " ", with: String(String.noBreakSpace))
    }

    // MARK: Report

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
