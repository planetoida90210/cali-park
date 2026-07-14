---
name: Zakładka Ćwiczenia + dziennik
overview: "Budowa zakładki Ćwiczenia wg wzorca MVVM z Parks: lokalna biblioteka ćwiczeń, prosty dziennik treningów z persystencją, oraz podłączenie modułów Home (Quick Log, Następny trening, streak) pod realne dane z logów. Praca podzielona na 4 sprinty wykonywane przez osobnych agentów — status w docs/SPRINTS.md."
todos:
  - id: s1-models
    content: "S1: Modele Exercise, MuscleGroup, WorkoutLogEntry/LoggedSet (Codable, stałe UUID) w Features/Exercises/Models/"
    status: completed
  - id: s1-catalog
    content: "S1: ExerciseCatalog — wbudowany katalog ~15–20 ćwiczeń kalisteniki po polsku z mapowaniem na SF Symbols figure.*"
    status: completed
  - id: s1-log-store
    content: "S1: WorkoutLogStoring + FileWorkoutLogStore (JSON w documentsDirectory) + InMemoryWorkoutLogStore"
    status: completed
  - id: s1-tests
    content: "S1: Testy — integralność katalogu, roundtrip store"
    status: completed
  - id: s2-library-vm-view
    content: "S2: ExerciseLibraryViewModel (@Observable) + przebudowa ExerciseLibraryView (lista, chips, szukanie, navigationDestination)"
    status: completed
  - id: s2-detail
    content: "S2: ExerciseDetailView (opis, grupy, instrukcje, ikona figure.*)"
    status: completed
  - id: s2-app-env
    content: "S2: Rejestracja workoutLogStore i fabryk w AppEnvironment + DI do ExerciseLibraryView w MainTabView"
    status: completed
  - id: s2-tests
    content: "S2: Testy — filtr kategorii i szukanie jako testy parametryzowane"
    status: completed
  - id: s3-setpad-input
    content: "S3: SetPadInput — czysty typ logiki licznika serii (+ / ⌫ / C)"
    status: completed
  - id: s3-setpad-view
    content: "S3: SetPadSheetView + WorkoutLogViewModel z alertem błędów, prezentacja sheet(item:) z detalu ćwiczenia"
    status: completed
  - id: s3-history
    content: "S3: Historia logów w zakładce Ćwiczenia (lista + swipe-to-delete)"
    status: completed
  - id: s3-tests
    content: "S3: Testy — sekwencje SetPadInput (parametryzowane), błędy VM, polska odmiana serii/powtórzeń"
    status: completed
  - id: s4-home-modules
    content: "S4: Podłączenie QuickLog/Streak/NextWorkout/HeroCard pod realne logi, usunięcie martwego dailyChallenge"
    status: completed
  - id: s4-cleanup
    content: "S4: Tab API w MainTabView, NavigationStack w HomeView, deprecated modifiery w dotykanych plikach, wypełnienie pustego AccentColor.colorset (#D1FF00)"
    status: completed
  - id: s4-tests
    content: "S4: Testy — logika streak (dziś, wczoraj, przerwa) jako testy parametryzowane"
    status: completed
  - id: s5-model
    content: "S5: sessionID (opcjonalny) w WorkoutLogEntry + batch append w WorkoutLogStoring (atomowy zapis sesji)"
    status: completed
  - id: s5-setpad-reuse
    content: "S5: Wydzielenie SetPadEntryView (reużywalny keypad) — SetPadSheetView korzysta z niego bez zmiany zachowania"
    status: completed
  - id: s5-session
    content: "S5: QuickWorkoutViewModel + QuickWorkoutView (Szybki trening: dodaj dowolne ćwiczenia → Zakończ) + ExercisePickerSheet"
    status: completed
  - id: s5-entrypoints
    content: "S5: Wejścia — przycisk Szybki trening w zakładce Ćwiczenia i w module Quick Log (Home); grupowanie sesji w historii"
    status: completed
  - id: s5-tests
    content: "S5: Testy — QuickWorkoutViewModel, batch append, grupowanie historii, wsteczna zgodność Codable sessionID"
    status: completed
  - id: s6-models
    content: "S6: Modele planera — Weekday, WorkoutSchedule (+ nextOccurrence), PlannedExercise, WorkoutPlan (Codable, stałe UUID)"
    status: completed
  - id: s6-store
    content: "S6: WorkoutPlanStoring + FileWorkoutPlanStore (JSON w documentsDirectory, upsert) + InMemoryWorkoutPlanStore"
    status: completed
  - id: s6-env
    content: "S6: Rejestracja workoutPlanStore w AppEnvironment (bez konsumenta — VM/UI w S7)"
    status: completed
  - id: s6-tests
    content: "S6: Testy — WorkoutSchedule.nextOccurrence (parametryzowane), roundtrip store, Codable/Weekday↔Calendar"
    status: completed
  - id: s7-editor
    content: "S7: WorkoutPlansViewModel + PlanEditorViewModel/PlanEditorView (nazwa, ćwiczenia przez ExercisePickerSheet, harmonogram) + lista planów"
    status: completed
  - id: s7-di
    content: "S7: Fabryki planera w AppEnvironment + wejście do listy planów (zakładka Ćwiczenia)"
    status: completed
  - id: s7-tests
    content: "S7: Testy — VM edytora (walidacja, dodawanie/usuwanie ćwiczeń, wybór harmonogramu)"
    status: completed
  - id: s8-home
    content: "S8: Home — zamiana „Nast. trening\" na plan (najbliższy zaplanowany trening) + „Rozpocznij\" prefill sesji z planu"
    status: pending
  - id: s8-tests
    content: "S8: Testy — wybór najbliższego planu z wielu, prefill DraftItem z PlannedExercise"
    status: pending
isProject: false
---

# Zakładka Ćwiczenia + dziennik treningów + ożywienie Home

## Zasady dla agentów (obowiązkowe)

1. **NIE uruchamiać `xcodebuild`** ani żadnej weryfikacji kompilacji — build i testy sprawdza wyłącznie użytkownik ręcznie w Xcode.
2. **Wykonujesz TYLKO swój sprint** (sprawdź w [docs/SPRINTS.md](docs/SPRINTS.md), który jest następny). Nie wybiegaj w przód, nawet jeśli widzisz oczywisty kolejny krok.
3. **Przed startem** przeczytaj cały ten plan + wpisy poprzednich agentów w [docs/SPRINTS.md](docs/SPRINTS.md) (sekcja „Dziennik sprintów").
4. **Po sprincie obowiązkowo**: (a) zmień statusy swoich todos w tym pliku na `completed`, (b) uzupełnij swój wpis w dzienniku w `docs/SPRINTS.md` — co zrobione, odstępstwa od planu, decyzje, wskazówki dla następnego agenta, (c) ustaw status sprintu na „do weryfikacji" — na „zakończony" zmienia go użytkownik po ręcznym buildzie.
5. Nowe pliki Swift trzeba dodać do targetu w Xcode — jeśli projekt używa file system synchronized groups, wystarczy położyć plik w katalogu; w razie wątpliwości zostaw notkę użytkownikowi w dzienniku.

## Kontekst architektoniczny (dotyczy wszystkich sprintów)

Wzorzec: **MVVM (fit)** jak w Parks — protokoły serwisów, DI przez [cali-park/Core/AppEnvironment.swift](cali-park/Core/AppEnvironment.swift), modele `Codable` z `UUID`. Nowe ViewModele wg reguł projektu na `@Observable` (nie `ObservableObject`). Zero nowych zależności. Backend odłożony — dziennik za protokołem, później czysta podmiana na Supabase/Firebase. **Kolory tylko z [AppTheme.swift](cali-park/Core/Theme/AppTheme.swift)** (`Color.accent` #D1FF00, `.appBackground` #121212, `.componentBackground`, `.textPrimary/.textSecondary`) — bez nowych hexów. Jeden typ = jeden plik.

---

## Sprint 1 — fundament danych (bez UI)

- **Modele** w `cali-park/Features/Exercises/Models/`:
  - **`Exercise`** — `id: UUID` (stały, jak `mockParkID`), `name`, `category` (enum: podstawowe/zaawansowane/ekspert), `muscleGroups: [MuscleGroup]`, `description`, `instructions: [String]`, **`symbolName: String`** (SF Symbol z rodziny `figure.*`), opcjonalnie `equipment: [String]` (spójne ze stringami w `Park.equipments`). `Codable`.
  - **`MuscleGroup`** — enum `String`, `Codable` (plecy, klatka, ramiona, core, nogi…).
  - **`WorkoutLogEntry`** — `id: UUID`, `exerciseID: UUID`, `date`, `sets: [LoggedSet]` (`reps`, opcjonalnie `weight`), opcjonalna `note`. `Codable`.
- **Warstwa danych** w `cali-park/Features/Exercises/Services/`:
  - **`ExerciseCatalog`** — statyczny, wbudowany katalog ~15–20 ćwiczeń kalisteniki po polsku (podciągnięcia, pompki, dipy, muscle-up, front lever, flagi…). Dane produkcyjne, nie mock. Mapowanie ćwiczenie→symbol z puli: `figure.strengthtraining.traditional`, `figure.strengthtraining.functional`, `figure.core.training`, `figure.gymnastics`, `figure.climbing`, `figure.flexibility`, `figure.cooldown`, `figure.play` (brak dedykowanego „pullup" — najbliższy zamiennik per ćwiczenie).
  - **`WorkoutLogStoring`** (protokół) + **`FileWorkoutLogStore`** — zapis JSON w `URL.documentsDirectory`; metody `load() -> [WorkoutLogEntry]`, `append(_:)`, `delete(id:)`. Do testów `InMemoryWorkoutLogStore` (analogicznie do `InMemoryFavoritesStore`). Świadomie NIE Core Data — pusty szkielet `PersistenceController` zostaje nietknięty.
- **Testy** (Swift Testing): integralność katalogu (unikalne ID, niepuste kategorie/grupy/symbole), `FileWorkoutLogStore` roundtrip zapis/odczyt/usunięcie (katalog tymczasowy).

**Definition of done:** modele + katalog + store istnieją, testy warstwy danych przechodzą (weryfikuje użytkownik), żadnych zmian w UI.

## Sprint 2 — biblioteka ćwiczeń (UI + DI)

- **`ExerciseLibraryViewModel`** (`@Observable`): lista z katalogu, filtr po kategorii (chips) i wyszukiwarka (wzorzec filtrów z `ParksViewModel`).
- **Przebudowa [ExerciseLibraryView.swift](cali-park/Features/Exercises/Views/ExerciseLibraryView.swift)**: realna lista z `navigationDestination(for: Exercise.self)`, chips kategorii jako przyciski (nie `onTapGesture`), pole szukania.
- **`ExerciseDetailView`** (nowy): opis, grupy mięśniowe, instrukcje krok po kroku. Przycisk „Dodaj serię" dopiero w Sprincie 3 — tu bez niego.
- **Ikony — styl Apple Watch Workout**: czarny glif `Image(systemName: exercise.symbolName)` + `.foregroundStyle(.black)` na kole `Color.accent`; jeden rozmiar koła w liście, większy w detalu, oba z siatki spacingu 4/8. Żadnych ilustracji/grafik.
- **DI**: rejestracja `workoutLogStore: WorkoutLogStoring` + fabryka `makeExerciseLibraryViewModel()` w `AppEnvironment`; `ExerciseLibraryView` dostaje environment w [MainTabView.swift](cali-park/Features/Main/MainTabView.swift) (dziś tylko Parks ma DI).
- **Testy**: filtr kategorii + szukanie jako testy parametryzowane (`@Test(arguments:)`).

**Definition of done:** przeglądanie biblioteki działa (lista → filtr → szukanie → detal), ikony w stylu Watch, testy VM przechodzą.

## Sprint 3 — SetPad + dziennik (serce feature'u)

- **`SetPadInput`** — czysty, testowalny typ logiki (stan: `[Int]` zatwierdzone serie + `String` bieżący wpis): cyfry 0–9; `+` zatwierdza bieżącą liczbę jako serię; `⌫` kasuje cyfrę, a przy pustym wpisie cofa ostatnią serię; `C` czyści całość; blokada zapisu pustego wpisu; limit 3 cyfr.
- **`SetPadSheetView`** + **`WorkoutLogViewModel`** (`@Observable`) — licznik serii w stylu kalkulatora (wzorowany na nawyku użytkownika: `6+6+6+8+6`). Zapis przez `WorkoutLogStoring`, błędy przez alert (wzorzec z `ParkPhotosViewModel`).
  - **Wyświetlacz**: serie jako `6 + 6 + 6 + 8 + 6` dużym, lekkim krojem Dynamic Type z `.monospacedDigit()` i `.contentTransition(.numericText())`; pod spodem suma i liczba serii w kolorze drugorzędnym z AppTheme. Max 3 rozmiary fontu; spacing z siatki 4/8; klawisze na `Color.componentBackground`, akcent (#D1FF00) tylko na `+` i `Zapisz`.
  - **Prezentacja**: sheet z medium detent, `sheet(item:)` z payloadem ćwiczenia (nie `Bool` + osobny stan). Klawisze jako prawdziwe `Button` z etykietami dostępności („Dodaj serię", „Usuń", „Wyczyść"). Haptic feedback na `+`.
  - **Copy**: pusty stan `0` + jednorazowa podpowiedź „Każdy + to nowa seria"; przycisk „Zapisz" (nazwana akcja, nie `=`); poprawna polska odmiana („1 seria / 2 serie / 5 serii", „1 powtórzenie / 2 powtórzenia / 5 powtórzeń"); brak komunikatu sukcesu — potwierdzeniem jest wpis w historii.
  - **Świadome cięcie**: bez pola ciężaru i notatki (szybkość > kompletność) — `LoggedSet.weight`/`note` zostają w modelu na później.
- **Wejście**: przycisk „Dodaj serię" w `ExerciseDetailView` otwiera SetPad.
- **Historia logów**: sekcja/ekran „Ostatnie treningi" w zakładce Ćwiczenia (lista wpisów z datą, ćwiczeniem, ikoną i seriami; swipe-to-delete; daty przez `Text(_, format:)`).
- **Testy**: sekwencje `SetPadInput` parametryzowane (`6,+,6,+,8` → `[6,6]` + wpis `8`; `⌫` na pustym cofa serię; `C` czyści), błędy `WorkoutLogViewModel` (stub rzucający — wzorzec `FailingReviewsService`), polska odmiana 1 / 2–4 / 5+.

**Definition of done:** pełna pętla — detal ćwiczenia → SetPad → `6+6+8` → Zapisz → wpis widoczny w historii; testy przechodzą.

## Sprint 4 — ożywienie Home + sprzątanie

- Moduły dostają dane z tego samego `WorkoutLogStoring` (przez `AppEnvironment` — HomeView dziś nie ma DI, trzeba przekazać):
  - **`QuickLogModuleContent`** — ostatni wpis z dziennika; przycisk otwiera `SetPadSheetView` z ostatnio logowanym ćwiczeniem (domyślnie podciągnięcia).
  - **`StreakModuleContent`** — streak i kalendarz liczone z dat wpisów (koniec hardkodu „Lipiec 2023").
  - **`NextWorkoutModuleContent`** — heurystyka „proponowane następne ćwiczenie" (najdawniej nietrenowana grupa mięśniowa); jeśli za dużo — uczciwy stan pusty.
  - **`HeroCardView`** — tygodniowa liczba podciągnięć z logów (profil/imię zostaje z mocka do sprintu Profil); usunąć martwe `dailyChallenge` z `HomeView`.
- **Sprzątanie plików, które i tak dotykamy**: [MainTabView.swift](cali-park/Features/Main/MainTabView.swift) `tabItem` → nowe **Tab API**; `HomeView.swift` `NavigationView` → `NavigationStack` + usunąć `DispatchQueue.main.asyncAfter`; w dotykanych plikach `foregroundColor` → `foregroundStyle`, `cornerRadius` → `clipShape(.rect(cornerRadius:))`; wypełnić pusty `AccentColor.colorset` wartością #D1FF00.
- **Testy**: logika streak (dziś, wczoraj, przerwa) jako testy parametryzowane.

**Definition of done:** Quick Log, streak i hero na Home pokazują realne dane z dziennika, zero deprecated API w dotykanych plikach.

## Sprint 5 — „Szybki trening" (dodane po ukończeniu planu 4-sprintowego)

Powód: użytkownik zgłosił, że logowanie sprawia wrażenie „tylko podciągnięcia" — oba wejścia (Home Quick Log domyślnie podciągnięcia; zakładka Ćwiczenia wymusza wejście w detal jednego ćwiczenia) prowadzą do jednego ćwiczenia. Brakuje szybkiego zalogowania całego treningu z dowolnych ćwiczeń.

- **Model**: opcjonalny `sessionID: UUID?` w `WorkoutLogEntry` (wstecznie zgodny — stare logi dekodują się z `nil`). Batch `append(contentsOf:)` w `WorkoutLogStoring` (default w extension + atomowy override w `FileWorkoutLogStore`) — sesja zapisuje się jednym zapisem, all-or-nothing.
- **Reużycie SetPada**: wydzielony `SetPadEntryView` (nagłówek + wyświetlacz + keypad + przycisk zapisu, sterowany `Binding<SetPadInput>` + `onSave`). `SetPadSheetView` (pojedyncze ćwiczenie, persystencja przez VM + alert) korzysta z niego bez zmiany zachowania; sesja używa go z akumulacją w pamięci.
- **Sesja**: `QuickWorkoutViewModel` (`@Observable`) — akumuluje pozycje (`DraftItem`: ćwiczenie + serie), `finish()` zapisuje wszystko jako jedną sesję. `QuickWorkoutView` — lista dodanych ćwiczeń, „Dodaj ćwiczenie" → `ExercisePickerSheet` (reużywa `ExerciseLibraryViewModel` do szukania/filtrów) → SetPad → pozycja dołącza do listy → „Zakończ". Łańcuch pod-sheetów przez jeden enum `ActiveSheet` (nigdy dwa naraz).
- **Wejścia**: przycisk „Szybki trening" (akcent, `safeAreaInset` dolny) w zakładce Ćwiczenia; w module Quick Log na Home „Szybki trening" jako akcja główna + „Dodaj serię — {ostatnie}" jako akcja pomocnicza (tylko gdy jest ostatni wpis).
- **Historia**: wpisy z tym samym `sessionID` grupują się w jedną kartę sesji (nagłówek: data + „N ćwiczeń · M powtórzeń"); pojedyncze wpisy (nil) zostają osobnymi wierszami; kolejność chronologiczna.
- **Testy**: `QuickWorkoutViewModel` (akumulacja, pusty no-op, `finish` = jeden sessionID + jeden timestamp, błąd przez `FailingWorkoutLogStore`), batch append (InMemory + FileStore temp dir), grupowanie historii, roundtrip + wsteczna zgodność `sessionID` w Codable.

**Definition of done:** „Szybki trening" z Home i z zakładki Ćwiczenia → dodaj kilka różnych ćwiczeń → Zakończ → sesja widoczna jako jedna karta w historii; pojedyncze logowanie ćwiczenia działa jak dotąd; testy przechodzą.

---

## Planer treningów — „Zaplanuj trening" (mini-plan, Sprinty 6–8, dodany po Sprincie 5)

Powód: użytkownik zauważył, że na Home „Szybki trening" i „Nast. trening" prowadzą do tego samego (logowanie). Zamiast drugiego przycisku-do-logowania potrzebny jest **plan treningu**: budujesz trening (zestaw ćwiczeń) i zapisujesz, jak często chcesz go wykonywać (np. co tydzień w poniedziałek). Docelowo rozbudowywalne. Feature żyje w nowym katalogu `cali-park/Features/Planner/`.

Świadome cięcia całego mini-planu (zgodnie z „szybko do App Store"): brak powiadomień lokalnych (osobny temat — wymaga uprawnień, dodać dopiero z realnym kodem), brak pory dnia w harmonogramie (na razie granulacja dzienna), brak integracji HealthKit/Watch (architektura gotowa — patrz notatki S4/S5).

### Sprint 6 — fundament danych planera (bez UI) ✅ zrobione

- **Modele** w `cali-park/Features/Planner/Models/`:
  - **`Weekday`** — enum `Int` (rawValue = `Calendar` `.weekday`: niedziela = 1 … sobota = 7), `Codable`, `CaseIterable`, polskie `displayName`/`shortName`.
  - **`WorkoutSchedule`** — enum `Codable`: `once(Date?)` (jednorazowy / szkic bez daty), `weekly(Set<Weekday>)` (co tydzień w wybrane dni), `everyNDays(Int, from: Date)` (co N dni od kotwicy). Czysta, testowalna funkcja `nextOccurrence(onOrAfter:calendar:)` — liczy najbliższy dzień wystąpienia (granulacja dzienna, `startOfDay`).
  - **`PlannedExercise`** — `id: UUID`, `exerciseID: UUID` (z `ExerciseCatalog`), opcjonalne `targetSets`/`targetReps`. `Codable`.
  - **`WorkoutPlan`** — `id: UUID`, `name`, `exercises: [PlannedExercise]`, `schedule`, `isActive`, `createdAt`. `Codable`. `nextOccurrence(...)` respektuje `isActive`.
- **Warstwa danych** w `cali-park/Features/Planner/Services/`: `WorkoutPlanStoring` (`load`, `save` = upsert po `id`, `delete(id:)`) + `FileWorkoutPlanStore` (JSON `workout-plans.json` w `URL.documentsDirectory`, ISO 8601) + `InMemoryWorkoutPlanStore`. Analogia do `WorkoutLogStore`.
- **AppEnvironment**: `workoutPlanStore: WorkoutPlanStoring = FileWorkoutPlanStore()` (bez fabryk VM — te dochodzą w S7, wraz z typami VM).
- **Testy**: `WorkoutSchedule.nextOccurrence` parametryzowane (weekly/interval/once, deterministyczny kalendarz UTC), roundtrip store (InMemory + File temp dir, upsert, delete), Codable per wariant harmonogramu, zgodność `Weekday.rawValue` z `Calendar`.

**Definition of done:** modele + harmonogram + store istnieją, testy przechodzą (weryfikuje użytkownik), zero zmian w UI.

### Sprint 7 — UI planera (lista + kreator/edytor)

- `WorkoutPlansViewModel` (`@Observable`) + `WorkoutPlansView` — lista planów (nazwa, podsumowanie harmonogramu, liczba ćwiczeń), swipe-to-delete, wejście do edytora.
- `PlanEditorViewModel` + `PlanEditorView` — nazwa planu, dodawanie ćwiczeń (reużyj `ExercisePickerSheet`), wybór harmonogramu (dni tygodnia jako pojedynczy stan wyboru — nie osobne toggle; „co N dni" jako alternatywa). Walidacja: nazwa niepusta + ≥1 ćwiczenie.
- Fabryki w `AppEnvironment` (`makeWorkoutPlansViewModel`, `makePlanEditorViewModel(plan:)`).
- Wejście: przycisk/pozycja „Plany treningowe" w zakładce Ćwiczenia (toolbar lub nad `QuickWorkoutButton`).
- Kolory z AppTheme, siatka spacingu 4/8, harmonogram jako czytelny opis PL (writing-for-interfaces), `Weekday` w kolejności zależnej od locale w UI.

**Definition of done:** utworzenie planu (nazwa + ćwiczenia + „co tydzień w poniedziałek") → zapis → widoczny na liście; edycja i usuwanie działają; testy VM przechodzą.

### Sprint 8 — Home: najbliższy zaplanowany trening + start z planu

- W `HomeDashboardViewModel`: `nextPlannedWorkout` — z `workoutPlanStore` wybiera plan z najbliższym `nextOccurrence` (aktywne plany).
- `PrimaryActionRailView` / moduł „next": „Nast. trening" pokazuje najbliższy **zaplanowany** trening (nazwa + kiedy) i „Rozpocznij" → `QuickWorkoutView` z prefillem `DraftItem` z `PlannedExercise` (użytkownik zatwierdza serie na SetPadzie); przy braku planów — uczciwy fallback (obecne zachowanie / propozycja heurystyczna).
- `HomeDashboardViewModel` dostaje `workoutPlanStore` (drugi store) — DI jak dotąd.
- **Testy**: wybór najbliższego z wielu planów (deterministyczny kalendarz), prefill DraftItem z targetSets/targetReps.

**Definition of done:** plan „co tydzień w poniedziałek" pojawia się na Home jako najbliższy trening; „Rozpocznij" otwiera sesję z ćwiczeniami z planu; zapis trafia do historii jak sesja.

---

## Poza zakresem (świadomie, wszystkie sprinty)

- Backend (Supabase vs Firebase SQL Connect — notatka porównawcza gotowa, decyzja później; `WorkoutLogStoring` jest na to gotowy).
- Zakładki Profil (następny duży temat — wpięcie onboardingu i statystyk z logów) i Społeczność (wymaga backendu).
- Planner treningów / harmonogram — tylko heurystyka w module Home.
- Moduł parks w Home i pozostałe moduły (leaderboard, feed, achievements) — zostają na mockach.
- `ModulePreferences` (ObservableObject działa — osobny refaktor).

Weryfikacja końcowa (po Sprincie 4): build + testy w Xcode (ręcznie, użytkownik) + smoke test: zalogowanie serii z detalu ćwiczenia → wpis widoczny w historii, Quick Logu i streaku na Home.
