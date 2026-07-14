# Tracker sprintów — Zakładka Ćwiczenia + dziennik

Plan źródłowy: [.cursor/plans/zakładka_ćwiczenia_+_dziennik_4ca18af5.plan.md](../.cursor/plans/zakładka_ćwiczenia_+_dziennik_4ca18af5.plan.md)

## Instrukcja dla agenta

1. Znajdź w tabeli pierwszy sprint ze statusem `oczekuje` — to twój sprint. Wykonaj TYLKO jego zakres z planu.
2. Jeśli poprzedni sprint ma status `do weryfikacji`, ZATRZYMAJ SIĘ i poproś użytkownika o weryfikację buildu w Xcode — nie zaczynaj kolejnego sprintu na niezweryfikowanym fundamencie.
3. Przed startem przeczytaj cały plan oraz WSZYSTKIE wpisy w dzienniku poniżej.
4. NIE uruchamiaj `xcodebuild` ani żadnej weryfikacji kompilacji — build i testy sprawdza użytkownik ręcznie w Xcode.
5. Po skończeniu pracy:
   - zmień status swojego sprintu w tabeli na `do weryfikacji`,
   - odhacz swoje todos w pliku planu (status `completed`),
   - dopisz wpis do dziennika wg szablonu poniżej.
6. Status `zakończony` ustawia wyłącznie użytkownik po ręcznym buildzie i testach.

## Status sprintów

| Sprint | Zakres (skrót) | Status | Data |
|---|---|---|---|
| 1 | Fundament danych: modele, ExerciseCatalog, WorkoutLogStoring + store'y, testy warstwy danych | zakończony | 2026-07-14 |
| 2 | Biblioteka ćwiczeń: ViewModel, lista + chips + szukanie, detal, ikony figure.*, DI w AppEnvironment | zakończony | 2026-07-14 |
| 3 | SetPad + dziennik: SetPadInput, SetPadSheetView, historia logów, testy sekwencji | zakończony | 2026-07-14 |
| 4 | Home + sprzątanie: Quick Log/streak/hero z realnych logów, Tab API, NavigationStack, AccentColor | zakończony | 2026-07-14 |
| 5 | „Szybki trening": sesja z dowolnych ćwiczeń (sessionID + batch append), reużywalny SetPadEntryView, ExercisePickerSheet, wejścia z Home i Ćwiczeń, grupowanie sesji w historii | zakończony | 2026-07-14 |
| 6 | Planer — fundament danych: Weekday, WorkoutSchedule (+ nextOccurrence), PlannedExercise, WorkoutPlan, WorkoutPlanStoring + store'y, workoutPlanStore w AppEnvironment, testy (bez UI) | zakończony | 2026-07-14 |
| 7 | Planer — UI: lista planów + kreator/edytor (nazwa, ćwiczenia, harmonogram), fabryki w AppEnvironment, wejście z zakładki Ćwiczenia | zakończony | 2026-07-14 |
| 8 | Planer — Home: „Nast. trening" = najbliższy zaplanowany trening + „Rozpocznij" (prefill sesji z planu) | do weryfikacji | 2026-07-14 |

Statusy: `oczekuje` → `w toku` → `do weryfikacji` → `zakończony` (ustawia użytkownik).

> Uwaga: plan pierwotnie miał 4 sprinty; Sprint 5 dodano po ich ukończeniu na prośbę użytkownika (logowanie sprawiało wrażenie „tylko podciągnięcia"). Sprinty 6–8 to mini-plan „Planer treningów / Zaplanuj trening" dodany po Sprincie 5 (na Home „Szybki trening" i „Nast. trening" prowadziły do tego samego — logowania). Definicje w pliku planu.

## Dziennik sprintów

Szablon wpisu (kopiuj i wypełnij):

```
### Sprint N — <data>, agent

**Zrobione:** (lista plików utworzonych/zmienionych, jednym zdaniem co w każdym)
**Odstępstwa od planu:** (co zrobiono inaczej niż w planie i dlaczego; „brak" jeśli nic)
**Decyzje podjęte w trakcie:** (np. wybrane symbole SF, nazwy typów, struktury katalogów)
**Znane problemy / TODO:** (co zostawiono świadomie, co wymaga uwagi)
**Wskazówki dla następnego agenta:** (na co uważać, od czego zacząć)
**Do ręcznej weryfikacji przez użytkownika:** (build, testy, konkretne ścieżki smoke testu)
```

---

### Sprint 1 — 2026-07-14, agent

**Zrobione:**
- `cali-park/Features/Exercises/Models/Exercise.swift` — model ćwiczenia (`Identifiable`, `Codable`, `Hashable` po `id`), pola wg planu w tym `symbolName` i `equipment` spójne z `Park.equipments`.
- `cali-park/Features/Exercises/Models/ExerciseCategory.swift` — enum poziomów (basic/advanced/expert) z polskim `displayName`; surowe wartości po angielsku jako stabilne klucze persystencji.
- `cali-park/Features/Exercises/Models/MuscleGroup.swift` — enum grup mięśniowych (back/chest/shoulders/arms/core/legs) z polskim `displayName`.
- `cali-park/Features/Exercises/Models/WorkoutLogEntry.swift` — wpis dziennika (`exerciseID`, `date`, `sets`, opcjonalna `note`) + pomocnicze `totalReps`.
- `cali-park/Features/Exercises/Models/LoggedSet.swift` — pojedyncza seria (`reps`, opcjonalny `weight` — UI dojdzie później).
- `cali-park/Features/Exercises/Services/ExerciseCatalog.swift` — wbudowany katalog 19 ćwiczeń po polsku (7 podstawowych, 7 zaawansowanych, 5 ekspert) ze stałymi UUID (`E0000000-…-0001` do `…-0019`), opisami i instrukcjami krok po kroku; słownikowy lookup `exercise(withID:)`.
- `cali-park/Features/Exercises/Services/WorkoutLogStore.swift` — protokół `WorkoutLogStoring` (`load()`, throwing `append(_:)` / `delete(id:)`), `FileWorkoutLogStore` (JSON w `URL.documentsDirectory`, zapis atomowy, daty ISO 8601) i `InMemoryWorkoutLogStore` do testów/preview.
- `cali-parkTests/ExercisesDataTests.swift` — testy Swift Testing: integralność katalogu (unikalne ID i nazwy, komplet kategorii, testy parametryzowane per ćwiczenie, prefiks `figure.`, roundtrip JSON) + `FileWorkoutLogStore` (pusty load, append/load/delete, delete nieznanego ID, persystencja między instancjami).

**Odstępstwa od planu:** brak. Jedno doprecyzowanie: `append(_:)` i `delete(id:)` są `throws` (plan nie precyzował) — Sprint 3 potrzebuje błędów zapisu do alertu w `WorkoutLogViewModel`, a stub rzucający będzie trywialny.

**Decyzje podjęte w trakcie:**
- Kategoria jako osobny plik `ExerciseCategory.swift` (zasada „jeden typ = jeden plik").
- Enumy z angielskimi raw values (klucze JSON) + polskie `displayName` — bezpieczne przy przyszłej lokalizacji.
- Mapowanie symboli: podciągnięcia/łucznicze/flaga → `figure.climbing`; dipy (klasyczne i na kółkach) → `figure.strengthtraining.traditional`; pompki/przysiady/wykroki/pistolety → `figure.strengthtraining.functional`; deska/wznosy nóg/L-sit → `figure.core.training`; HSPU/muscle-up/front lever/planche/back lever → `figure.gymnastics`; mostek → `figure.flexibility`; australijskie → `figure.play`.
- Daty w JSON jako ISO 8601 (czytelny plik, stabilny format). Uwaga: ISO 8601 ucina ułamki sekund — porównania dat w testach używają pełnych sekund.
- `FileWorkoutLogStore.init` przyjmuje `directory:` (domyślnie `.documentsDirectory`) — testy używają katalogu tymczasowego bez dotykania prawdziwych danych.

**Znane problemy / TODO:**
- `weight` i `note` są w modelu, ale bez UI (świadome cięcie z planu, Sprint 3).
- Katalog: NIGDY nie zmieniać ani nie reużywać istniejących UUID — tylko dopisywać nowe (logi trzymają `exerciseID`).

**Wskazówki dla następnego agenta (Sprint 2):**
- `ExerciseCatalog.all` to źródło listy dla `ExerciseLibraryViewModel`; filtry po `category` i `muscleGroups`, szukanie po `name` (wzorzec: `ParksViewModel.displayedParks`).
- Chips kategorii: `ExerciseCategory.allCases` + `displayName`.
- W `AppEnvironment` dodaj `let workoutLogStore: WorkoutLogStoring = FileWorkoutLogStore()` + fabrykę `makeExerciseLibraryViewModel()`.
- Nowe pliki leżą w katalogach zsynchronizowanych z targetem (projekt używa `fileSystemSynchronizedGroups`) — nie trzeba nic dodawać w Xcode. Pliki testów w `cali-parkTests/` analogicznie.
- ZANIM zaczniesz: sprawdź, czy Sprint 1 ma status `zakończony` (użytkownik weryfikuje build).

**Do ręcznej weryfikacji przez użytkownika:**
- Build projektu w Xcode (nowe pliki: 5 modeli/serwisów + 1 plik testów — powinny podpiąć się same przez synchronized groups).
- Uruchomienie testów: `ExerciseCatalogTests` i `FileWorkoutLogStoreTests` (plus istniejące — nic w starym kodzie nie zmieniano).
- Po pozytywnej weryfikacji: zmień status Sprintu 1 w tabeli na `zakończony`.

---

### Sprint 2 — 2026-07-14, agent

**Zrobione:**
- `cali-park/Features/Exercises/ViewModels/ExerciseLibraryViewModel.swift` — `@Observable @MainActor` ViewModel: filtr kategorii (`selectedCategory: ExerciseCategory?`, `nil` = wszystkie), szukanie po nazwie i `displayedExercises` jako computed property; katalog wstrzykiwany w init (testy dostają mały fixture zamiast produkcyjnego katalogu).
- `cali-park/Features/Exercises/Views/Components/ExerciseIconView.swift` — ikona w stylu Apple Watch Workout: czarny glif `figure.*` na kole `Color.accent`; dwa stałe rozmiary (`.row` 44 pt, `.detail` 80 pt), ukryta dla VoiceOver (dekoracja).
- `cali-park/Features/Exercises/Views/ExerciseLibraryView.swift` — pełna przebudowa placeholdera: pole szukania (z przyciskiem czyszczenia), poziome chips kategorii („Wszystkie" + 3 poziomy) jako prawdziwe `Button` z traitem `.isSelected`, lista `NavigationLink(value:)` + `navigationDestination(for: Exercise.self)`, pusty stan „Brak wyników". Podwidoki jako osobne prywatne struktury (nie computed properties — wydajność z `@Observable`).
- `cali-park/Features/Exercises/Views/ExerciseDetailView.swift` — detal: duża ikona, kategoria, opis, chipsy grup mięśniowych, sprzęt (tylko gdy niepusty), instrukcje krok po kroku jako karta z numeracją i `Divider()`. BEZ przycisku „Dodaj serię" (Sprint 3).
- `cali-park/Core/AppEnvironment.swift` — dodane `workoutLogStore: WorkoutLogStoring` (domyślnie `FileWorkoutLogStore()`) + fabryka `makeExerciseLibraryViewModel()`.
- `cali-park/Features/Main/MainTabView.swift` — `ExerciseLibraryView(environment: environment)` (DI jak w Parks).
- `cali-parkTests/ExerciseLibraryViewModelTests.swift` — testy parametryzowane (`@Test(arguments:)`): filtr per kategoria, szukanie (case-insensitive, diacritic-insensitive — „podciagniecia" znajduje „Podciągnięcia", trim spacji, brak wyników), kombinacja filtr+szukanie, default = pełny katalog.

**Odstępstwa od planu:** brak. Doprecyzowania: (1) chips mają dodatkowo opcję „Wszystkie" (`selectedCategory = nil`) — bez niej nie dałoby się wrócić do pełnej listy; (2) szukanie przez `localizedStandardContains` — ignoruje wielkość liter i polskie znaki; (3) `ExerciseLibraryViewModel` trzyma NavigationStack wewnątrz siebie (zakładka), a nie w MainTabView — spójnie z dotychczasowym układem.

**Decyzje podjęte w trakcie:**
- `ExerciseIconView` jako współdzielony komponent w `Views/Components/` — Sprint 3 użyje go w historii logów (rozmiar `.row`).
- Ikona ma `accessibilityHidden(true)` — nazwa ćwiczenia obok wystarcza VoiceOver.
- Rozmiary ikon: 44 pt lista / 80 pt detal (siatka 4/8), jeden `lineWidth` nie dotyczy (fill, nie stroke).
- Tytuł zakładki skrócony z „Biblioteka ćwiczeń" na „Ćwiczenia" (spójny z nazwą taba, krótsza kopia).
- ViewModel w widoku przez `@State` (wzorzec dla `@Observable`; `@StateObject` jest dla `ObservableObject` — ParksView zostaje po staremu, nie ruszane).
- `workoutLogStore` jest już w AppEnvironment, ale nikt z niego jeszcze nie czyta — Sprint 3 podłączy go do `WorkoutLogViewModel`.

**Znane problemy / TODO:**
- `MainTabView` nadal na starym `tabItem` (celowo — migracja na Tab API to zakres Sprintu 4).
- `ExerciseDetailView` nie ma przycisku „Dodaj serię" — wchodzi w Sprincie 3.
- Chips grup mięśniowych w detalu nie zawijają się (max 3 grupy — mieszczą się w jednej linii; gdyby katalog dostał ćwiczenie z 4+, rozważyć zawijanie).

**Wskazówki dla następnego agenta (Sprint 3):**
- Wejście SetPada: dodaj przycisk „Dodaj serię" w `ExerciseDetailView` + `sheet(item:)` z payloadem `Exercise` (NIE `Bool` + osobny stan).
- `WorkoutLogViewModel` bierze `WorkoutLogStoring` z `AppEnvironment.workoutLogStore` — dodaj fabrykę `makeWorkoutLogViewModel(...)` w AppEnvironment.
- W historii logów użyj `ExerciseIconView(symbolName:size: .row)` + `ExerciseCatalog.exercise(withID:)` do rozwiązania nazwy/ikony wpisu.
- Wzorzec alertu błędów: `ParkPhotosViewModel`; stub rzucający: patrz `FailingReviewsService` w testach.
- ZANIM zaczniesz: sprawdź, czy Sprint 2 ma status `zakończony` (użytkownik weryfikuje build).

**Do ręcznej weryfikacji przez użytkownika:**
- Build w Xcode (4 nowe pliki: ViewModel, ExerciseIconView, ExerciseDetailView, testy — synchronized groups podpinają same; ExerciseLibraryView/AppEnvironment/MainTabView zmienione).
- Testy: `ExerciseLibraryViewModelTests` (+ istniejące bez zmian).
- Smoke test: zakładka Ćwiczenia → lista 19 ćwiczeń → chip „Ekspert" filtruje do 5 → szukanie „podciag" znajduje 2 → tap w ćwiczenie otwiera detal z ikoną, opisem, grupami i instrukcjami → powrót działa.
- Po pozytywnej weryfikacji: zmień status Sprintu 2 w tabeli na `zakończony`.

---

### Sprint 3 — 2026-07-14, agent (wpis zrekonstruowany przez agenta Sprintu 4)

Agent Sprintu 3 nie zostawił wpisu w dzienniku — poniżej rekonstrukcja z commita `4499f33` i stanu kodu. Użytkownik potwierdził, że build Sprintu 3 przeszedł bez błędów, więc status zmieniony na „zakończony".

**Zrobione:**
- `cali-park/Features/Exercises/Models/SetPadInput.swift` — czysta logika licznika serii (cyfry, `+` zatwierdza, `⌫` kasuje cyfrę / cofa serię, `C` czyści, limit 3 cyfr, blokada zera wiodącego); niezapisany wpis liczy się przy zapisie (`setsForSaving`).
- `cali-park/Features/Exercises/ViewModels/WorkoutLogViewModel.swift` — `@Observable @MainActor`; zapis przez `WorkoutLogStoring`, błąd → `errorMessage` (alert), sukces → `didSave` (sheet sam się zamyka).
- `cali-park/Features/Exercises/ViewModels/WorkoutHistoryViewModel.swift` — lista wpisów (najnowsze pierwsze), delete z obsługą błędu, `exercise(for:)` przez katalog.
- `cali-park/Features/Exercises/Views/SetPadSheetView.swift` — SetPad w stylu kalkulatora (Grid 4×3, akcent tylko na `+` i „Zapisz"), medium detent, `sensoryFeedback` na `+`, jednorazowa podpowiedź „Każdy + to nowa seria" (`@AppStorage`), etykiety dostępności.
- `cali-park/Features/Exercises/Views/WorkoutHistoryView.swift` — „Ostatnie treningi": lista z ikoną/nazwą/seriami/datą, swipe-to-delete, stan pusty.
- `cali-park/Features/Exercises/Views/ExerciseDetailView.swift` — przycisk „Dodaj serię" (safeAreaInset) + `sheet(item:)` z payloadem ćwiczenia.
- `cali-park/Features/Exercises/Views/ExerciseLibraryView.swift` — wejście do historii z toolbara (ikona zegara) przez `navigationDestination`.
- `cali-park/Core/Extensions/PolishPlural.swift` — odmiana „seria/serie/serii", „powtórzenie/powtórzenia/powtórzeń" (z wyjątkiem nastek).
- `cali-park/Core/AppEnvironment.swift` — fabryki `makeWorkoutLogViewModel(exercise:)` i `makeWorkoutHistoryViewModel()`.
- `cali-parkTests/SetPadTests.swift` — parametryzowane sekwencje klawiszy, testy VM (w tym `FailingWorkoutLogStore`), testy odmiany.

**Do ręcznej weryfikacji przez użytkownika:** zweryfikowane — build przeszedł (potwierdzone w rozmowie), status „zakończony".

---

### Sprint 4 — 2026-07-14, agent

Uwaga wstępna: Sprint 3 miał status „do weryfikacji", ale użytkownik potwierdził, że build przeszedł bez błędów — dlatego oznaczyłem Sprint 3 jako „zakończony" i wykonałem Sprint 4.

**Zrobione:**
- `cali-park/Features/Home/Models/WorkoutStreak.swift` (NOWY) — czysta, testowalna logika streaka: `current` (trening wczoraj utrzymuje streak przy braku dzisiejszego), `longest` (najdłuższa seria w historii), `trainedDays` (dni znormalizowane do początku dnia — dla kalendarza). Wstrzykiwany `Calendar` i `today` dla deterministycznych testów.
- `cali-park/Features/Home/ViewModels/HomeDashboardViewModel.swift` (NOWY) — `@Observable @MainActor` VM zasilający moduły Home z tego samego `WorkoutLogStoring`, do którego pisze zakładka Ćwiczenia: `latestEntry`, `quickLogExercise` (ostatnio logowane, fallback: podciągnięcia), `streak`, `weeklyPullUps` (podciągnięcia w bieżącym tygodniu kalendarzowym), `suggestedExercise` (heurystyka: najdawniej nietrenowana grupa mięśniowa → podstawowe ćwiczenie na tę grupę; `nil` przy pustym dzienniku), fabryka `makeWorkoutLogViewModel(exercise:)` dla SetPada z Home.
- `cali-park/Core/AppEnvironment.swift` — dodana fabryka `makeHomeDashboardViewModel()`.
- `cali-park/Core/Extensions/PolishPlural.swift` — dodane odmiany `days` („1 dzień / 2 dni / 5 dni") i `pullUps` („1 podciągnięcie / 2 podciągnięcia / 5 podciągnięć").
- `cali-park/Features/Main/MainTabView.swift` — migracja `tabItem` → nowe **Tab API** (`Tab(_:systemImage:value:)`); `HomeView` dostaje `environment` (DI).
- `cali-park/Features/Home/Views/HomeView.swift` — `NavigationView` → `NavigationStack`; DI przez `init(environment:)` + `@State` dashboard; hero z realnych danych (`weeklyPullUps`, progress = logi/`weeklyGoal` z mocka); usunięte martwe `dailyChallenge`; `DispatchQueue.main.asyncAfter` → `Task` + `Task.sleep(for:)`; `presentationMode` → `dismiss` w `ModuleSelectionView`; toggle modułów przez natywny `Toggle` z etykietą (koniec `labelsHidden`); `reload()` w `onAppear` (wpisy z zakładki Ćwiczenia widoczne po przełączeniu taba); deprecated modifiery wyczyszczone (`foregroundColor`/`cornerRadius`/`edgesIgnoringSafeArea`).
- `cali-park/Components/ModuleView.swift` — przyjmuje `dashboard: HomeDashboardViewModel` i przekazuje go do QuickLog/NextWorkout/Streak; deprecated modifiery wyczyszczone; etykieta dostępności na przycisku usuwania modułu.
- `cali-park/Features/Home/Views/Components/QuickLogModuleContent.swift` — przebudowa: przycisk „Dodaj serię — {ćwiczenie}" otwiera `SetPadSheetView` (`sheet(item:)` z payloadem, `onDismiss` → reload); „Ostatni zapis" z realnego dziennika („Podciągnięcia · 6 + 6 + 8" + data); uczciwy stan pusty.
- `cali-park/Features/Home/Views/Components/StreakModuleContent.swift` — przebudowa: streak i rekord z `WorkoutStreak`; kalendarz bieżącego miesiąca z realnymi dniami treningowymi (koniec hardkodu „Lipiec 2023" — tytuł przez `Text(.now, format:)`); dzisiejszy dzień z obwódką; stan pusty przy braku wpisów.
- `cali-park/Features/Home/Views/Components/NextWorkoutModuleContent.swift` — przebudowa: propozycja z heurystyki (ikona + nazwa + „Najdłużej nietrenowane: …"), przycisk „Zaloguj serię" otwiera SetPad; stan pusty przy pustym dzienniku (koniec fikcyjnego „Trening Push, Dziś 19:00").
- `cali-park/Features/Home/Views/Components/HeroCardView.swift` — realne tygodniowe podciągnięcia z poprawną odmianą, procent przez `Text(_, format: .percent)` (bez C-style), `contentTransition(.numericText())`, deprecated modifiery wyczyszczone.
- `cali-park/Resources/Assets.xcassets/AccentColor.colorset/Contents.json` — wypełniony #D1FF00 (sRGB 0xD1/0xFF/0x00).
- `cali-park/Core/Theme/AppTheme.swift` — usunięta ręczna deklaracja `Color.accent` (po wypełnieniu colorseta Xcode generuje własny symbol `Color.accent` z assetu i build padał na „Invalid redeclaration of 'accent'"); kolor jest ten sam (#D1FF00), źródłem prawdy jest teraz colorset, komentarz w pliku ostrzega przed ponownym dodaniem.
- `cali-parkTests/WorkoutStreakTests.swift` (NOWY) — testy parametryzowane streaka (dziś / wczoraj / przerwa / luka w środku / pusty dziennik / dwa wpisy jednego dnia) na stałym zegarze i kalendarzu UTC + normalizacja `trainedDays` + odmiany `days`/`pullUps`.

**Odstępstwa od planu:** brak. Doprecyzowania: (1) przycisk w NextWorkout otwiera SetPad dla proponowanego ćwiczenia (realna akcja zamiast martwego „Rozpocznij teraz"); (2) `weeklyGoal` (75) i imię zostają z mocka — zgodnie z planem czekają na sprint Profil; (3) „✓ Gotowe" w toolbarze skrócone do „Gotowe", a „Zapisz" w selektorze modułów zmienione na „Gotowe" (nic nie zapisywał — przełączniki działają natychmiast).

**Decyzje podjęte w trakcie:**
- Streak liczony na `Calendar.current` w VM; w testach wstrzykiwany kalendarz UTC + stałe „dziś" — testy nie zależą od momentu uruchomienia.
- `HomeDashboardViewModel` ma własną fabrykę `makeWorkoutLogViewModel` (ma już store), żeby moduły nie potrzebowały całego `AppEnvironment`.
- Moduły Quick Log i NextWorkout mają własne `sheet(item:)` + `onDismiss: reload` — wpis zalogowany z Home od razu odświeża streak/hero/ostatni zapis.
- Heurystyka „następne ćwiczenie": grupy sortowane po dacie ostatniego treningu (nigdy nietrenowane wygrywają), preferowane ćwiczenie podstawowe z tą grupą jako pierwszą; przy pustym dzienniku uczciwy stan pusty zamiast zmyślonej propozycji.
- `ParksModuleContent`, `Leaderboard`, `Feed`, `Achievements` NIE ruszane (zostają na mockach — poza zakresem), mimo że mają deprecated modifiery; `PrimaryActionRailView` też nietknięty (martwe przyciski to temat na później, nie ten sprint).

**Znane problemy / TODO:**
- `MockDailyChallenge`/`dailyChallenge` w `MockData.swift` są teraz całkiem nieużywane — do usunięcia przy sprzątaniu MockData (plik poza zakresem sprintu).
- `PrimaryActionRailView` ma trzy przyciski bez akcji (haptic i nic więcej) — kandydat do podpięcia pod SetPad/planner w przyszłym sprincie.
- Kalendarz streaka pokazuje dni 1–N bieżącego miesiąca bez wyrównania do dni tygodnia (tak jak poprzedni mock) — świadome uproszczenie.
- `ModulePreferences` zostaje na `ObservableObject` (poza zakresem — zgodnie z planem).

**Wskazówki dla następnego agenta:**
- Plan 4-sprintowy jest UKOŃCZONY. Następne duże tematy wg planu: zakładka Profil (onboarding + statystyki z logów — `HomeDashboardViewModel.weeklyPullUps` i `WorkoutStreak` gotowe do reużycia), backend (`WorkoutLogStoring` gotowy do podmiany), HealthKit/Watch (patrz niżej).
- Użytkownik planuje HealthKit + Apple Watch: architektura jest na to gotowa — logowanie przechodzi przez protokół `WorkoutLogStoring`, więc zapis sesji do HealthKit można dodać jako dekorator/drugi store bez ruszania UI. Apple Fitness liczy czas/kalorie (HKWorkout), a nasze powtórzenia mogą iść równolegle do własnego store — to standardowy układ. Uwaga App Store: HealthKit wymaga `NSHealthShareUsageDescription`/`NSHealthUpdateUsageDescription` w Info.plist + capability w Xcode — NIE dodane (nie było w zakresie tego sprintu; dodać dopiero razem z realnym kodem HealthKit, bo Review odrzuca uprawnienia bez użycia).
- Nowe pliki (`WorkoutStreak`, `HomeDashboardViewModel`, `WorkoutStreakTests`) leżą w katalogach synchronized groups — podpinają się same.

**Do ręcznej weryfikacji przez użytkownika:**
- Build w Xcode (3 nowe pliki + 8 zmienionych).
- Testy: `WorkoutStreakTests`, `PolishPluralHomeTests` (+ wszystkie poprzednie — bez zmian w starych testach).
- Smoke test: zaloguj serię w zakładce Ćwiczenia → przełącz na Home → hero pokazuje podciągnięcia z tego tygodnia → rozwiń moduł Quick Log: widać ostatni zapis, „Dodaj serię" otwiera SetPad i po zapisie moduł się odświeża → moduł Streak pokazuje „1 dzień" i zaznaczony dzisiejszy dzień w kalendarzu → moduł „Następny trening" proponuje ćwiczenie z najdawniej nietrenowanej grupy.
- Tint/AccentColor: sprawdź, czy wypełnienie AccentColor (#D1FF00) niczego nie przebarwiło nieoczekiwanie (wcześniej colorset był pusty).
- Po pozytywnej weryfikacji: zmień status Sprintu 4 w tabeli na `zakończony`.

---

### Sprint 5 — 2026-07-14, agent (piąty)

Uwaga wstępna: plan 4-sprintowy był ukończony. Użytkownik potwierdził, że build Sprintu 4 przeszedł bez błędów — oznaczyłem Sprint 4 jako `zakończony`. Sprint 5 to nowy zakres dodany na prośbę użytkownika: logowanie sprawiało wrażenie „tylko podciągnięcia", brakowało szybkiego zalogowania całego treningu z dowolnych ćwiczeń. Kształt („pełna sesja") wybrany przez użytkownika.

**Zrobione:**
- `cali-park/Features/Exercises/Models/WorkoutLogEntry.swift` — dodany opcjonalny `sessionID: UUID?` (grupuje ćwiczenia jednej sesji). Wstecznie zgodny: syntetyzowany Codable używa `decodeIfPresent` dla opcjonali, więc stare logi (bez klucza) dekodują się z `nil`.
- `cali-park/Features/Exercises/Services/WorkoutLogStore.swift` — nowa metoda protokołu `append(contentsOf:)` z domyślną implementacją w extension (pętla, dla `InMemory`/stubów) oraz atomowym override w `FileWorkoutLogStore` (jeden zapis pliku = sesja all-or-nothing).
- `cali-park/Features/Exercises/Views/Components/SetPadEntryView.swift` (NOWY) — wydzielony reużywalny keypad (nagłówek + wyświetlacz `6 + 6 + 8` + klawiatura + przycisk zapisu), sterowany `Binding<SetPadInput>` + `onSave`. Zawiera haptic i logikę jednorazowej podpowiedzi. `SetPadHeader` internal (współdzielony), reszta podwidoków private.
- `cali-park/Features/Exercises/Views/SetPadSheetView.swift` — odchudzony: korzysta z `SetPadEntryView`, zachowuje dotychczasowe zachowanie (persystencja przez `WorkoutLogViewModel` + alert błędu + auto-dismiss po zapisie). Przeniesione `SetPadDisplay/Keypad/Key/Header` do `SetPadEntryView.swift`.
- `cali-park/Features/Exercises/ViewModels/QuickWorkoutViewModel.swift` (NOWY) — `@Observable @MainActor`; `DraftItem` (ćwiczenie + serie), `addExercise` (ignoruje puste), `remove`, `finish()` zapisuje wszystkie pozycje jako jedną sesję (wspólny `sessionID` + jeden `Date.now`) przez `append(contentsOf:)`; błąd → `errorMessage`, sukces → `didFinish`.
- `cali-park/Features/Exercises/Views/ExercisePickerSheet.swift` (NOWY) — szybki wybór dowolnego ćwiczenia; reużywa `ExerciseLibraryViewModel` (szukanie + chips), wiersze to przyciski wołające `onPick`. „Anuluj" w toolbarze.
- `cali-park/Features/Exercises/Views/QuickWorkoutView.swift` (NOWY) — ekran „Szybki trening": lista dodanych ćwiczeń (swipe-to-delete, stopka z podsumowaniem), stan pusty, dolny „Dodaj ćwiczenie", toolbar „Anuluj"/„Zakończ" (disabled gdy pusto). Łańcuch pod-sheetów przez jeden enum `ActiveSheet` (`.picker`/`.setPad(Exercise)`) — nigdy dwa sheety naraz. `SessionSetPadSheet` (private) używa `SetPadEntryView` bez persystencji (oddaje serie do VM).
- `cali-park/Features/Exercises/Views/WorkoutHistoryView.swift` + `.../ViewModels/WorkoutHistoryViewModel.swift` — historia grupuje wpisy po `sessionID` (`WorkoutHistorySection`): sesja (2+ wpisy) = jedna sekcja z nagłówkiem (data + „N ćwiczeń · M powtórzeń"); pojedyncze wpisy (nil) = osobne wiersze; kolejność malejąco po dacie. Wiersz sesji ukrywa datę (jest w nagłówku).
- `cali-park/Features/Exercises/Views/ExerciseLibraryView.swift` — dolny akcentowy przycisk „Szybki trening" (`safeAreaInset`) + prezentacja `QuickWorkoutView`.
- `cali-park/Features/Home/Views/Components/PrimaryActionRailView.swift` — **ożywiony martwy pasek akcji** (użytkownik wskazał, że o TEN „Quick Log" chodziło): scalone „Start treningu" + „Quick Log" w jeden akcentowy przycisk **„Szybki trening"** (otwiera sesję) + „Nast. trening" (proponowane ćwiczenie z `suggestedExercise` → SetPad; przy pustym dzienniku otwiera Szybki trening). Pasek dostaje `dashboard: HomeDashboardViewModel`, sam prezentuje sheety i woła `reload`. Przy okazji usunięte deprecated modyfikatory (`foregroundColor`/`cornerRadius`/`.font(.system(size:))`/`minimumScaleFactor`).
- `cali-park/Features/Home/Views/HomeView.swift` — `PrimaryActionRailView(dashboard: dashboard)`.
- **Usunięcie redundancji przycisku „Szybki trening" (akcja tylko w pasku):**
  - `cali-park/Features/Home/Views/Components/QuickLogModuleContent.swift` USUNIĘTY, zastąpiony `LastWorkoutModuleContent.swift` — moduł jest teraz **read-only podglądem „Ostatni trening"** (bez własnego przycisku). Świadomy sesji: dla sesji pokazuje „N ćwiczeń · M powtórzeń" + listę nazw ćwiczeń; dla pojedynczego wpisu „{nazwa} · 6 + 6 + 8"; + data; stan pusty.
  - `cali-park/Features/Home/ViewModels/HomeDashboardViewModel.swift` — dodane `LatestWorkout` + `latestWorkout` (zwija ostatnią sesję po `sessionID`, albo pojedynczy wpis).
  - `cali-park/Models/ModuleDefinition.swift` — moduł `id: "log"` przemianowany „Quick Log" → **„Ostatni trening"** (ikona `clock.arrow.circlepath`, opis „Twój ostatni zapisany trening"). `id` bez zmian → `enabledModules` w UserDefaults bez migracji.
  - `cali-park/Components/ModuleView.swift` — `case "log"` → `LastWorkoutModuleContent`.
  - `HomeDashboardViewModel.quickLogExercise` nie jest już używane w UI (zostaje jako pomocnicze — bez ostrzeżeń).

  Efekt: „Szybki trening" jest teraz w JEDNYM miejscu (pasek akcji); moduł niżej to tylko glanceable podgląd ostatniego treningu.
- `cali-park/Core/AppEnvironment.swift` + `cali-park/Features/Home/ViewModels/HomeDashboardViewModel.swift` — fabryki `makeQuickWorkoutViewModel()`.
- `cali-park/Core/Extensions/PolishPlural.swift` — dodana odmiana `exercises` („1 ćwiczenie / 2 ćwiczenia / 5 ćwiczeń").
- `cali-parkTests/QuickWorkoutTests.swift` (NOWY) — Codable roundtrip + wsteczna zgodność (legacy JSON bez `sessionID` → nil), `QuickWorkoutViewModel` (akumulacja, pusty no-op, `finish` = jeden sessionID + jeden timestamp, błąd przez `FailingWorkoutLogStore`), batch append (InMemory + `FileWorkoutLogStore` na temp dir), grupowanie historii (sesja zwija się, pojedyncze zostają osobno nawet tego samego dnia, sortowanie).

**Odstępstwa od planu:** brak (Sprint 5 nie był w pierwotnym planie). Doprecyzowania kształtu: (1) sesja akumuluje w pamięci i zapisuje na końcu (all-or-nothing) zamiast persystować każde ćwiczenie od razu — brak wpisów-sierot przy porzuceniu sesji; (2) łańcuch picker→SetPad przez jeden enum-binding zamiast dwóch osobnych `sheet` (unika kolizji dwóch sheetów); (3) w module Quick Log zostawiłem „Dodaj serię — {ostatnie}" jako szybkie powtórzenie obok „Szybki trening" — nie tracimy jednym tapem powtórki.

**Decyzje podjęte w trakcie:**
- `append(contentsOf:)` jako wymóg protokołu + default w extension → `FileWorkoutLogStore` daje atomowy override widoczny przez referencję protokołu (dynamic dispatch), a `InMemory` i stub testowy nie wymagają zmian.
- `SetPadEntryView` jako jedno źródło UI keypada dla obu ścieżek — pojedyncze ćwiczenie (VM persystuje) i sesja (akumulacja). `onSave` jako domknięcie: parent decyduje co zrobić z seriami.
- Sesja z jednym ćwiczeniem renderuje się w historii jak zwykły wiersz (kryterium karty sesji: `entries.count > 1`) — mniej zaskoczeń wizualnych.
- Grupowanie tylko po niepustym `sessionID`; dwa pojedyncze logi tego samego dnia (nil) NIE łączą się.

**Znane problemy / TODO:**
- Sesja nie ma pola ciężaru/notatki ani czasu trwania (świadome cięcie — spójne z SetPadem; model `LoggedSet.weight`/`WorkoutLogEntry.note` gotowe).
- Edycja pozycji w trakcie sesji: można usunąć (swipe) i dodać ponownie; brak edycji serii już dodanej pozycji (kandydat na później).
- Brak nazwy/typu treningu (np. „Push/Pull") — sesja to na razie po prostu zbiór ćwiczeń z jednym znacznikiem czasu.
- HealthKit/Watch nadal nietknięte (jak w notatce Sprintu 4) — `append(contentsOf:)` i `sessionID` ułatwią późniejsze mapowanie sesji na `HKWorkout`.

**Wskazówki dla następnego agenta:**
- Nowe pliki leżą w katalogach synchronized groups — podpinają się same (4 nowe pliki app + 1 plik testów).
- Punkt zapisu sesji do HealthKit: `QuickWorkoutViewModel.finish()` — tam powstaje komplet wpisów z jednym `sessionID`; naturalne miejsce na równoległy zapis `HKWorkout` (dekorator na `WorkoutLogStoring` lub drugi store).
- Jeśli dojdzie nazwa/typ treningu: dodać pole do `WorkoutLogEntry` (opcjonalne, wstecznie zgodne) i nagłówek sesji w historii.
- ZANIM zaczniesz kolejny duży temat (Profil / HealthKit / backend): sprawdź, czy Sprint 5 ma status `zakończony` (użytkownik weryfikuje build).

**Do ręcznej weryfikacji przez użytkownika:**
- Build w Xcode (4 nowe pliki app: `SetPadEntryView`, `QuickWorkoutViewModel`, `ExercisePickerSheet`, `QuickWorkoutView` + 1 plik testów `QuickWorkoutTests`; zmienione: `WorkoutLogEntry`, `WorkoutLogStore`, `SetPadSheetView`, `WorkoutHistoryView(Model)`, `ExerciseLibraryView`, `QuickLogModuleContent`, `AppEnvironment`, `HomeDashboardViewModel`, `PolishPlural`).
- Testy: `QuickWorkoutTests` (+ wszystkie poprzednie — stare testy bez zmian; `SetPadTests`/`WorkoutHistoryViewModelTests` powinny nadal przechodzić mimo refaktoru).
- Smoke test A (zakładka Ćwiczenia): dolny „Szybki trening" → „Dodaj ćwiczenie" → wybierz Podciągnięcia → `6 + 6 + 8` → „Dodaj do treningu" → wróć do listy sesji → „Dodaj ćwiczenie" → Pompki → `10 + 10` → „Zakończ" → otwórz historię (zegar) → jedna karta sesji z 2 ćwiczeniami i podsumowaniem.
- Smoke test B (Home): górny pasek → „Szybki trening" otwiera sesję; „Nast. trening" otwiera SetPad proponowanego ćwiczenia. Po zapisie/„Zakończ" Home się odświeża (hero, streak). Moduł „Ostatni trening" (ikona zegara, read-only) pokazuje ostatnią sesję jako „N ćwiczeń · M powtórzeń" + nazwy ćwiczeń, a pojedynczy log jako „{nazwa} · serie".
- Smoke test C (regres pojedynczego logowania): detal ćwiczenia → „Dodaj serię" → zapis → wpis w historii jako pojedynczy wiersz (nie karta sesji).
- Po pozytywnej weryfikacji: zmień status Sprintu 5 w tabeli na `zakończony`.

---

### Sprint 6 — 2026-07-14, agent (szósty)

Uwaga wstępna: plan 5-sprintowy był ukończony. Użytkownik potwierdził, że build Sprintu 5 przeszedł bez błędów — oznaczyłem Sprint 5 jako `zakończony`. Sprint 6 rozpoczyna nowy mini-plan „Planer treningów / Zaplanuj trening" (Sprinty 6–8), dodany na prośbę użytkownika: na Home „Szybki trening" i „Nast. trening" prowadziły do tego samego (logowania) — brakowało zaplanowanego, powtarzalnego treningu (np. „co tydzień w poniedziałek"). Sprint 6 to sam fundament danych (bez UI) — analogicznie do Sprintu 1.

**Zrobione:**
- `cali-park/Features/Planner/Models/Weekday.swift` (NOWY) — enum `Int` z rawValue = `Calendar` `.weekday` (niedziela = 1 … sobota = 7), polskie `displayName`/`shortName`, `ordered(for:)` (kolejność dni wg `firstWeekday` locale — dla pickera w S7).
- `cali-park/Features/Planner/Models/WorkoutSchedule.swift` (NOWY) — enum `Codable`: `once(Date?)`, `weekly(Set<Weekday>)`, `everyNDays(Int, from: Date)`; czysta `nextOccurrence(onOrAfter:calendar:)` (granulacja dzienna przez `startOfDay`, ignoruje porę dnia), `isRecurring`.
- `cali-park/Features/Planner/Models/PlannedExercise.swift` (NOWY) — `id`, `exerciseID` (z `ExerciseCatalog`), opcjonalne `targetSets`/`targetReps`.
- `cali-park/Features/Planner/Models/WorkoutPlan.swift` (NOWY) — `id`, `name`, `exercises`, `schedule`, `isActive`, `createdAt`; `nextOccurrence(...)` respektuje `isActive`; `exerciseCount`, `totalTargetSets`; `hash` po `id`.
- `cali-park/Features/Planner/Services/WorkoutPlanStore.swift` (NOWY) — `WorkoutPlanStoring` (`load` / `save` = upsert po `id` / `delete(id:)`) + `FileWorkoutPlanStore` (`workout-plans.json` w `URL.documentsDirectory`, zapis atomowy, ISO 8601) + `InMemoryWorkoutPlanStore`.
- `cali-park/Core/AppEnvironment.swift` — dodane `workoutPlanStore: WorkoutPlanStoring` (domyślnie `FileWorkoutPlanStore()`). BEZ fabryk VM (typy VM powstają w S7 — inaczej nie skompiluje).
- `cali-parkTests/WorkoutPlanTests.swift` (NOWY) — Swift Testing: `Weekday.rawValue` vs `Calendar` (parametryzowane) + `ordered`; `WorkoutSchedule.nextOccurrence` (weekly/everyNDays/once — parametryzowane, deterministyczny kalendarz UTC, kotwica na epoce = czwartek); `isRecurring`; `WorkoutPlan` (isActive gate, `totalTargetSets`); Codable roundtrip per wariant harmonogramu; store (InMemory upsert/delete, FileStore temp-dir między instancjami, pusty load).

**Odstępstwa od planu:** brak (Sprint 6 nie był w pierwotnym 5-sprintowym planie; definicja mini-planu Planera dopisana w pliku planu w tej samej sesji).

**Decyzje podjęte w trakcie:**
- `Weekday.rawValue` celowo = indeks `Calendar` (nie 0-based, nie angielskie stringi) — dzięki temu `Weekday(rawValue: calendar.component(.weekday, from:))` mapuje datę wprost na dzień, bez tabel przeliczeń. Polskie nazwy w `displayName` (jak `MuscleGroup`).
- `WorkoutSchedule` jako enum (nie struct z polami) — trzy warianty pokrywają „co tydzień w wybrane dni", „co N dni", „jednorazowo/szkic". Pora dnia i powiadomienia świadomie pominięte (osobny temat, wymaga uprawnień — patrz notatki S4/S5); granulacja dzienna wystarcza do „co tydzień w poniedziałek".
- `nextOccurrence(onOrAfter:)` liczy DZIEŃ WŁĄCZNIE (jeśli dziś pasuje — zwraca dziś). S8 zdecyduje, czy na Home pokazać „dziś" czy „następny".
- `everyNDays` niesie kotwicę (`from: Date`) w samym wariancie — harmonogram jest samowystarczalny (nie potrzebuje `createdAt` planu do policzenia wystąpienia).
- `save` = upsert po `id` (jeden protokół na tworzenie i edycję) — spójne z tym, jak S7 będzie zapisywać edytowany plan.
- Nowy katalog `cali-park/Features/Planner/` — projekt używa `PBXFileSystemSynchronizedRootGroup` na `cali-park` i `cali-parkTests` (zweryfikowane w `project.pbxproj`), więc nowy podkatalog i pliki podpinają się do targetu same.

**Znane problemy / TODO:**
- Brak UI — planów nie da się jeszcze utworzyć z aplikacji (to S7). `workoutPlanStore` jest w `AppEnvironment`, ale nikt z niego jeszcze nie czyta (jak `workoutLogStore` po S1/S2).
- Brak pory dnia / powiadomień lokalnych i nazwy „typu" treningu — świadome cięcia (App Store: powiadomienia dopiero z realnym kodem + uprawnieniami).
- `PlannedExercise.targetSets/targetReps` w modelu, ale UI ich użycia (prefill SetPada) dochodzi w S8.

**Wskazówki dla następnego agenta (Sprint 7):**
- Zbuduj `WorkoutPlansViewModel` (`@Observable`, lista z `workoutPlanStore.load()`, delete) + `WorkoutPlansView`, oraz `PlanEditorViewModel`/`PlanEditorView` (nazwa, ćwiczenia przez reużyty `ExercisePickerSheet`, harmonogram). Zapis edytowanego planu przez `store.save(plan)` (upsert).
- Dodaj fabryki w `AppEnvironment`: `makeWorkoutPlansViewModel()`, `makePlanEditorViewModel(plan:)` (plan opcjonalny = nowy).
- Wybór dni tygodnia: użyj `Weekday.ordered(for:)` do kolejności; harmonogram to POJEDYNCZY stan wyboru (segment „Co tydzień" / „Co N dni" / „Jednorazowo"), nie kilka niezależnych toggle (patrz swiftui-design-principles: „Mutually exclusive options").
- Opis harmonogramu po polsku (np. „Co tydzień: Pon, Czw") licz w VM/warstwie prezentacji, nie w modelu (writing-for-interfaces); do odmiany dni jest już `PolishPlural.days`.
- Kolory tylko z `AppTheme` (`Color.accent`/`.appBackground`/`.componentBackground`/`.textPrimary/.textSecondary`), siatka spacingu 4/8, `clipShape(.rect(cornerRadius:))`, przyciski jako `Button` (nie `onTapGesture`).
- ZANIM zaczniesz: sprawdź, czy Sprint 6 ma status `zakończony` (użytkownik weryfikuje build).

**Do ręcznej weryfikacji przez użytkownika:**
- Build w Xcode (5 nowych plików app: `Weekday`, `WorkoutSchedule`, `PlannedExercise`, `WorkoutPlan`, `WorkoutPlanStore` + 1 plik testów `WorkoutPlanTests`; zmieniony: `AppEnvironment`). Pliki w `Features/Planner/` podpną się same (synchronized groups).
- Testy: `WeekdayTests`, `WorkoutScheduleTests`, `WorkoutPlanTests`, `WorkoutPlanCodableTests`, `WorkoutPlanStoreTests` (+ wszystkie poprzednie — nic w starym kodzie nie zmieniano poza dodaniem pola w `AppEnvironment`).
- Brak smoke testu UI (Sprint bez UI). Ewentualnie: aplikacja nadal buduje się i działa jak po Sprincie 5 (planer jeszcze niewidoczny).
- Po pozytywnej weryfikacji: zmień status Sprintu 6 w tabeli na `zakończony`.

---

### Sprint 7 — 2026-07-14, agent (siódmy)

Uwaga wstępna: Sprint 6 miał status `do weryfikacji`, ale użytkownik potwierdził, że build Sprintu 6 przeszedł bez błędów — oznaczyłem Sprint 6 jako `zakończony` i wykonałem Sprint 7 (UI planera: lista planów + kreator/edytor). Fundament danych planera (modele + store + `workoutPlanStore` w `AppEnvironment`) był gotowy z S6 — S7 dokłada tylko warstwę VM/UI + wejście.

**Zrobione:**
- `cali-park/Features/Planner/ViewModels/WorkoutScheduleFormatter.swift` (NOWY) — współdzielony helper prezentacji: `summary(_:)` zamienia `WorkoutSchedule` na krótki polski opis („Co tydzień · Pon, Czw", „Co 3 dni", „Codziennie", „Jednorazowo · 20 lip", „Bez terminu"). Dni w kolejności locale (`Weekday.ordered`). Logika opisu poza modelem (writing-for-interfaces).
- `cali-park/Features/Planner/ViewModels/PlanEditorViewModel.swift` (NOWY) — `@Observable @MainActor`; tworzenie i edycja planu. Pola: `name`, `exercises: [PlannedExercise]`, `scheduleMode` (enum `weekly`/`everyNDays`/`once` — POJEDYNCZY stan wyboru), `selectedWeekdays`, `interval`, `onceDate`. `schedule` składany z trybu; `canSave` = nazwa (trim) niepusta + ≥1 ćwiczenie + poprawny harmonogram. Intencje: `addExercise` (bez duplikatów po `exerciseID`), `remove`, `toggle(weekday)`, `save()` (upsert przez `store.save`, błąd → `errorMessage`, sukces → `didSave`). Edycja preloaduje pola z istniejącego planu i zachowuje `id`/`createdAt`/`isActive`/kotwicę `everyNDays`.
- `cali-park/Features/Planner/ViewModels/WorkoutPlansViewModel.swift` (NOWY) — `@Observable @MainActor`; `plans` (od najnowszego po `createdAt`), `reload()`, `delete(_:)` (błąd → alert), `scheduleSummary(for:)` przez formatter.
- `cali-park/Features/Planner/Views/PlanEditorView.swift` (NOWY) — `Form` (styl natywny, ciemny motyw): sekcja Nazwa (`TextField`), Ćwiczenia (lista + swipe-to-delete + „Dodaj ćwiczenie" → `ExercisePickerSheet`), Harmonogram (segmented `Picker` trybu + `WeekdaySelector`/`Stepper`/`DatePicker` zależnie od trybu, stopka z opisem PL). Toolbar „Anuluj"/„Zapisz" (Zapisz disabled dopóki `!canSave`). Prezentowany jako sheet z własnym `NavigationStack`. Podwidoki jako osobne `private struct` (wydajność `@Observable`).
- `cali-park/Features/Planner/Views/WorkoutPlansView.swift` (NOWY) — lista planów (nazwa + opis harmonogramu + liczba ćwiczeń), swipe-to-delete, stan pusty z CTA, toolbar „+". Tap w wiersz = edycja, „+" = nowy — oba przez `sheet(item: PlanEditorRoute)` (`.new`/`.edit(plan)`), reload po zapisie. Pushowany z zakładki Ćwiczenia (bez własnego `NavigationStack`).
- `cali-park/Core/AppEnvironment.swift` — fabryki `makeWorkoutPlansViewModel()` i `makePlanEditorViewModel(plan:)` (plan opcjonalny = nowy); usunięta nieaktualna notatka „bez fabryk (S7)".
- `cali-park/Features/Exercises/Views/ExerciseLibraryView.swift` — wejście do planera: przycisk `calendar` w toolbarze (leading) + `navigationDestination(for: WorkoutPlansDestination.self)` → `WorkoutPlansView(environment:)`.
- `cali-parkTests/PlanEditorViewModelTests.swift` (NOWY) — Swift Testing (`@MainActor`): walidacja (nazwa/ćwiczenia/dni weekly), duplikaty ignorowane, remove (offset + wartość), toggle dni, `schedule` per tryb, `save` upsert (stały `id`, edycja nie duplikuje), no-op bez pól, błąd przez `FailingWorkoutPlanStore`, preload przy edycji; `WorkoutPlansViewModelTests` (sort najnowsze-first, delete); `WorkoutScheduleFormatterTests` (kolejność dni locale, pusty weekly, codziennie/Co N dni, szkic bez terminu).

**Odstępstwa od planu:** brak istotnych. Doprecyzowanie: dodałem do `canSave` warunek „poprawny harmonogram" (weekly wymaga ≥1 dnia, interval > 0) ponad plan „nazwa niepusta + ≥1 ćwiczenie" — bez tego dałoby się zapisać plan tygodniowy bez żadnego dnia (harmonogram nigdy by nie wystąpił). Tryb `once` zawsze poprawny (data domyślnie dziś).

**Decyzje podjęte w trakcie:**
- Harmonogram jako `scheduleMode` (segmented `Picker`) — jeden aktywny tryb, nie kilka niezależnych toggle (swiftui-design-principles: „Mutually exclusive options"). W trybie `weekly` wybór wielu dni to naturalny `Set<Weekday>` (chipsy `WeekdaySelector`).
- Edytor jako `Form` (natywne sekcje, keyboard handling) z `.scrollContentBackground(.hidden)` + `Color.appBackground` i `.listRowBackground(Color.componentBackground)` — spójne z ciemnym motywem, mniej custom kodu.
- Editor prezentowany jako sheet (`PlanEditorRoute` przez `sheet(item:)`, nie `Bool` + osobny stan) — payload decyduje o trybie nowy/edycja; `WorkoutPlansView` pushowany (dziedziczy `NavigationStack` zakładki).
- `WorkoutScheduleFormatter` jako osobny typ współdzielony przez oba VM (lista + stopka edytora) — jedno źródło opisu PL.
- Usunąłem `.onMove`/`move(...)` (reorder) — brak wejścia w tryb edycji (EditButton), więc byłby to martwy afford; swipe-delete wystarcza. Do dodania z EditButton, jeśli zajdzie potrzeba.
- Wejście przez ikonę `calendar` w toolbarze (leading), obok istniejącej ikony historii (trailing) — bez zaśmiecania dolnego paska (tam jest akcentowy „Szybki trening").

**Znane problemy / TODO:**
- Brak edycji `targetSets`/`targetReps` w UI — `PlannedExercise` ma te pola (dla prefill SetPada w S8), ale edytor dodaje ćwiczenie bez targetów (świadome cięcie; S8 użyje prefill nawet przy `nil`).
- Brak reorderu ćwiczeń w planie (patrz wyżej) i przełącznika `isActive` w UI (nowe plany są aktywne; model gotowy).
- `once`/`everyNDays` są w pełni wspierane w edytorze, choć DoD skupia się na „co tydzień" — trzymają się modelu z S6, więc bez martwych ścieżek.
- Planer nadal NIE jest podłączony do Home — to zakres S8 (`nextPlannedWorkout` + „Rozpocznij" z prefillem sesji z planu).

**Wskazówki dla następnego agenta (Sprint 8):**
- W `HomeDashboardViewModel` dodaj `workoutPlanStore` (drugi store — DI jak `workoutLogStore`) i `nextPlannedWorkout`: z `store.load()` wybierz aktywny plan z najbliższym `plan.nextOccurrence(...)` (deterministyczny kalendarz w testach). `nextOccurrence` liczy dzień WŁĄCZNIE (dziś się liczy) — zdecyduj na Home, czy „dziś" czy „następny".
- „Nast. trening" na Home (`PrimaryActionRailView` / moduł „next"): pokaż nazwę planu + kiedy (`WorkoutScheduleFormatter` gotowy do reużycia albo `Text(date, format:)`), „Rozpocznij" → `QuickWorkoutView` z prefillem `DraftItem` z `PlannedExercise` (użytkownik zatwierdza serie na SetPadzie). Przy braku planów — obecny fallback (heurystyka `suggestedExercise`).
- Prefill sesji: `QuickWorkoutViewModel` obecnie dostaje pozycje przez `addExercise(_:sets:)`. Na S8 rozważ init z listą wstępnych `DraftItem` (z `targetSets`/`targetReps` → puste serie do uzupełnienia) LUB seed z planu; `finish()` już zapisuje jako jedną sesję.
- Fabryka `makePlanEditorViewModel(plan:)` i `makeWorkoutPlansViewModel()` są w `AppEnvironment`; `makeHomeDashboardViewModel()` trzeba będzie rozszerzyć o `workoutPlanStore`.
- Nowe pliki leżą w `Features/Planner/` (synchronized groups — podpinają się same): 3 VM + 2 View + 1 plik testów.
- Kolory z `AppTheme`, siatka 4/8, `clipShape(.rect(cornerRadius:))`, przyciski jako `Button` — utrzymane.
- ZANIM zaczniesz: sprawdź, czy Sprint 7 ma status `zakończony` (użytkownik weryfikuje build).

**Do ręcznej weryfikacji przez użytkownika:**
- Build w Xcode (5 nowych plików app: `WorkoutScheduleFormatter`, `PlanEditorViewModel`, `WorkoutPlansViewModel`, `PlanEditorView`, `WorkoutPlansView` + 1 plik testów `PlanEditorViewModelTests`; zmienione: `AppEnvironment`, `ExerciseLibraryView`). Pliki w `Features/Planner/` podpną się same (synchronized groups).
- Testy: `PlanEditorViewModelTests`, `WorkoutPlansViewModelTests`, `WorkoutScheduleFormatterTests` (+ wszystkie poprzednie — nic w starym kodzie nie zmieniano poza `AppEnvironment`/`ExerciseLibraryView`).
- Smoke test: zakładka Ćwiczenia → ikona kalendarza (lewy górny róg) → „Plany treningowe" (pusty stan) → „Nowy plan" → wpisz nazwę „Pull" → „Dodaj ćwiczenie" → wybierz Podciągnięcia i Dipy → tryb „Co tydzień" → zaznacz Pon → stopka pokazuje „Co tydzień · Pon" → „Zapisz" → plan na liście (nazwa + „Co tydzień · Pon" + „2 ćwiczenia"). Tap w plan → edycja (pola wczytane) → zmień na Pon+Czw → Zapisz → opis się aktualizuje. Swipe w lewo → usuń.
- Sprawdź, że „Zapisz" jest nieaktywny dopóki brak nazwy LUB brak ćwiczeń LUB (tryb „Co tydzień" bez żadnego dnia).
- Po pozytywnej weryfikacji: zmień status Sprintu 7 w tabeli na `zakończony`.

---

### Sprint 8 — 2026-07-14, agent (ósmy)

Uwaga wstępna: Sprint 7 miał status `do weryfikacji`, ale użytkownik potwierdził, że build Sprintu 7 przeszedł bez błędów — oznaczyłem Sprint 7 jako `zakończony` i wykonałem Sprint 8 (ostatni sprint mini-planu Planera). S8 podłącza istniejący `workoutPlanStore` (z S6) i UI planera (z S7) do ekranu Home: „Nast. trening" pokazuje teraz najbliższy **zaplanowany** trening i uruchamia sesję z prefillem ćwiczeń z planu.

**Zrobione:**
- `cali-park/Features/Home/ViewModels/HomeDashboardViewModel.swift` — drugi store `workoutPlanStore` + wstrzykiwany `calendar` (DI jak `workoutLogStore`); `reload()` ładuje też `plans`; `PlannedWorkout` (plan + data) i `nextPlannedWorkout` — z aktywnych planów wybiera ten z najbliższym `nextOccurrence` (remis → starszy `createdAt`). Testowalny rdzeń `nextPlannedWorkout(asOf:)` z jawną datą odniesienia. Nowa fabryka `makeQuickWorkoutViewModel(plan:)`.
- `cali-park/Features/Exercises/ViewModels/QuickWorkoutViewModel.swift` — `DraftItem.sets` z `let` na `var` + `isPending` (puste serie = pozycja do uzupełnienia); `convenience init(store:plan:)` seeduje sesję z ćwiczeń planu; czyste, statyczne `draftItem(from:)` i `prefilledSets(from:)` (targetSets×targetReps → konkretne serie; brak/zero targetów → pending). `updateSets(itemID:sets:)` (zatwierdzenie/edycja serii na SetPadzie). `canFinish` = min. jedna niepusta pozycja; `finish()` zapisuje tylko niepuste (pending pomijane), dalej jako jedna sesja (`sessionID`).
- `cali-park/Features/Exercises/Models/SetPadInput.swift` — `init(committedSets:)` do seedowania keypada znanymi seriami (prefill z targetów planu / edycja pozycji).
- `cali-park/Features/Exercises/Views/QuickWorkoutView.swift` — pozycje sesji są teraz klikalne (`Button` → SetPad z prefillem bieżących serii, `ActiveSheet.editItem`); pozycje pending pokazują „Dotknij, aby dodać serie" + ikonę `plus.circle`; `SessionSetPadSheet` przyjmuje `initialSets` i seeduje `SetPadInput`.
- `cali-park/Features/Home/Views/Components/NextWorkoutModuleContent.swift` — priorytet dla zaplanowanego treningu: karta z nazwą planu + „kiedy" (`WorkoutScheduleFormatter.dayLabel`) + liczbą ćwiczeń + „Rozpocznij" (otwiera `QuickWorkoutView` z prefillem). Brak planu → dotychczasowa heurystyka `suggestedExercise`; pusto → uczciwy stan pusty (copy zaktualizowane: „Zaloguj pierwszy trening lub zaplanuj kolejny.").
- `cali-park/Features/Home/Views/Components/PrimaryActionRailView.swift` — drugi przycisk: gdy jest zaplanowany trening → pokazuje nazwę planu i uruchamia sesję z prefillem; gdy brak planu → **„Zaplanuj trening"** otwiera edytor nowego planu (`PlanEditorView` przez `makePlanEditorViewModel()` na dashboardzie), po zapisie `reload()`. (Poprawka po S8 na życzenie użytkownika: fallback to nie „Nast. trening"/logowanie sugerowanego ćwiczenia, tylko wprost zaproszenie do zaplanowania.)
- `cali-park/Features/Home/ViewModels/HomeDashboardViewModel.swift` — dodana fabryka `makePlanEditorViewModel()` (nowy plan, przez `workoutPlanStore`) dla wejścia „Zaplanuj trening" z paska akcji.
- `cali-park/Features/Planner/ViewModels/WorkoutScheduleFormatter.swift` — nowy `dayLabel(_:asOf:calendar:)`: „Dziś"/„Jutro"/nazwa dnia tygodnia (do 7 dni)/data (dalej).
- `cali-park/Core/AppEnvironment.swift` — `makeHomeDashboardViewModel()` przekazuje `workoutPlanStore`.
- `cali-parkTests/HomePlannerTests.swift` (NOWY) — Swift Testing: wybór najbliższego planu z wielu (deterministyczny kalendarz UTC + jawna data odniesienia), pomijanie planów nieaktywnych, remis po `createdAt`, brak planu → nil; prefill `DraftItem` (targety → serie, brak → pending, niekompletne/zero targetów → puste — parametryzowane, nieznane ID → nil); sesja z planu (seed, canFinish, totalSets), pending nie da się zakończyć dopóki nie zalogujesz serii, `finish()` zapisuje tylko zatwierdzone pod jednym `sessionID`; `dayLabel` (Dziś/Jutro/dzień tygodnia).

**Odstępstwa od planu:** brak istotnych. Doprecyzowania: (1) „prefill DraftItem z PlannedExercise" zrealizowany tak, że pozycje z targetami dostają gotowe serie (do potwierdzenia/edycji), a bez targetów (obecne plany z S7 nie mają targetów) są **pending** — użytkownik zatwierdza serie na SetPadzie (zgodnie z „użytkownik zatwierdza serie na SetPadzie"); `finish()` pomija pending, więc nigdy nie zapisze pustej pozycji. (2) Bogaty widok „nazwa + kiedy + Rozpocznij" trafił do modułu „Następny trening" (ma miejsce), a kompaktowy pasek akcji tylko pokazuje nazwę planu i uruchamia sesję — oba wejścia spójne.

**Decyzje podjęte w trakcie:**
- `nextPlannedWorkout(asOf:)` jako osobna, testowalna metoda z jawną datą; computed property woła ją z `.now`. Kalendarz wstrzykiwany do VM (jak w `WorkoutStreak`).
- Pozycje sesji edytowalne przez tap (`ActiveSheet.editItem`) zamiast osobnego trybu edycji — reużywa istniejący `SetPadEntryView`; pending i „gotowe" pozycje mają ten sam ekran.
- Remis najbliższych planów rozstrzygany po `createdAt` (stabilny, deterministyczny wynik w testach).
- `canFinish`/`finish()` liczone po niepustych pozycjach — wstecznie zgodne z S5 (tam wszystkie pozycje mają serie, więc zachowanie bez zmian).

**Znane problemy / TODO:**
- Edytor planu (S7) nadal nie ustawia `targetSets`/`targetReps` — więc realne plany seedują się jako pending (użytkownik loguje serie ręcznie). Prefill konkretnych serii zadziała od razu, gdy dojdzie UI targetów w edytorze (model gotowy).
- Brak „dziś vs następny" rozróżnienia w akcji — `nextOccurrence` liczy dzień włącznie, więc plan zaplanowany na dziś pokazuje „Dziś" i startuje normalnie (świadome, proste).
- HealthKit/Watch nadal nietknięte (jak w notatkach S4/S5) — `finish()` z jednym `sessionID` to naturalne miejsce na mapowanie sesji na `HKWorkout`.
- Mini-plan Planera (S6–S8) UKOŃCZONY. Kolejne duże tematy: zakładka Profil (statystyki z logów), backend (`WorkoutLogStoring`/`WorkoutPlanStoring` gotowe do podmiany), HealthKit/Watch, ewentualnie powiadomienia lokalne dla harmonogramu (wymaga uprawnień — dodać z realnym kodem, inaczej App Store Review odrzuca).

**Wskazówki dla następnego agenta:**
- Nowe pliki (`HomePlannerTests`) leżą w `cali-parkTests/` (synchronized groups — podpina się samo). Reszta to modyfikacje istniejących plików.
- Jeśli dojdą powiadomienia lokalne: `WorkoutSchedule.nextOccurrence` daje datę do zaplanowania `UNCalendarNotificationTrigger`; pamiętać o `NSUserNotificationsUsageDescription`/uprawnieniach + capability.
- Prefill targetów: dodaj UI `targetSets`/`targetReps` w `PlanEditorView` → `QuickWorkoutViewModel.prefilledSets(from:)` już to rozwinie w gotowe serie (bez zmian w sesji).
- ZANIM zaczniesz kolejny temat: sprawdź, czy Sprint 8 ma status `zakończony` (użytkownik weryfikuje build).

**Do ręcznej weryfikacji przez użytkownika:**
- Build w Xcode (1 nowy plik testów `HomePlannerTests`; zmienione: `HomeDashboardViewModel`, `QuickWorkoutViewModel`, `SetPadInput`, `QuickWorkoutView`, `NextWorkoutModuleContent`, `PrimaryActionRailView`, `WorkoutScheduleFormatter`, `AppEnvironment`).
- Testy: `HomePlannerTests` (`NextPlannedWorkoutTests`, `QuickWorkoutPrefillTests`, `WorkoutScheduleDayLabelTests`) + wszystkie poprzednie (stare testy `QuickWorkoutTests`/`SetPadTests` powinny nadal przechodzić — sygnatury publiczne zachowane).
- Smoke test A (plan → Home): zakładka Ćwiczenia → kalendarz → utwórz plan „Pull" (Podciągnięcia + Dipy, „Co tydzień · <dziś/najbliższy dzień>") → wróć na Home → moduł „Następny trening" pokazuje „Pull", „<Dziś/Jutro/dzień>" i „N ćwiczeń" → „Rozpocznij" otwiera sesję z 2 pozycjami pending („Dotknij, aby dodać serie") → dotknij Podciągnięcia → `6 + 6 + 8` → Dodaj do treningu → „Zakończ" aktywne → Zakończ → w historii jedna karta sesji (Dipy pominięte, bo bez serii).
- Smoke test B (pasek akcji): górny prawy przycisk pokazuje nazwę planu zamiast „Nast. trening" i uruchamia tę samą sesję z prefillem.
- Smoke test C (brak planu): usuń wszystkie plany → moduł „Następny trening" wraca do propozycji heurystycznej; przy pustym dzienniku — stan pusty.
- Po pozytywnej weryfikacji: zmień status Sprintu 8 w tabeli na `zakończony`.
