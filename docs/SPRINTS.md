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
| 1 | Fundament danych: modele, ExerciseCatalog, WorkoutLogStoring + store'y, testy warstwy danych | do weryfikacji | 2026-07-14 |
| 2 | Biblioteka ćwiczeń: ViewModel, lista + chips + szukanie, detal, ikony figure.*, DI w AppEnvironment | oczekuje | — |
| 3 | SetPad + dziennik: SetPadInput, SetPadSheetView, historia logów, testy sekwencji | oczekuje | — |
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
