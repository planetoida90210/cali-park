import Foundation
import Testing
@testable import cali_park

// MARK: - Fixtures
/// A full backup built from the golden store fixtures (whole-second dates),
/// plus a weekly goal, so every section is exercised.
private enum BackupFixtures {
    static let exportedAt = StoreFixtures.october2

    static let weeklyGoal = WeeklyGoalHistory(
        versions: [WeeklyGoalVersion(effectiveFrom: StoreFixtures.october1,
                                     goals: WeeklyGoal.defaultGoals(trainingDaysPerWeek: 4))],
        pauses: [],
        celebrated: [],
        // Matches the backup's plans, so importing records nothing new and
        // the export reads back exactly what was imported.
        planSchedules: [PlanScheduleRecord(effectiveFrom: StoreFixtures.october1,
                                           activePlansOf: StoreFixtures.workoutPlans)]
    )

    static let favoriteParks = [
        UUID(uuidString: "D0000000-0000-4000-8000-000000000002")!,
        UUID(uuidString: "D0000000-0000-4000-8000-000000000001")!
    ]
    /// A favorite already on the phone before an import.
    static let oldFavorite = UUID(uuidString: "D0000000-0000-4000-8000-0000000000F0")!

    static let favoriteExercises = [ExerciseCatalog.australianPullUpsID, ExerciseCatalog.dipsID]
    /// A favorite exercise already on the phone before an import.
    static let oldFavoriteExercise = ExerciseCatalog.pushUpsID

    static let full = TrainingBackup(
        workoutLog: StoreFixtures.workoutLog,
        workoutPlans: StoreFixtures.workoutPlans,
        placement: StoreFixtures.placement,
        skillProgress: StoreFixtures.progress,
        weeklyGoal: weeklyGoal,
        favoriteParkIDs: favoriteParks,
        favoriteExerciseIDs: favoriteExercises
    )

    static func data(_ backup: TrainingBackup = full) throws -> Data {
        try TrainingBackupCodec.encode(backup, exportedAt: exportedAt, appVersion: "1.0 (1)")
    }

    /// The encoded backup with its top-level fields edited.
    static func editedData(_ edit: (inout [String: Any]) -> Void) throws -> Data {
        var object = try #require(JSONSerialization.jsonObject(with: data()) as? [String: Any])
        edit(&object)
        return try JSONSerialization.data(withJSONObject: object)
    }
}

/// The stores of one restore, wired through a real `AppEnvironment` so the
/// journal, progress, weekly goal and reward loop are the app's.
@MainActor
private struct BackupRig {
    let log: WorkoutLogStoring
    let plans: WorkoutPlanStoring
    let placement: SkillPlacementStoring
    let progress: SkillProgressStoring
    let goal: WeeklyGoalStoring
    let favorites: FavoriteParkStoring
    let exerciseFavorites: FavoriteExerciseStoring
    let scheduler = InMemoryReminderScheduler(status: .authorized)
    let environment: AppEnvironment
    let service: TrainingBackupService

    init(log: WorkoutLogStoring = InMemoryWorkoutLogStore(),
         plans: WorkoutPlanStoring = InMemoryWorkoutPlanStore(),
         placement: SkillPlacementStoring = InMemorySkillPlacementStore(),
         progress: SkillProgressStoring = InMemorySkillProgressStore(),
         goal: WeeklyGoalStoring = InMemoryWeeklyGoalStore(),
         favorites: FavoriteParkStoring = InMemoryFavoriteParkStore(),
         exerciseFavorites: FavoriteExerciseStoring = InMemoryFavoriteExerciseStore()) {
        self.log = log
        self.plans = plans
        self.placement = placement
        self.progress = progress
        self.goal = goal
        self.favorites = favorites
        self.exerciseFavorites = exerciseFavorites
        environment = AppEnvironment(
            parkDirectory: InMemoryParkDirectory(),
            locationProvider: FixedLocationProvider(authorization: .denied),
            favoriteParkStore: favorites,
            favoriteExerciseStore: exerciseFavorites,
            workoutLogStore: log,
            workoutPlanStore: plans,
            reminderScheduler: scheduler,
            reminderRefreshScheduler: InMemoryReminderRefreshScheduler(),
            placementStore: placement,
            skillProgressStore: progress,
            weeklyGoalStore: goal,
            diagnostics: DiagnosticsService(store: InMemoryDiagnosticReportStore()),
            defaults: .throwaway()
        )
        service = environment.makeTrainingBackupService()
    }

    /// Some data that is not the full fixture, to replace.
    static func withOldData() -> BackupRig {
        BackupRig(
            log: InMemoryWorkoutLogStore(initial: [WorkoutLogEntry(exerciseID: ExerciseCatalog.dipsID, date: StoreFixtures.october1, sets: [LoggedSet(reps: 3)])]),
            plans: InMemoryWorkoutPlanStore(initial: [WorkoutPlan(name: "Stary plan", schedule: .once(nil), createdAt: StoreFixtures.october1)]),
            placement: InMemorySkillPlacementStore(initial: SkillPlacement(declaredRungByPath: [.core: 1], declaredAt: StoreFixtures.october1)),
            progress: InMemorySkillProgressStore(initial: SkillProgress(celebratedLevel: 2)),
            goal: InMemoryWeeklyGoalStore(initial: nil),
            favorites: InMemoryFavoriteParkStore(initial: [BackupFixtures.oldFavorite]),
            exerciseFavorites: InMemoryFavoriteExerciseStore(initial: [BackupFixtures.oldFavoriteExercise])
        )
    }
}

// MARK: - Failing stores
/// A plan store whose whole-file replace fails, after reads that work.
private final class FailingReplacePlanStore: WorkoutPlanStoring {
    struct Failure: Error {}
    private var plans: [WorkoutPlan]
    init(initial: [WorkoutPlan]) { plans = initial }
    func load() throws -> [WorkoutPlan] { plans }
    func save(_ plan: WorkoutPlan) throws { throw Failure() }
    func delete(id: UUID) throws { throw Failure() }
    func replaceAll(with plans: [WorkoutPlan]) throws { throw Failure() }
}

/// A placement store that takes the first replace (the import) and refuses
/// every later one (the rollback), to model a rollback that cannot finish.
private final class OneShotPlacementStore: SkillPlacementStoring {
    struct Failure: Error {}
    private var placement: SkillPlacement?
    private var replaces = 0
    init(initial: SkillPlacement?) { placement = initial }
    func load() throws -> SkillPlacement? { placement }
    func save(_ placement: SkillPlacement) throws { throw Failure() }
    func replace(with placement: SkillPlacement?) throws {
        replaces += 1
        guard replaces == 1 else { throw Failure() }
        self.placement = placement
    }
}

// MARK: - Codec
@Suite("Training backup file format")
struct TrainingBackupCodecTests {
    @Test("A backup survives encode and decode unchanged")
    func roundtrip() throws {
        let decoded = try TrainingBackupCodec.decode(BackupFixtures.data())
        #expect(decoded == BackupFixtures.full)
    }

    @Test("An empty backup roundtrips, with nothing-saved sections as null")
    func emptyRoundtrip() throws {
        let data = try BackupFixtures.data(TrainingBackup())
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let payload = try #require(object["payload"] as? [String: Any])
        #expect(payload["placement"] is NSNull)
        #expect(payload["weeklyGoal"] is NSNull)
        #expect(try TrainingBackupCodec.decode(data) == TrainingBackup())
    }

    @Test("The file carries the format marker, version, date and app version")
    func header() throws {
        let object = try #require(JSONSerialization.jsonObject(with: BackupFixtures.data()) as? [String: Any])
        #expect(object["format"] as? String == "calipark-backup")
        #expect(object["schemaVersion"] as? Int == 2)
        #expect(object["exportedAt"] as? String == "2026-10-02T18:05:10Z")
        #expect(object["appVersion"] as? String == "1.0 (1)")
    }

    @Test("The file name carries the date in the athlete's calendar")
    func fileName() {
        #expect(TrainingBackupCodec.fileName(for: StoreFixtures.october1, calendar: ProgramFixtures.calendar)
                == "calipark-backup-2026-10-01.json")
        var tokyo = ProgramFixtures.calendar
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        // 18:05 UTC on 2 October is already 3 October in Tokyo.
        #expect(TrainingBackupCodec.fileName(for: StoreFixtures.october2, calendar: tokyo)
                == "calipark-backup-2026-10-03.json")
    }

    @Test("Files that are not CaliPark backups are refused as such", arguments: [
        "not json at all",
        "[1, 2, 3]",
        #"{"schemaVersion": 1, "payload": []}"#,
        #"{"format": "other-app", "schemaVersion": 1}"#
    ])
    func notABackup(_ text: String) {
        #expect(throws: TrainingBackupError.notABackup) {
            try TrainingBackupCodec.decode(Data(text.utf8))
        }
    }

    @Test("A store file is not mistaken for a backup")
    func storeFileIsNotABackup() throws {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "workout-log-legacy", withExtension: "json"))
        #expect(throws: TrainingBackupError.notABackup) {
            try TrainingBackupCodec.decode(Data(contentsOf: url))
        }
    }

    @Test("A newer schema version is refused with a message to update")
    func newerVersion() throws {
        let newer = TrainingBackupCodec.schemaVersion + 1
        let data = try BackupFixtures.editedData { $0["schemaVersion"] = newer }
        #expect(throws: TrainingBackupError.newerVersion(newer)) {
            try TrainingBackupCodec.decode(data)
        }
        #expect(TrainingBackupError.newerVersion(newer).message.contains("nowsza wersja"))
    }

    @Test("A backup with a broken payload is reported as damaged")
    func damagedPayload() throws {
        let missingLog = try BackupFixtures.editedData { object in
            var payload = object["payload"] as? [String: Any] ?? [:]
            payload["workoutLog"] = nil
            object["payload"] = payload
        }
        #expect(throws: TrainingBackupError.damaged) { try TrainingBackupCodec.decode(missingLog) }

        let wrongType = try BackupFixtures.editedData { object in
            var payload = object["payload"] as? [String: Any] ?? [:]
            payload["workoutPlans"] = "three plans"
            object["payload"] = payload
        }
        #expect(throws: TrainingBackupError.damaged) { try TrainingBackupCodec.decode(wrongType) }

        let zeroVersion = try BackupFixtures.editedData { $0["schemaVersion"] = 0 }
        #expect(throws: TrainingBackupError.damaged) { try TrainingBackupCodec.decode(zeroVersion) }
    }

    @Test("Duplicate ids and invalid goals are refused before anything is written")
    func invalidContent() throws {
        var duplicateLog = BackupFixtures.full
        duplicateLog.workoutLog.append(duplicateLog.workoutLog[0])
        #expect(throws: TrainingBackupError.invalidContent("powtórzone wpisy w dzienniku")) {
            try TrainingBackupCodec.decode(BackupFixtures.data(duplicateLog))
        }

        var duplicatePlans = BackupFixtures.full
        duplicatePlans.workoutPlans.append(duplicatePlans.workoutPlans[0])
        #expect(throws: TrainingBackupError.invalidContent("powtórzone plany")) {
            try TrainingBackupCodec.decode(BackupFixtures.data(duplicatePlans))
        }

        var noGoals = BackupFixtures.full
        noGoals.weeklyGoal = WeeklyGoalHistory(versions: [WeeklyGoalVersion(
            effectiveFrom: StoreFixtures.october1,
            goals: [WeeklyGoal(metric: .trainingDays(days: 9))]
        )])
        #expect(throws: TrainingBackupError.invalidContent("niepoprawny cel tygodniowy")) {
            try TrainingBackupCodec.decode(BackupFixtures.data(noGoals))
        }
    }

    @Test("Oversized data is refused without decoding")
    func tooLarge() {
        let data = Data(count: TrainingBackupCodec.maximumFileSize + 1)
        #expect(throws: TrainingBackupError.tooLarge) { try TrainingBackupCodec.decode(data) }
    }

    /// The payload sections are the stores' current formats. Bumping any of
    /// these versions needs a new backup `schemaVersion` and a decoder for old files.
    @Test("Backup version 2 pins the placement, progress and plan formats it embeds")
    func pinnedPayloadVersions() {
        #expect(TrainingBackupCodec.schemaVersion == 2)
        #expect(SkillPlacement.schemaVersion == 2)
        #expect(SkillProgress.schemaVersion == 2)
        #expect(FileWorkoutPlanStore.schemaVersion == 2)
    }

    @Test("The summary counts workouts as sessions and names what is set")
    func summary() {
        let summary = BackupFixtures.full.summary
        // Three entries: one standalone, two in one session.
        #expect(summary.workouts == 2)
        #expect(summary.plans == 4)
        #expect(summary.favoriteParks == 2)
        #expect(summary.favoriteExercises == 2)
        #expect(summary.text == "2 treningi, 4 plany, test poziomu, cel tygodniowy, 2 ulubione Parki, 2 ulubione ćwiczenia")
        #expect(TrainingBackup(favoriteParkIDs: [UUID()]).summary.text == "0 treningów, 0 planów, 1 ulubiony Park")
        #expect(TrainingBackup(favoriteParkIDs: [UUID()]).summary.isEmpty == false)
        #expect(TrainingBackup(favoriteParkIDs: nil).summary.isEmpty)
        #expect(TrainingBackup().summary.isEmpty)
        #expect(TrainingBackup().summary.text == "0 treningów, 0 planów")
    }
}

/// Finds the test bundle for the golden fixture files.
private final class BundleToken {}

// MARK: - Service
@MainActor
@Suite("Training backup restore", .temporaryDirectories, .timeLimit(.minutes(1)))
struct TrainingBackupServiceTests {
    @Test("Restore replaces every store and the export reads it back")
    func restoreReplacesEverything() async throws {
        let rig = BackupRig.withOldData()
        try await rig.service.restore(BackupFixtures.full)

        #expect(try rig.service.currentBackup() == BackupFixtures.full)
        // Every screen sees the import through the shared services.
        #expect(rig.environment.journal.entries == BackupFixtures.full.workoutLog)
        #expect(rig.environment.progressService.placement == BackupFixtures.full.placement)
        #expect(rig.environment.weeklyGoalService.history == BackupFixtures.weeklyGoal)
        #expect(rig.environment.parkFavorites.ids == BackupFixtures.favoriteParks)
        #expect(rig.environment.exerciseFavorites.ids == BackupFixtures.favoriteExercises)
    }

    @Test("A backup from before plan records gets its plans recorded on import")
    func legacyBackupRecordsItsPlans() async throws {
        let rig = BackupRig.withOldData()
        var legacy = BackupFixtures.full
        legacy.weeklyGoal?.planSchedules = []
        try await rig.service.restore(legacy)

        let records = try #require(rig.environment.weeklyGoalService.history?.planSchedules)
        #expect(records.map(\.plans) == [PlanScheduleRecord.scheduled(StoreFixtures.workoutPlans)])
        #expect(try rig.service.currentBackup().weeklyGoal?.versions == legacy.weeklyGoal?.versions)
    }

    @Test("An import is not progress: no celebration and no XP toast")
    func restoreDoesNotCelebrate() async throws {
        let rig = BackupRig()
        let strongLog = (0..<6).map { day in
            WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                            date: StoreFixtures.october1.addingTimeInterval(Double(day) * 86_400),
                            sets: Array(repeating: LoggedSet(reps: 10), count: 3))
        }
        try await rig.service.restore(TrainingBackup(workoutLog: strongLog))

        #expect(rig.environment.progressService.snapshot.level.totalXP > 0)
        #expect(rig.environment.rewardCenter.current == nil)
        #expect(rig.environment.rewardCenter.xpToastAmount == nil)
    }

    @Test("Restoring nothing-saved sections clears them")
    func restoreClearsOptionalSections() async throws {
        let rig = BackupRig.withOldData()
        try await rig.service.restore(TrainingBackup())

        #expect(try rig.placement.load() == nil)
        // The old "celebrated" record is gone; the reward loop then seeds a
        // fresh, silent baseline for the (empty) imported history.
        #expect(try rig.progress.load() != SkillProgress(celebratedLevel: 2))
        #expect(rig.environment.rewardCenter.current == nil)
        #expect(try rig.log.load().isEmpty)
        #expect(try rig.plans.load().isEmpty)
    }

    @Test("Restore re-syncs plan reminders from the imported plans")
    func restoreSyncsReminders() async throws {
        let rig = BackupRig()
        let plan = WorkoutPlan(name: "Push", exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID)],
                               schedule: .weekly(Set(Weekday.allCases)), reminderTime: DateComponents(hour: 18, minute: 0))
        try await rig.service.restore(TrainingBackup(workoutPlans: [plan]))

        #expect(await rig.scheduler.rescheduleCount == 1)
        #expect(await rig.scheduler.scheduledRequests.contains { $0.planID == plan.id })
    }

    @Test("A failed write rolls every store back to the data before the import")
    func failedWriteRollsBack() async throws {
        let oldPlan = WorkoutPlan(name: "Stary plan", schedule: .once(nil), createdAt: StoreFixtures.october1)
        let rig = BackupRig(
            plans: FailingReplacePlanStore(initial: [oldPlan]),
            placement: InMemorySkillPlacementStore(initial: SkillPlacement(declaredRungByPath: [.core: 1], declaredAt: StoreFixtures.october1)),
            progress: InMemorySkillProgressStore(initial: SkillProgress(celebratedLevel: 2))
        )
        let before = try rig.service.currentBackup()

        await #expect(throws: TrainingBackupRestoreError.failedAndRolledBack) {
            try await rig.service.restore(BackupFixtures.full)
        }
        // Placement, progress and goal were written before the plans failed;
        // all three are back, and the log was never touched.
        #expect(try rig.service.currentBackup() == before)
    }

    @Test("A rollback that cannot finish is reported as such")
    func incompleteRollback() async throws {
        // Placement takes the import, the plans fail, and the placement then
        // refuses the rollback.
        let rig = BackupRig(
            plans: FailingReplacePlanStore(initial: []),
            placement: OneShotPlacementStore(initial: nil)
        )

        await #expect(throws: TrainingBackupRestoreError.failedRollbackIncomplete) {
            try await rig.service.restore(BackupFixtures.full)
        }
        // The failed plan write changed nothing, so it does not count as
        // a rollback failure; the stuck placement does.
        #expect(try rig.placement.load() == StoreFixtures.placement)
        #expect(try rig.plans.load().isEmpty)
    }

    @Test("Unreadable current data stops the import before any write")
    func unreadableCurrentData() async throws {
        let saved = SkillPlacement(declaredRungByPath: [.core: 1], declaredAt: StoreFixtures.october1)
        let placement = InMemorySkillPlacementStore(initial: saved)
        let rig = BackupRig(log: UnreadableWorkoutLogStore(), placement: placement)

        await #expect(throws: TrainingBackupRestoreError.currentDataUnreadable) {
            try await rig.service.restore(BackupFixtures.full)
        }
        #expect(placement.load() == saved)
    }

    @Test("Export and import roundtrip through the real file stores")
    func fileStoreRoundtrip() async throws {
        let source = try TemporaryDirectory.make("backup-tests")
        let target = try TemporaryDirectory.make("backup-tests")
        defer {
            try? FileManager.default.removeItem(at: source)
            try? FileManager.default.removeItem(at: target)
        }
        func rig(_ directory: URL) -> BackupRig {
            BackupRig(
                log: FileWorkoutLogStore(directory: directory),
                plans: FileWorkoutPlanStore(directory: directory),
                placement: FileSkillPlacementStore(directory: directory),
                progress: FileSkillProgressStore(directory: directory),
                goal: FileWeeklyGoalStore(directory: directory),
                favorites: FileFavoriteParkStore(directory: directory),
                exerciseFavorites: FileFavoriteExerciseStore(directory: directory)
            )
        }
        let exporter = rig(source)
        try await exporter.service.restore(BackupFixtures.full)
        let data = try TrainingBackupCodec.encode(exporter.service.currentBackup(),
                                                  exportedAt: BackupFixtures.exportedAt, appVersion: "1.0 (1)")

        let importer = rig(target)
        try importer.placement.save(SkillPlacement(declaredRungByPath: [.core: 1]))
        try await importer.service.restore(TrainingBackupCodec.decode(data))

        #expect(try importer.service.currentBackup() == BackupFixtures.full)
    }

    @Test("Replacing a file store with nothing deletes its file")
    func fileStoreClear() throws {
        let directory = try TemporaryDirectory.make("backup-tests")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileSkillPlacementStore(directory: directory)
        try store.save(StoreFixtures.placement)

        try store.replace(with: nil)

        #expect(try store.load() == nil)
        #expect(FileManager.default.fileExists(atPath: directory.appending(path: "skill-placement.json").path()) == false)
        try store.replace(with: nil)
    }

    @Test("A broken file store refuses to be replaced, so the import rolls back")
    func brokenFileStoreRefusesReplace() throws {
        let directory = try TemporaryDirectory.make("backup-tests")
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("{ broken".utf8).write(to: directory.appending(path: "weekly-goal.json"))
        let store = FileWeeklyGoalStore(directory: directory)

        #expect(throws: (any Error).self) { try store.replace(with: nil) }
        #expect(throws: (any Error).self) { try store.replace(with: BackupFixtures.weeklyGoal) }
    }
}

// MARK: - View model
@MainActor
@Suite("Export and import screen", .temporaryDirectories, .timeLimit(.minutes(1)))
struct TrainingBackupViewModelTests {
    private func viewModel(_ rig: BackupRig, directory: URL) -> TrainingBackupViewModel {
        TrainingBackupViewModel(
            service: rig.service,
            exportDirectory: directory,
            appVersion: "1.0 (1)",
            calendar: ProgramFixtures.calendar,
            clock: { ProgramFixtures.today }
        )
    }

    @Test("Export writes a dated file that decodes to the saved data")
    func export() async throws {
        let directory = try TemporaryDirectory.make("backup-tests")
        defer { try? FileManager.default.removeItem(at: directory) }
        let rig = BackupRig()
        try await rig.service.restore(BackupFixtures.full)
        let model = viewModel(rig, directory: directory)

        model.prepareExport()

        let file = try #require(model.exportFile)
        #expect(file.lastPathComponent == "calipark-backup-2026-11-04.json")
        #expect(try TrainingBackupCodec.decode(Data(contentsOf: file)) == BackupFixtures.full)
        #expect(model.currentSummary == BackupFixtures.full.summary)
    }

    @Test("Export offers no file when the data cannot be read")
    func exportUnreadable() throws {
        let directory = try TemporaryDirectory.make("backup-tests")
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = viewModel(BackupRig(log: UnreadableWorkoutLogStore()), directory: directory)

        model.prepareExport()

        #expect(model.exportFile == nil)
        #expect(model.errorMessage == StoreLoadFailure.message)
    }

    @Test("Reviewing a file asks first and writes nothing")
    func reviewAsksFirst() throws {
        let rig = BackupRig.withOldData()
        let model = viewModel(rig, directory: try TemporaryDirectory.make("backup-tests"))

        model.review(try BackupFixtures.data())

        let pending = try #require(model.pendingImport)
        #expect(pending.incoming.text == "2 treningi, 4 plany, test poziomu, cel tygodniowy, 2 ulubione Parki, 2 ulubione ćwiczenia")
        #expect(pending.current.text == "1 trening, 1 plan, test poziomu, 1 ulubiony Park, 1 ulubione ćwiczenie")
        #expect(try rig.log.load().count == 1)
    }

    @Test("Cancel drops the reviewed file")
    func cancel() throws {
        let rig = BackupRig.withOldData()
        let model = viewModel(rig, directory: try TemporaryDirectory.make("backup-tests"))
        model.review(try BackupFixtures.data())

        model.cancelImport()

        #expect(model.pendingImport == nil)
        #expect(try rig.plans.load().map(\.name) == ["Stary plan"])
    }

    @Test("Confirming replaces the data and reports what was imported")
    func confirm() async throws {
        let directory = try TemporaryDirectory.make("backup-tests")
        defer { try? FileManager.default.removeItem(at: directory) }
        let rig = BackupRig.withOldData()
        let model = viewModel(rig, directory: directory)
        model.review(try BackupFixtures.data())
        let pending = try #require(model.pendingImport)

        await model.confirmImport(pending)

        #expect(model.resultMessage == "Zaimportowano: 2 treningi, 4 plany, test poziomu, cel tygodniowy, 2 ulubione Parki, 2 ulubione ćwiczenia.")
        #expect(model.errorMessage == nil)
        #expect(try rig.service.currentBackup() == BackupFixtures.full)
        #expect(model.currentSummary == BackupFixtures.full.summary)
    }

    @Test("A bad file shows its reason and leaves nothing pending")
    func badFile() throws {
        let model = viewModel(BackupRig(), directory: try TemporaryDirectory.make("backup-tests"))

        model.review(try BackupFixtures.editedData { $0["schemaVersion"] = 7 })

        #expect(model.pendingImport == nil)
        #expect(model.errorMessage == TrainingBackupError.newerVersion(7).message)
    }

    @Test("A picked file is read from disk")
    func reviewFile() throws {
        let directory = try TemporaryDirectory.make("backup-tests")
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "calipark-backup-2026-10-02.json")
        try BackupFixtures.data().write(to: url)
        let model = viewModel(BackupRig(), directory: directory)

        model.review(fileAt: url)
        #expect(model.pendingImport?.backup == BackupFixtures.full)

        model.review(fileAt: directory.appending(path: "missing.json"))
        #expect(model.errorMessage == TrainingBackupError.unreadableFile.message)
    }
}

// MARK: - Favorite Parks
@MainActor
@Suite("Favorite Parks in the training backup", .timeLimit(.minutes(1)))
struct TrainingBackupFavoritesTests {
    /// A version 1 file written before favorites existed: no `favoriteParks`.
    private static func oldBackupData() throws -> Data {
        try BackupFixtures.editedData { object in
            var payload = object["payload"] as? [String: Any] ?? [:]
            payload.removeValue(forKey: "favoriteParks")
            object["payload"] = payload
        }
    }

    @Test("The export writes favorites as Park IDs in the payload")
    func exportWritesFavorites() throws {
        let object = try #require(JSONSerialization.jsonObject(with: BackupFixtures.data()) as? [String: Any])
        let payload = try #require(object["payload"] as? [String: Any])
        #expect(payload["favoriteParks"] as? [String] == BackupFixtures.favoriteParks.map(\.uuidString))
    }

    @Test("A backup from before favorites still reads, saying nothing about them")
    func oldBackupDecodes() throws {
        let decoded = try TrainingBackupCodec.decode(Self.oldBackupData())
        #expect(decoded.favoriteParkIDs == nil)
        var expected = BackupFixtures.full
        expected.favoriteParkIDs = nil
        #expect(decoded == expected)
    }

    @Test("Importing an old backup keeps the favorites on the phone")
    func oldBackupKeepsFavorites() async throws {
        let rig = BackupRig.withOldData()
        try await rig.service.restore(TrainingBackupCodec.decode(Self.oldBackupData()))

        #expect(try rig.favorites.load() == [BackupFixtures.oldFavorite])
        #expect(rig.environment.parkFavorites.ids == [BackupFixtures.oldFavorite])
        // Everything else was still replaced.
        #expect(rig.environment.journal.entries == BackupFixtures.full.workoutLog)
    }

    @Test("An empty favorites list in the file clears them")
    func emptyFavoritesClear() async throws {
        let rig = BackupRig.withOldData()
        try await rig.service.restore(TrainingBackup())

        #expect(try rig.favorites.load().isEmpty)
        #expect(rig.environment.parkFavorites.ids.isEmpty)
    }

    @Test("Duplicate favorites are refused before anything is written")
    func duplicateFavoritesRefused() {
        let id = UUID()
        #expect(throws: TrainingBackupError.invalidContent("powtórzone ulubione Parki")) {
            try TrainingBackupCodec.validate(TrainingBackup(favoriteParkIDs: [id, id]))
        }
    }

    @Test("A failed write puts the favorites back too")
    func failedWriteRollsBackFavorites() async throws {
        let rig = BackupRig(
            plans: FailingReplacePlanStore(initial: []),
            favorites: InMemoryFavoriteParkStore(initial: [BackupFixtures.oldFavorite])
        )

        await #expect(throws: TrainingBackupRestoreError.failedAndRolledBack) {
            try await rig.service.restore(BackupFixtures.full)
        }
        #expect(try rig.favorites.load() == [BackupFixtures.oldFavorite])
        #expect(rig.environment.parkFavorites.ids == [BackupFixtures.oldFavorite])
    }

    @Test("Unreadable favorites stop the export and the import")
    func unreadableFavorites() async throws {
        let store = InMemoryFavoriteParkStore(initial: [BackupFixtures.oldFavorite], failure: .init())
        let rig = BackupRig(favorites: store)

        #expect(throws: StoreLoadFailure.self) { try rig.service.currentBackup() }
        await #expect(throws: TrainingBackupRestoreError.currentDataUnreadable) {
            try await rig.service.restore(BackupFixtures.full)
        }
        store.failure = nil
        #expect(try store.load() == [BackupFixtures.oldFavorite])
        #expect(store.saveCount == 0)
    }
}

// MARK: - Favorite exercises
@MainActor
@Suite("Favorite exercises in the training backup", .timeLimit(.minutes(1)))
struct TrainingBackupExerciseFavoritesTests {
    /// A file written before exercise favorites existed: no `favoriteExercises`.
    private static func oldBackupData() throws -> Data {
        try BackupFixtures.editedData { object in
            var payload = object["payload"] as? [String: Any] ?? [:]
            payload.removeValue(forKey: "favoriteExercises")
            object["payload"] = payload
        }
    }

    @Test("The export writes favorite exercises as exercise IDs in the payload")
    func exportWritesFavorites() throws {
        let object = try #require(JSONSerialization.jsonObject(with: BackupFixtures.data()) as? [String: Any])
        let payload = try #require(object["payload"] as? [String: Any])
        #expect(payload["favoriteExercises"] as? [String] == BackupFixtures.favoriteExercises.map(\.uuidString))
        #expect(object["schemaVersion"] as? Int == 2)
    }

    @Test("A backup from before exercise favorites still reads, saying nothing about them")
    func oldBackupDecodes() throws {
        let decoded = try TrainingBackupCodec.decode(Self.oldBackupData())
        #expect(decoded.favoriteExerciseIDs == nil)
        var expected = BackupFixtures.full
        expected.favoriteExerciseIDs = nil
        #expect(decoded == expected)
    }

    @Test("Importing an old backup keeps the favorite exercises on the phone")
    func oldBackupKeepsFavorites() async throws {
        let rig = BackupRig.withOldData()
        try await rig.service.restore(TrainingBackupCodec.decode(Self.oldBackupData()))

        #expect(try rig.exerciseFavorites.load() == [BackupFixtures.oldFavoriteExercise])
        #expect(rig.environment.exerciseFavorites.ids == [BackupFixtures.oldFavoriteExercise])
        // Everything else was still replaced.
        #expect(rig.environment.journal.entries == BackupFixtures.full.workoutLog)
        #expect(rig.environment.parkFavorites.ids == BackupFixtures.favoriteParks)
    }

    @Test("Importing a backup with favorite exercises replaces them")
    func importReplacesFavorites() async throws {
        let rig = BackupRig.withOldData()
        try await rig.service.restore(BackupFixtures.full)

        #expect(try rig.exerciseFavorites.load() == BackupFixtures.favoriteExercises)
        #expect(rig.environment.exerciseFavorites.ids == BackupFixtures.favoriteExercises)
    }

    @Test("An empty favorite exercises list in the file clears them")
    func emptyFavoritesClear() async throws {
        let rig = BackupRig.withOldData()
        try await rig.service.restore(TrainingBackup())

        #expect(try rig.exerciseFavorites.load().isEmpty)
        #expect(rig.environment.exerciseFavorites.ids.isEmpty)
    }

    @Test("Duplicate favorite exercises are refused before anything is written")
    func duplicateFavoritesRefused() {
        let id = ExerciseCatalog.dipsID
        #expect(throws: TrainingBackupError.invalidContent("powtórzone ulubione ćwiczenia")) {
            try TrainingBackupCodec.validate(TrainingBackup(favoriteExerciseIDs: [id, id]))
        }
    }

    @Test("A failed write puts the favorite exercises back too")
    func failedWriteRollsBackFavorites() async throws {
        let rig = BackupRig(
            plans: FailingReplacePlanStore(initial: []),
            exerciseFavorites: InMemoryFavoriteExerciseStore(initial: [BackupFixtures.oldFavoriteExercise])
        )

        await #expect(throws: TrainingBackupRestoreError.failedAndRolledBack) {
            try await rig.service.restore(BackupFixtures.full)
        }
        #expect(try rig.exerciseFavorites.load() == [BackupFixtures.oldFavoriteExercise])
        #expect(rig.environment.exerciseFavorites.ids == [BackupFixtures.oldFavoriteExercise])
    }

    @Test("Unreadable favorite exercises stop the export and the import")
    func unreadableFavorites() async throws {
        let store = InMemoryFavoriteExerciseStore(initial: [BackupFixtures.oldFavoriteExercise], failure: .init())
        let rig = BackupRig(exerciseFavorites: store)

        #expect(throws: StoreLoadFailure.self) { try rig.service.currentBackup() }
        await #expect(throws: TrainingBackupRestoreError.currentDataUnreadable) {
            try await rig.service.restore(BackupFixtures.full)
        }
        store.failure = nil
        #expect(try store.load() == [BackupFixtures.oldFavoriteExercise])
        #expect(store.saveCount == 0)
    }

    @Test("The summary counts favorite exercises with the right Polish form", arguments: [
        (1, "0 treningów, 0 planów, 1 ulubione ćwiczenie"),
        (3, "0 treningów, 0 planów, 3 ulubione ćwiczenia"),
        (5, "0 treningów, 0 planów, 5 ulubionych ćwiczeń")
    ])
    func summaryText(count: Int, text: String) {
        let backup = TrainingBackup(favoriteExerciseIDs: (0..<count).map { _ in UUID() })
        #expect(backup.summary.text == text)
        #expect(backup.summary.isEmpty == false)
    }
}
