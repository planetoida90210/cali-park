# CaliPark

iOS calisthenics app in SwiftUI with no third-party dependencies. The UI copy and the docs in `docs/` are Polish. Write code, new comments and commit messages in English; some legacy files still have Polish comments.

## Verify every change

Build and run the unit tests yourself before you call a change done. The sprint docs (`docs/SPRINTS*.md`) and `.cursor/plans/*.plan.md` say "NIE uruchamiaj `xcodebuild`" (don't run xcodebuild). That rule is retired.

```sh
xcodebuild -project cali-park.xcodeproj -scheme cali-park \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath "$TMPDIR/dd" -only-testing:cali-parkTests test
```

- Simulator access fails inside the Bash sandbox (CoreSimulator, xcrun cache). Run xcodebuild with the sandbox disabled.
- Baseline as of 2026-11-03: the build has zero warnings and every unit test passes (270 `@Test` functions, 512 cases including parameterized ones). Keep the build warning-free and the tests green.
- Targets use synchronized folders. A new file under `cali-park/` or `cali-parkTests/` is compiled automatically, so add files without editing `project.pbxproj`.

## Toolchain facts

- The deployment target is iOS 18.4. Gate any iOS 26+ API with `#available`.
- The project is in Swift 5 language mode, and `SWIFT_DEFAULT_ACTOR_ISOLATION` is unset. The "main actor isolation is on by default" line in the rules file below therefore does not apply. Mark UI-bound types `@MainActor` explicitly until that setting changes to `MainActor`.

## SwiftUI rules

@.cursor/rules/project-rules.mdc

## Architecture conventions

- The composition root is `cali-park/Core/AppEnvironment.swift`. Services are created there once and passed to view models through its `make…ViewModel()` factories (initializer injection). Pass every store explicitly. Several legacy view model initializers give stores default arguments, and that silently disconnects them from the root.
- Persistence is a set of small stores behind protocols: `WorkoutLogStoring`, `WorkoutPlanStoring`, `PlacementStoring`, `SkillProgressStoring`, `FavoritesStoring`. The app uses the `File…` implementations (`UserDefaultsFavoritesStore` for favorites), and tests use `InMemory…`. For previews use `AppEnvironment.seeded(...)`, which is in-memory. `AppEnvironment.preview` is backed by the real file stores.
- File stores encode dates as ISO 8601 with whole seconds, so roundtrip fixtures need whole-second dates.
- Core Data (`cali-park/Core/Services/Persistence.swift`, `cali_park.xcdatamodeld`) is an empty scaffold. The model has no entities and nothing reads the context, but `cali_parkApp.swift` still creates it at launch. New persistence goes in a store.
- Domain logic lives in caseless enums of static pure functions: `ProgressionEngine`, `RewardEvaluator`, `WorkoutReminderPlanner`, `PlacementCalibration`. Date-dependent APIs take the calendar and reference date as parameters (`calendar:`, `asOf:`/`today:`/`declaredAt:`), defaulting to `.current`/`.now`. Read the wall clock only through those defaults, and pass explicit values in tests.
- Model new code on Exercises, Planner, Skills and Home's dashboard view model: `@Observable` + `@MainActor`, `navigationDestination(for:)`, and the `Tab` API in `MainTabView`. These are legacy, so don't copy them: Parks (ObservableObject, mocks), Profile (placeholder), Community (unreachable), and Home's module system (`ModuleDefinition`/`ModulePreferences`, `MockDataProvider`).
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
