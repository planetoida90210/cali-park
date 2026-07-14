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
| 5 | „Szybki trening": sesja z dowolnych ćwiczeń (sessionID + batch append), reużywalny SetPadEntryView, ExercisePickerSheet, wejścia z Home i Ćwiczeń, grupowanie sesji w historii | do weryfikacji | 2026-07-14 |

Statusy: `oczekuje` → `w toku` → `do weryfikacji` → `zakończony` (ustawia użytkownik).

> Uwaga: plan pierwotnie miał 4 sprinty; Sprint 5 dodano po ich ukończeniu na prośbę użytkownika (logowanie sprawiało wrażenie „tylko podciągnięcia"). Definicja Sprintu 5 w pliku planu.

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
