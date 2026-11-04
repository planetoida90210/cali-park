import Foundation

// MARK: - TrainingBackupError
/// Why a file cannot be imported. Nothing is written in any of these cases:
/// the file is checked in full before any store is touched.
nonisolated enum TrainingBackupError: Error, Equatable {
    /// Not a CaliPark backup at all (another JSON file, a photo, …).
    case notABackup
    /// Written by a newer CaliPark with a format this build cannot read.
    case newerVersion(Int)
    /// A CaliPark backup whose content cannot be decoded.
    case damaged
    /// Decodes, but breaks a rule the stores rely on (e.g. duplicate ids).
    case invalidContent(String)
    /// Larger than any real journal; refused before reading it whole.
    case tooLarge
    /// The picked file could not be opened.
    case unreadableFile

    /// The alert text for the import screen.
    var message: String {
        switch self {
        case .notABackup:
            String(localized: "To nie jest plik kopii CaliPark. Wybierz plik „calipark-backup-…json”.")
        case .newerVersion:
            String(localized: "Ten plik zapisała nowsza wersja CaliPark. Zaktualizuj apkę i spróbuj ponownie.")
        case .damaged:
            String(localized: "Plik kopii jest uszkodzony i nie da się go wczytać.")
        case .invalidContent(let reason):
            String(localized: "Plik kopii zawiera niepoprawne dane (\(reason)).")
        case .tooLarge:
            String(localized: "Ten plik jest za duży na kopię treningów.")
        case .unreadableFile:
            String(localized: "Nie udało się otworzyć pliku.")
        }
    }
}

// MARK: - TrainingBackupCodec
/// The export file format, `calipark-backup-YYYY-MM-DD.json`:
///
/// ```json
/// {
///   "format": "calipark-backup",
///   "schemaVersion": 2,
///   "exportedAt": "2026-11-04T18:30:00Z",
///   "appVersion": "1.0 (1)",
///   "payload": { "workoutLog": […], "workoutPlans": […],
///                "placement": {…} | null, "skillProgress": {…} | null,
///                "weeklyGoal": {…} | null, "favoriteParks": ["<Park UUID>", …],
///                "favoriteExercises": ["<exercise UUID>", …] }
/// }
/// ```
///
/// Each payload section is the same JSON its store writes, in the store's
/// current format (`SkillPlacement`, `SkillProgress` and `WorkoutPlan`
/// version 2). When one of those formats changes, bump `schemaVersion` and
/// teach `decode` to read the older backups. Dates are ISO 8601 with whole
/// seconds, like the stores.
///
/// Version 2 stores plan schedule days as `"yyyy-MM-dd"`. Version 1 stored
/// them as instants, which `CalendarDay` reads as days in the current
/// calendar.
///
/// `favoriteParks` and `favoriteExercises` came later than the other
/// sections: files without them (from before those favorites existed) still
/// read, as a backup that says nothing about them. Older builds ignore the
/// keys they don't know, so adding one doesn't bump `schemaVersion`.
nonisolated enum TrainingBackupCodec {
    static let formatIdentifier = "calipark-backup"
    /// The version this build writes; it reads `1...schemaVersion`.
    static let schemaVersion = 2
    /// Far above a real journal (about 1 MB holds thousands of workouts).
    static let maximumFileSize = 50 * 1024 * 1024

    // MARK: Encode
    /// The export file's bytes. Pretty-printed, so the file stays readable.
    static func encode(_ backup: TrainingBackup, exportedAt: Date, appVersion: String) throws -> Data {
        let file = File(
            format: formatIdentifier,
            schemaVersion: schemaVersion,
            exportedAt: exportedAt,
            appVersion: appVersion,
            payload: Payload(backup)
        )
        return try encoder.encode(file)
    }

    /// `calipark-backup-2026-11-04.json`, dated in the athlete's time zone.
    static func fileName(for date: Date, calendar: Calendar = .current) -> String {
        let day = date.formatted(Date.ISO8601FormatStyle(timeZone: calendar.timeZone).year().month().day())
        return "\(formatIdentifier)-\(day).json"
    }

    // MARK: Decode
    /// Reads and fully validates a backup. Throws `TrainingBackupError`; never
    /// returns a partial backup.
    static func decode(_ data: Data) throws(TrainingBackupError) -> TrainingBackup {
        guard data.count <= maximumFileSize else { throw .tooLarge }
        guard let header = try? JSONFileFormat.decoder.decode(Header.self, from: data),
              header.format == formatIdentifier else {
            throw .notABackup
        }
        guard let version = header.schemaVersion, version >= 1 else { throw .damaged }
        guard version <= schemaVersion else { throw .newerVersion(version) }

        let file: File
        do {
            file = try JSONFileFormat.decoder.decode(File.self, from: data)
        } catch {
            throw .damaged
        }
        let backup = file.payload.backup
        try validate(backup)
        return backup
    }

    /// The rules the stores rely on, checked before anything is written.
    static func validate(_ backup: TrainingBackup) throws(TrainingBackupError) {
        if Set(backup.workoutLog.map(\.id)).count != backup.workoutLog.count {
            throw .invalidContent(String(localized: "powtórzone wpisy w dzienniku"))
        }
        if Set(backup.workoutPlans.map(\.id)).count != backup.workoutPlans.count {
            throw .invalidContent(String(localized: "powtórzone plany"))
        }
        if let goal = backup.weeklyGoal {
            guard goal.versions.allSatisfy({ WeeklyGoal.isValidSet($0.goals) }) else {
                throw .invalidContent(String(localized: "niepoprawny cel tygodniowy"))
            }
            let starts = goal.versions.map(\.effectiveFrom)
            guard starts == starts.sorted() else {
                throw .invalidContent(String(localized: "niepoprawna historia celu tygodniowego"))
            }
        }
        if let favorites = backup.favoriteParkIDs, Set(favorites).count != favorites.count {
            throw .invalidContent(String(localized: "powtórzone ulubione Parki"))
        }
        if let favorites = backup.favoriteExerciseIDs, Set(favorites).count != favorites.count {
            throw .invalidContent(String(localized: "powtórzone ulubione ćwiczenia"))
        }
    }

    // MARK: Format
    private struct Header: Decodable {
        let format: String?
        let schemaVersion: Int?
    }

    private struct File: Codable {
        let format: String
        let schemaVersion: Int
        let exportedAt: Date
        let appVersion: String
        let payload: Payload
    }

    private struct Payload: Codable {
        let workoutLog: [WorkoutLogEntry]
        let workoutPlans: [WorkoutPlan]
        let placement: SkillPlacement?
        let skillProgress: SkillProgress?
        let weeklyGoal: WeeklyGoalHistory?
        /// Absent in files written before favorites existed.
        let favoriteParks: [UUID]?
        /// Absent in files written before exercise favorites existed.
        let favoriteExercises: [UUID]?

        init(_ backup: TrainingBackup) {
            workoutLog = backup.workoutLog
            workoutPlans = backup.workoutPlans
            placement = backup.placement
            skillProgress = backup.skillProgress
            weeklyGoal = backup.weeklyGoal
            favoriteParks = backup.favoriteParkIDs
            favoriteExercises = backup.favoriteExerciseIDs
        }

        var backup: TrainingBackup {
            TrainingBackup(
                workoutLog: workoutLog,
                workoutPlans: workoutPlans,
                placement: placement,
                skillProgress: skillProgress,
                weeklyGoal: weeklyGoal,
                favoriteParkIDs: favoriteParks,
                favoriteExerciseIDs: favoriteExercises
            )
        }

        // `encodeIfPresent` would drop nil keys; write them as null so the file
        // states plainly that nothing was saved.
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(workoutLog, forKey: .workoutLog)
            try container.encode(workoutPlans, forKey: .workoutPlans)
            try container.encode(placement, forKey: .placement)
            try container.encode(skillProgress, forKey: .skillProgress)
            try container.encode(weeklyGoal, forKey: .weeklyGoal)
            try container.encode(favoriteParks, forKey: .favoriteParks)
            try container.encode(favoriteExercises, forKey: .favoriteExercises)
        }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}
