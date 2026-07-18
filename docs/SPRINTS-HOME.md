# Tracker sprintów — Kontekstowy hero na Home

Plan źródłowy: [.cursor/plans/kontekstowy_hero_na_home_b5072ca9.plan.md](../.cursor/plans/kontekstowy_hero_na_home_b5072ca9.plan.md)
Poprzedni tracker (kontekst Sprintów 1–8, zamknięty): [docs/SPRINTS.md](SPRINTS.md)

## Instrukcja dla agenta

1. Znajdź w tabeli pierwszy sprint ze statusem `oczekuje` — to twój sprint. Wykonaj TYLKO jego zakres z planu.
2. Jeśli poprzedni sprint ma status `do weryfikacji`, ZATRZYMAJ SIĘ i poproś użytkownika o weryfikację buildu w Xcode — nie zaczynaj kolejnego sprintu na niezweryfikowanym fundamencie.
3. Przed startem przeczytaj: cały plan źródłowy, WSZYSTKIE wpisy w dzienniku poniżej oraz notatki końcowe w [docs/SPRINTS.md](SPRINTS.md) (sekcja „Zamknięcie planu" — stan kodu po Sprintach 1–8).
4. Przeczytaj skille przypisane twojemu sprintowi w planie (sekcja „Obowiązkowe skille") ZANIM napiszesz kod.
5. NIE uruchamiaj `xcodebuild` ani żadnej weryfikacji kompilacji — build i testy sprawdza użytkownik ręcznie w Xcode.
6. Trzymaj się sekcji „Wymogi pod App Store review" z planu — dostępność, Dynamic Type, zero deprecated API, zero nowych uprawnień, żadnych martwych przycisków.
7. Po skończeniu pracy:
   - zmień status swojego sprintu w tabeli na `do weryfikacji`,
   - odhacz swoje todos w pliku planu (status `completed`),
   - dopisz wpis do dziennika wg szablonu poniżej.
8. Status `zakończony` ustawia wyłącznie użytkownik po ręcznym buildzie i testach.

## Status sprintów

| Sprint | Zakres (skrót) | Status | Data |
|---|---|---|---|
| H1 | Fundament stanu (bez UI): planID w WorkoutLogEntry, HomeHeroState, heroState(asOf:) w HomeDashboardViewModel, testy parametryzowane | do weryfikacji | 2026-07-18 |
| H2 | Widoki hero: ContextualHeroView + widoki per stan (Views/Components/Hero/), animacje + Reduce Motion, copy PL, previews per stan + galeria (bez integracji z HomeView) | do weryfikacji | 2026-07-18 |
| H3 | Integracja: ContextualHeroView w HomeView (ActiveSheet), rail z wejściem „Plany", seedowane previews AppEnvironment, bramka jakości App Store, testy akcji | oczekuje | — |

Statusy: `oczekuje` → `w toku` → `do weryfikacji` → `zakończony` (ustawia użytkownik).

## Dziennik sprintów

Szablon wpisu (kopiuj i wypełnij):

```
### Sprint HN — <data>, agent

**Zrobione:** (lista plików utworzonych/zmienionych, jednym zdaniem co w każdym)
**Odstępstwa od planu:** (co zrobiono inaczej niż w planie i dlaczego; „brak" jeśli nic)
**Decyzje podjęte w trakcie:** (np. copy per stan, nazwy typów, kształt animacji)
**Znane problemy / TODO:** (co zostawiono świadomie, co wymaga uwagi)
**Wskazówki dla następnego agenta:** (na co uważać, od czego zacząć)
**Do ręcznej weryfikacji przez użytkownika:** (build, testy, konkretne ścieżki smoke testu)
```

---

### Sprint H1 — 2026-07-18, agent (pierwszy z H1–H3)

**Zrobione:**
- `cali-park/Features/Exercises/Models/WorkoutLogEntry.swift` — nowe opcjonalne pole `planID: UUID?` (+ argument w `init`, domyślnie `nil`). Wstecznie zgodne przez syntezowany `Codable` (stare logi bez klucza → `nil`, jak `sessionID` w S5).
- `cali-park/Features/Exercises/ViewModels/QuickWorkoutViewModel.swift` — sesja pamięta `planID` (stała, ustawiana w `init(store:plan:)` = `plan.id`, a w `init(store:)` = `nil`); `finish()` stempluje każdy zapisany wpis tym `planID`. Dzięki temu wiemy precyzyjnie, że *dzisiejszy plan* został wykonany, a nie tylko „coś dziś zalogowano”.
- `cali-park/Features/Home/Models/HomeHeroState.swift` (NOWY) — enum `Equatable` z case'ami wg planu: `planToday(plan:loggedTodayReps:)`, `completedToday(summary:streak:)`, `restDay(nextPlan:date:streak:)`, `freeMode(lastWorkout:suggestion:streak:)`, `firstRun`. Czysty typ-wartość; widok (H2) będzie „głupi” i tylko przełącza się po case'ach.
- `cali-park/Features/Home/ViewModels/HomeDashboardViewModel.swift` — (1) `LatestWorkout` teraz `Equatable` (wymóg `Equatable` na `HomeHeroState`); (2) `streak(asOf:)` — testowalny rdzeń liczony na wstrzykniętym kalendarzu i jawnej dacie (property `streak` woła go z `.now`); (3) `heroState(asOf:)` — czysta, deterministyczna funkcja rozstrzygająca stan wg drzewa decyzyjnego z planu (plan dziś? → zrobiony? → trening dziś? → jakiś plan? → pusty dziennik?). Reużywa `nextPlannedWorkout(asOf:)`, `latestWorkout`, `suggestedExercise`, `streak(asOf:)`.
- `cali-parkTests/HomeHeroStateTests.swift` (NOWY) — Swift Testing, deterministyczny kalendarz UTC + jawna data odniesienia: parametryzowany `@Test(arguments:)` po 6 scenariuszach (plan dziś niezrobiony / plan dziś zrobiony przez `planID` / trening dziś bez planu / plan jutro → restDay / historia bez planów → freeMode / pusty dziennik → firstRun) + testy szczegółowe (planToday niesie plan i dzisiejszy progres; „zrobiony” tylko gdy log dziś ma `planID` planu; restDay podaje plan i dzień; freeMode podaje ostatni trening i streak; completedToday wlicza dziś do streaka); Codable `planID` (roundtrip + legacy JSON bez klucza → `nil`); `finish()` stempluje `planID` (sesja z planu) / brak `planID` (sesja wolna).

**Odstępstwa od planu:** brak. Sygnatury case'ów `HomeHeroState` i metody dokładnie jak w planie.

**Decyzje podjęte w trakcie:**
- Precyzja „plan zrobiony”: liczony po `planID` dzisiejszego logu (nie po „cokolwiek dziś”). Jeśli jest plan na dziś i użytkownik zalogował *wolny* trening (bez `planID`), stan zostaje `planToday`, a `loggedTodayReps` pokazuje progres — zgodnie z drzewem decyzyjnym (Q1: plan dziś → zrobiony? → jeśli nie, planToday).
- `LatestWorkout` zostaje zagnieżdżony w `HomeDashboardViewModel` (jest już tak używany w `LastWorkoutModuleContent`); `HomeHeroState` referuje `HomeDashboardViewModel.LatestWorkout` — bez przenoszenia typu, żeby nie ruszać plików spoza zakresu H1.
- Determinizm: dołożyłem `streak(asOf:)`, bo dotychczasowy `streak` liczył po `.now`/`.current` — to psułoby parametryzowane testy. Property `streak` zachowuje dotychczasowe zachowanie (woła `streak(asOf: .now)`), teraz na wstrzykniętym kalendarzu VM.
- Dwa oznaczone `init`-y w `QuickWorkoutViewModel` (zamiast `convenience`) — prościej i bez duplikacji ustawiania stałych.

**Znane problemy / TODO:**
- `weeklyPullUps` (drugorzędna linia hero) świadomie NIE trafia do case'ów enuma — widok H2 czyta ją wprost z VM (property bez zmian). Uwaga: `weeklyPullUps` nadal liczy po `Calendar.current`/`.now` (nie było w zakresie H1; jeśli H2/H3 będą chciały deterministycznej wersji do previews/testów, dołożyć `weeklyPullUps(asOf:)`).
- Zero zmian w UI (zgodnie z DoD H1). `HeroCardView` nietknięty.

**Wskazówki dla następnego agenta (H2):**
- Buduj `ContextualHeroView` jako głupi widok na `HomeHeroState` + closured akcje; osobne widoki per case w `Features/Home/Views/Components/Hero/`. Stan bierz z `dashboard.heroState` dopiero w H3 — w H2 podawaj stany wprost w `#Preview`.
- Nowe pliki kładź w katalogach synchronized groups (podpina się same do targetu) — testy w `cali-parkTests/`.
- Drugorzędna linia (tygodniowe podciągnięcia + ring) w completedToday/restDay/freeMode: czytaj `weeklyPullUps`/`streak` z VM, nie z enuma.

**Do ręcznej weryfikacji przez użytkownika:**
- Build w Xcode. Zmienione: `WorkoutLogEntry`, `QuickWorkoutViewModel`, `HomeDashboardViewModel`. Nowe: `HomeHeroState.swift`, `HomeHeroStateTests.swift`.
- Testy: `HomeHeroStateTests` (`HomeHeroStateResolutionTests` — parametryzowane + szczegółowe, `WorkoutLogEntryPlanIDCodableTests`, `QuickWorkoutPlanIDTests`) + wszystkie poprzednie (stare `QuickWorkoutTests`/`HomePlannerTests` powinny przejść bez zmian — sygnatury publiczne zachowane, dodane tylko opcjonalne pole/parametr).
- Po pozytywnej weryfikacji: zmień status H1 w tabeli na `zakończony`.
