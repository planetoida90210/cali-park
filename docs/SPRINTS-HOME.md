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

---

### Sprint H2 — 2026-07-18, agent (drugi z H1–H3)

**Zrobione:** (wszystko NOWE, w `cali-park/Features/Home/Views/Components/Hero/` — synchronized group, podpina się samo do targetu; `HeroCardView` celowo nietknięty)
- `ContextualHeroView.swift` — „głupi” kontener: dostaje `HomeHeroState` + `name`, `weeklyReps`, `weeklyProgress`, `now` (wstrzykiwana data pod deterministyczne previews) + closury akcji (`onStartPlan(WorkoutPlan)`, `onQuickWorkout`, `onPlanWorkout`). Jedna wspólna rama karty (`componentBackground`, `clipShape(.rect(cornerRadius: 12))`), `switch` po case'ach → osobny widok. Zawiera komplet `#Preview` (patrz niżej).
- `HeroPlanTodayView.swift` — plan na dziś, niezrobiony: nazwa planu jako nagłówek, „Plan na dziś · N ćwiczeń”, ewentualny progres („Zaczęte dziś: …”), duże CTA **„Rozpocznij”** z pulsującą ikoną `play.fill` (PhaseAnimator, wyłączany przy Reduce Motion).
- `HeroCompletedTodayView.swift` — trening dziś zrobiony: „Zrobione na dziś” + podsumowanie sesji + `HeroStreakLabel` + drugorzędny `HeroWeeklyRingView`. Bez CTA (robota skończona).
- `HeroRestDayView.swift` — dzień przerwy: „Dziś odpoczywasz” + „Następny trening: <Jutro/Pon> · <plan>” (przez `WorkoutScheduleFormatter.dayLabel(_,asOf:)`), streak + mini-ring. Bez CTA.
- `HeroFreeModeView.swift` — wolny tryb (brak planów, jest historia): „Trenuj po swojemu” + ostatni trening + sugestia ćwiczenia; CTA **„Szybki trening”** (primary) + **„Zaplanuj trening”** (secondary), streak + mini-ring.
- `HeroFirstRunView.swift` — pierwszy start (pusto): zaproszenie + **„Zaplanuj trening”** / **„Szybki trening”**.
- `HeroHeaderView.swift` — wspólne powitanie wg pory dnia („Dzień dobry” 5–12 / „Siema” 12–18 / „Dobry wieczór” reszta) + imię; `now` wstrzykiwana.
- `HeroWeeklyRingView.swift` — drugorzędna linia: mini-ring celu tygodnia (%) + „N podciągnięć w tym tygodniu”. Ring animowany (Reduce Motion respektowany), `contentTransition(.numericText())`.
- `HeroStreakLabel.swift` — wspólna linijka streaka (płomień + dni), numericText.
- `HeroWorkoutSummary.swift` — czysty helper: `LatestWorkout` → jedna linijka (sesja: „3 ćwiczenia · 68 powtórzeń”, pojedyncze: „Podciągnięcia · 6 + 6 + 8”); nazwy z `ExerciseCatalog`, więc widoki są bezstanowe.
- `HeroButtonStyles.swift` — `HeroPrimaryButtonStyle` (accent fill) / `HeroSecondaryButtonStyle` (accent ghost) na `clipShape`/`foregroundStyle` (zero deprecated API), full-width.

**Odstępstwa od planu:** brak co do zakresu. Dołożone (poza wyliczanką plików w planie) drobne wspólne widoki/helpery, żeby uniknąć duplikacji i nie pakować wielu typów do jednego pliku: `HeroHeaderView`, `HeroWeeklyRingView`, `HeroStreakLabel`, `HeroWorkoutSummary`, `HeroButtonStyles`.

**Decyzje podjęte w trakcie:**
- Copy PL (writing-for-interfaces, nagłówek niesie sedno): planToday → „Rozpocznij”; completedToday → „Zrobione na dziś”; restDay → „Dziś odpoczywasz”; freeMode → „Trenuj po swojemu” + „Szybki trening”/„Zaplanuj trening”; firstRun → „Zacznij swoją serię”. „Rozpocznij” spójne z istniejącym `NextWorkoutModuleContent`.
- Widok „głupi”: `weeklyReps`/`weeklyProgress`/`name`/`now` podawane wprost (nie z enuma ani nie z VM) — integracja z `dashboard`/`ActiveSheet` to H3.
- Animacja przejść: identyfikator `stateID` (Int per case) + `.transition` + `.animation(value: stateID)` — zmiana *stanu* animuje się przejściem, a zmiana liczb wewnątrz tego samego case'a (np. reps) idzie przez `numericText`, nie przeładowuje karty.
- Reduce Motion: puls CTA, ring i przejścia stanów wyłączane przy `accessibilityReduceMotion`.
- `onStartPlan` bierze `WorkoutPlan` (kontener woła `onStartPlan(plan)`) — gotowe pod `sheet(item:)`/`ActiveSheet` w H3.
- Rama karty: `componentBackground` + róg 12 (spójnie z resztą modułów Home), zamiast czarnego tła starego `HeroCardView`.

**Znane problemy / TODO:**
- `HeroCardView` nadal w drzewie i używany w `HomeView` — usunięcie i podmiana to H3 (DoD H2: apka działa jak przed sprintem, widoki niezintegrowane).
- `weeklyPullUps` w VM wciąż liczone po `Calendar.current`/`.now` (uwaga z H1). Do seedowanych previews całego Home (H3) rozważ `weeklyPullUps(asOf:)`, jeśli potrzebny determinizm.
- Nazwy ćwiczeń w podsumowaniu czytane z `ExerciseCatalog` (statyczny), świadomie — bez wstrzykiwania VM do „głupiego” widoku.

**Wskazówki dla następnego agenta (H3):**
- Podmień `HeroCardView` na `ContextualHeroView` w `HomeView`; `state:` bierz z `dashboard.heroState()`, `weeklyReps: dashboard.weeklyPullUps`, `weeklyProgress:` jak dotychczasowe `weeklyProgress`, `name: userProfile.name`.
- Akcje: `onStartPlan` → sheet szybkiego treningu z planu (`makeQuickWorkoutViewModel(plan:)`), `onQuickWorkout` → `makeQuickWorkoutViewModel()`, `onPlanWorkout` → edytor planu (`makePlanEditorViewModel()`); wszystko przez jeden `ActiveSheet` + `sheet(item:)`, `onDismiss` → `dashboard.reload()`.
- Style przycisków i mini-ring są gotowe do reużycia; nie duplikuj.
- Rail: drugi przycisk na stałe wejście „Plany” (zakres H3).

**Do ręcznej weryfikacji przez użytkownika:**
- Build w Xcode. Same NOWE pliki w `Features/Home/Views/Components/Hero/` — nic istniejącego nie zmienione, więc reszta apki bez zmian.
- Xcode Previews (Canvas): `ContextualHeroView` — „Plan dziś”, „Zrobione dziś”, „Dzień przerwy”, „Wolny tryb”, „Pierwszy start”, „Galeria stanów”, „Przejścia stanów” (tapnij „Następny stan”, by zobaczyć animowane przejścia). Sprawdź też pod Reduce Motion (puls/ring/przejścia mają zniknąć) i przy dużym Dynamic Type (layout nie powinien się łamać).
- Po pozytywnej weryfikacji: zmień status H2 w tabeli na `zakończony`.
