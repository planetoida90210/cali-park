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
| 3 | SetPad + dziennik: SetPadInput, SetPadSheetView, historia logów, testy sekwencji | do weryfikacji | 2026-07-14 |
| 4 | Home + sprzątanie: Quick Log/streak/hero z realnych logów, Tab API, NavigationStack, AccentColor | oczekuje | — |

Statusy: `oczekuje` → `w toku` → `do weryfikacji` → `zakończony` (ustawia użytkownik).

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
