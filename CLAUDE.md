# CaliPark

iOS calisthenics app in SwiftUI with no third-party dependencies. The UI copy and the docs in `docs/` are Polish. Write code, new comments and commit messages in English; some legacy files still have Polish comments.

## Verify every change

Build and run the unit tests yourself before you call a change done. The sprint docs (`docs/SPRINTS*.md`) and `.cursor/plans/*.plan.md` say "NIE uruchamiaj `xcodebuild`" (don't run xcodebuild). That rule is retired.

```sh
xcodebuild -project cali-park.xcodeproj -scheme cali-park \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath "$TMPDIR/dd" -only-testing:cali-parkTests test
```

- Simulator access fails inside the Bash sandbox (CoreSimulator, xcrun cache). Run xcodebuild with the sandbox disabled.
- Some simulator names exist on more than one runtime. Without `OS=26.5` in the destination, xcodebuild may fail to match a device; `id=<UDID>` from `xcrun simctl list devices` also works.
- Baseline as of 2026-11-04, after favorite exercises (`3ec8014`): the build has zero warnings and every unit test passes (839 `@Test` functions, 1278 cases including parameterized ones). Keep the build warning-free and the tests green.
- Targets use synchronized folders. A new file under `cali-park/` or `cali-parkTests/` is compiled automatically, so add files without editing `project.pbxproj`.

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs on every push to `main`, on every pull request, and on manual dispatch. CI must stay green: a red `test` job on `main` is a regression to fix before anything else.

- **`test`** (blocking): on the `macos-26` runner with Xcode 26.6 (CI uses an older Xcode than the local one; see `XCODE_VERSION` in the workflow), it runs the unit tests on an iPhone simulator picked by `scripts/ci-pick-simulator.sh` (iOS 26.5 when installed), with `CODE_SIGNING_ALLOWED=NO`. Then `scripts/check-build-warnings.sh` fails the job on any line containing `warning:`, except `appintentsmetadataprocessor` notes. When the job fails, it uploads the `.xcresult` and the full log as the `test-results` artifact. To bump Xcode, change the runner image and `XCODE_VERSION` together, after checking the image's readme in `actions/runner-images`.
- **`lint`** (report only, `continue-on-error: true`): `scripts/lint-rules.sh --baseline scripts/lint-rules.baseline` counts violations of the clearest rules in `project-rules.mdc` and flags any rule whose count exceeds the baseline. `xcrun swift-format lint --recursive` checks style against `.swift-format`. Both write a summary to the job page.
- Run the same checks locally: `scripts/lint-rules.sh` (add `--baseline scripts/lint-rules.baseline` to check for new violations), `xcrun swift-format lint --recursive --parallel cali-park cali-parkTests cali-parkUITests`, and `scripts/check-build-warnings.sh <xcodebuild log>`.
- After you fix rule violations, lower the baseline with `scripts/lint-rules.sh --write-baseline scripts/lint-rules.baseline` and commit it, so the fixed violations can't come back. Never raise it to make a new violation pass.
- To make lint blocking, remove `continue-on-error: true` from the `lint` job. The rules step then fails on any count above the baseline. For swift-format, add `--strict` once the code is formatted (`xcrun swift-format format --in-place --recursive …`).

## Toolchain facts

- The deployment target is iOS 18.4. Gate any iOS 26+ API with `#available`.
- Every target is in Swift 6 language mode, so data-race checking is complete and its diagnostics are errors. The app and unit test targets also set `SWIFT_APPROACHABLE_CONCURRENCY=YES`: a plain `nonisolated async` function runs on its caller's actor, and needs `@concurrent` to leave it.
- The app target sets `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`, so every type in `cali-park/` is main-actor isolated unless marked otherwise, and the rules file's "main actor isolation is on by default" line applies. Mark pure domain code `nonisolated` (models, catalogs, engines, planners, formatters, stores, codecs, `JSONFileStore`): tests and actors use it off the main actor. Existing explicit `@MainActor` annotations are redundant but harmless. The unit test target keeps nonisolated default isolation, so a Swift Testing suite that touches main-actor types is marked `@MainActor`.
- Don't use `DispatchQueue`, Combine, `Task.sleep(nanoseconds:)`, `@unchecked Sendable` or `nonisolated(unsafe)` in app code. Wait with `Task.sleep(for:)` in `.task(id:)`, and return on cancellation instead of `try?`.

## SwiftUI rules

@.cursor/rules/project-rules.mdc

## Architecture conventions

- The composition root is `cali-park/Core/AppEnvironment.swift`. Services are created there once and passed to view models through its `make…ViewModel()` factories (initializer injection). Pass every store explicitly. Several legacy view model initializers give stores default arguments, and that silently disconnects them from the root.
- Persistence is a set of small stores behind protocols: `WorkoutLogStoring`, `WorkoutPlanStoring`, `PlacementStoring`, `SkillProgressStoring`, `WeeklyGoalStoring`, `FavoriteParkStoring`. The app uses the `File…` implementations, and tests use `InMemory…`. For previews use `AppEnvironment.seeded(...)`, which is in-memory. `AppEnvironment.preview` is backed by the real file stores.
- Workout logs have one write path: `TrainingJournal` (`log`, `logSession`, `delete(ids:)`, `revision`, `loadFailure`), created once in `AppEnvironment`. Never write to `WorkoutLogStoring` from a view model, and don't add reload-on-dismiss calls: screens read the journal and update by observation. Its change handlers re-sync reminders and drive progress.
- Progress (path states, XP, level, badges, hint) comes from `ProgressService.snapshot`, computed once per journal revision and placement change by `ProgressionEngine.snapshot(...)`. Celebrations (rungs, levels, then met weekly goals from `WeeklyGoalService`) and the XP toast come from the one `RewardCenter`, shown by `.rewardOverlay()` (on the tab root and on sheets that stay up after a save). Don't add another celebration overlay; add the source to `RewardCenter`. Format sets, reps, seconds and criteria with `MeasureFormat`.
- File stores encode dates as ISO 8601 with whole seconds, so roundtrip fixtures need whole-second dates.
- Every `File…` store is a thin wrapper over `JSONFileStore` (`cali-park/Core/Services/JSONFileStore.swift`). A missing file reads as empty or nil. An unreadable or undecodable file makes `load()` throw, is copied aside as `<name>.corrupt-<timestamp>.json`, and blocks writes, so it is never overwritten. New writes use the `{"schemaVersion": 1, "payload": …}` envelope, and reads still accept the bare legacy format. View models must handle a throwing `load()` by showing an error (`StoreLoadFailure.message`), never by treating it as an empty journal. The golden files in `cali-parkTests/Fixtures/` hold the real legacy on-disk format, so never regenerate them.
- The store files live in `Application Support/CaliPark/` (`StoreDirectoryMigration.defaultDirectory`). File names are the `StoreFile` cases. `AppEnvironment.live()` builds the app's stores: before any store loads it moves the files from Documents (where versions up to 1.0 kept them), never overwriting and leaving a file in Documents when its move fails, and deletes the removed Core Data scaffold's empty `cali_park.sqlite` once. `File…` store initializers take the directory explicitly; tests use temp directories.
- There is no Core Data: the empty scaffold was removed. New persistence goes in a store.
- Every `UserDefaults`/`@AppStorage` key is a `DefaultsKey` case (`cali-park/Core/Storage/DefaultsKey.swift`); never write a key literal or rename a raw value.
- Day-only values (a one-off plan's day, an interval's anchor) are `CalendarDay`s (`"yyyy-MM-dd"`), not `Date`s, so they don't move when the time zone changes. Resolve them with `startDate(in: calendar)`.
- Domain logic lives in caseless enums of static pure functions: `ProgressionEngine`, `RewardEvaluator`, `WorkoutReminderPlanner`, `PlacementCalibration`. Date-dependent APIs take the calendar and reference date as parameters (`calendar:`, `asOf:`/`today:`/`declaredAt:`), defaulting to `.current`/`.now`. Read the wall clock only through those defaults, and pass explicit values in tests.
- Model new code on Exercises, Planner, Skills, Profile, Programs, WeeklyGoal, Parks (`ParkMapViewModel`) and Home's dashboard view model: `@Observable` (main-actor by default), `navigationDestination(for:)`, and the `Tab` API in `MainTabView`. Home's module order lives in `ModulePreferences` (`DefaultsKey.enabledModules`, created in `AppEnvironment` with the injected `UserDefaults`); previews and tests get a throwaway suite through `AppEnvironment.seeded(...)` or `UserDefaults.throwaway()`.
- Favorite Parks ("Ulubione") are Park IDs on the phone. `ParkFavorites`, created once in `AppEnvironment`, is their one write path, shared by the Parks tab and the training backup. IDs of Parks missing from the snapshot are kept and simply not shown.
- Favorite exercises ("Ulubione") are catalog exercise IDs on the phone, variants included. `ExerciseFavorites`, created once in `AppEnvironment` and injected into the SwiftUI environment by `MainTabView`, is their one write path, shared by the exercise pickers, the Exercises tab, the detail screen's star and the training backup. `ExerciseListSections` builds every exercise list: favorites first, then the catalog as before; a search is one flat list of all matches.
- Parks are read-only and come through `ParkDirectory` (`BundledParkDirectory` reads `cali-park/Resources/Parks/parks-osm-pl.json`; `InMemoryParkDirectory` in tests). The snapshot is built by `scripts/osm/build_parks_snapshot.py` (see `scripts/osm/README.md`) and the same data is the public ODbL dump in `data/`, so regenerate both together and never edit them by hand. Park names and localities come from OSM only: never store anything from MapKit geocoding or POIs. Every screen that shows OSM Parks carries the "© Współtwórcy OpenStreetMap" credit.
- Location goes through `LocationProviding` (`CoreLocationProvider`, `FixedLocationProvider` in tests and previews). Only the first Parks map open may show the permission prompt; everything else reads the position only when it is already allowed. The position is never stored.
- Use `PolishPlural` for counted nouns ("1 seria, 3 serie, 5 serii").
- `docs/PROGRESSIONS.md` is the source of truth for progression ladders. When you touch `ProgressionCatalog` or exercise variants in `ExerciseCatalog`, keep the code and that doc in sync 1:1.

## Tests

Tests use Swift Testing (`import Testing`). Build fixtures on a gregorian UTC `Calendar`, a fixed reference date, and `InMemory…` stores or a temp directory, so every test is deterministic.

## Known issues

Before you fix bugs or plan work, read `docs/audit/README.md`. It is the 2026-11-03 audit, with priorities and finding IDs that point into `docs/audit/findings.md`.

## Git

- When you commit, commit straight to `main`, not a feature branch. The owner keeps a GitHub contribution streak, which only counts commits on the default branch.
- Write plain commit messages with no `Co-Authored-By` or other agent attribution trailers.

## Skills

Claude Code loads project skills from `.claude/skills/` only. `npx skills add` installs into `.agents/skills/` (gitignored) by default. Pass `-a claude-code`, or symlink the skill into `.claude/skills/<name>`.
