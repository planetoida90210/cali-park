# Tracker sprintów — Ścieżki progresji kalisteniki (SK1–SK6)

Plan źródłowy: [.cursor/plans/skill_tree_kalisteniki_4d366e3c.plan.md](../.cursor/plans/skill_tree_kalisteniki_4d366e3c.plan.md)
Poprzednie trackery (kontekst, zamknięte): [docs/SPRINTS.md](SPRINTS.md) (Ćwiczenia + dziennik + planer, S1–S8), [docs/SPRINTS-HOME.md](SPRINTS-HOME.md) (kontekstowy hero, H1–H3)

## Instrukcja dla agenta

1. Znajdź w tabeli pierwszy sprint ze statusem `oczekuje` — to twój sprint. Wykonaj TYLKO jego zakres z planu źródłowego.
2. Jeśli poprzedni sprint ma status `do weryfikacji`, ZATRZYMAJ SIĘ i poproś użytkownika o weryfikację buildu w Xcode — nie zaczynaj kolejnego sprintu na niezweryfikowanym fundamencie.
3. Przed startem przeczytaj: cały plan źródłowy, WSZYSTKIE wpisy w dzienniku poniżej oraz notatki końcowe w [docs/SPRINTS.md](SPRINTS.md) i [docs/SPRINTS-HOME.md](SPRINTS-HOME.md) (stan kodu po poprzednich planach). Od SK2 wzwyż: także `docs/PROGRESSIONS.md` (dokument-prawda treści, powstaje w SK1).
4. **Przeczytaj skille przypisane twojemu sprintowi (tabela niżej + sekcja „Obowiązkowe skille" w planie) ZANIM napiszesz pierwszą linię kodu.** To nie jest formalność — wpis w dzienniku ma zawierać punkt „Zastosowane skille" z konkretami (co z którego skilla zastosowałeś / co odrzuciłeś i czemu).
5. NIE uruchamiaj `xcodebuild` ani żadnej weryfikacji kompilacji — build i testy sprawdza użytkownik ręcznie w Xcode.
6. Trzymaj się sekcji „App Store" z planu — dostępność, Dynamic Type, zero deprecated API w dotykanych plikach, zero nowych uprawnień, żadnych martwych CTA.
7. Nowe pliki Swift kładź w katalogach synchronized groups (podpinają się same do targetu); testy w `cali-parkTests/`. Jeden typ = jeden plik.
8. Po skończeniu pracy:
   - zmień status swojego sprintu w tabeli na `do weryfikacji`,
   - odhacz swoje todos w pliku planu (status `completed`),
   - dopisz wpis do dziennika wg szablonu poniżej.
9. Status `zakończony` ustawia wyłącznie użytkownik po ręcznym buildzie i testach.

## Status sprintów

| Sprint | Zakres (skrót) | Status | Data |
|---|---|---|---|
| SK1 | Baza progresji: `docs/PROGRESSIONS.md` ze źródłami (RR / Overcoming Gravity / poradniki), rozszerzenie ExerciseCatalog (~40–50 wariacji, `measurement`, `variantOf`), filtr biblioteki na ruchy główne, modele ProgressionPath/Step/Criterion + ProgressionCatalog, testy integralności | do weryfikacji | 2026-07-18 |
| SK2 | Sekundy w dzienniku: `LoggedSet.durationSeconds` (wstecznie zgodny), SetPad w trybie sekund wg `exercise.measurement`, historia/podsumowania „3 × 20 s", testy Codable back-compat + odmiana PL | zakończony | 2026-07-18 |
| SK3 | Silnik + placement (bez UI): ProgressionEngine (stany ścieżek z logów + deklaracji, ścieżki w pełni niezależne), SkillPlacement + PlacementStoring, XP/poziomy wstecz z historii, odznaki, SkillProgressStore, testy parametryzowane | zakończony | 2026-07-18 |
| SK4 | Placement UI: przebudowa strony poziomu w OnboardingView na placement per ścieżka (pytania liczbowe + skille + guma), arkusz kalibracji w apce, testy mapowania odpowiedzi → szczeble | zakończony | 2026-07-18 |
| SK5 | Zakładka Skille zamiast Społeczności: SkillPathsView (poziom + XP + karty ścieżek), PathDetailView (drabina, bez kłódek), StepDetailSheetView (kryterium + postęp + CTA Trenuj), sekcja „Progresje" w detalu ruchu, drill-in wariantów w pickerze, previews, testy VM | do weryfikacji | 2026-07-18 |
| SK6 | Pętla nagrody + Home: celebracja awansu (raz, kolejka, Reduce Motion), XP toast, sekcja odznak, realny moduł osiągnięć, podpowiedź progresji w hero, wyłączenie atrap leaderboard/feed, bramka jakości App Store | oczekuje | — |

Statusy: `oczekuje` → `w toku` → `do weryfikacji` → `zakończony` (ustawia użytkownik).

## Obowiązkowe skille per sprint

Pliki w `.agents/skills/` (projekt) i `~/.agents/skills/` (globalne). Szczegółowe wymagania per sprint — sekcja „Obowiązkowe skille" w planie źródłowym.

| Sprint | Skille (czytaj PRZED kodem) |
|---|---|
| SK1 | `swift-api-design-guidelines-skill`, `writing-for-interfaces`, `swift-testing-pro`, `core-data-expert` (bramka: decyzja o persystencji), `swift-architecture-skill` |
| SK2 | `swiftui-design-principles`, `writing-for-interfaces`, `swift-testing-pro`, `swift-api-design-guidelines-skill`, `swift-architecture-skill` |
| SK3 | `swift-concurrency-pro`, `swift-testing-pro`, `swift-api-design-guidelines-skill`, `swift-security-expert` (bramka: co wolno trzymać w JSON/UserDefaults), `core-data-expert` (bramka), `swift-architecture-skill` |
| SK4 | `writing-for-interfaces`, `swiftui-design-principles`, `swift-testing-pro`, `swift-security-expert` (bramka: dane placementu to nie sekrety, ale zero sekretów przy okazji), `swift-architecture-skill` |
| SK5 | `swiftui-design-principles`, `writing-for-interfaces`, `swift-concurrency-pro`, `swift-testing-pro`, `swift-architecture-skill` |
| SK6 | wszystkie powyższe jako bramka końcowa: `swiftui-design-principles` + `writing-for-interfaces` (celebracje/copy), `swift-concurrency-pro` (kolejka celebracji), `swift-testing-pro` (idempotencja), `swift-security-expert` + `core-data-expert` (audyt końcowy), `swift-api-design-guidelines-skill` |

## Dziennik sprintów

Szablon wpisu (kopiuj i wypełnij):

```
### Sprint SKN — <data>, agent

**Zrobione:** (lista plików utworzonych/zmienionych, jednym zdaniem co w każdym)
**Zastosowane skille:** (per skill: co konkretnie zastosowano; jeśli coś świadomie odrzucono — dlaczego)
**Odstępstwa od planu:** (co zrobiono inaczej niż w planie i dlaczego; „brak" jeśli nic)
**Decyzje podjęte w trakcie:** (np. copy, nazwy typów, progi kryteriów, mapowania placementu)
**Znane problemy / TODO:** (co zostawiono świadomie, co wymaga uwagi)
**Wskazówki dla następnego agenta:** (na co uważać, od czego zacząć)
**Do ręcznej weryfikacji przez użytkownika:** (build, testy, konkretne ścieżki smoke testu)
```

---

### Sprint SK1 — 2026-07-18, agent

**Zrobione:**
- `cali-park/Features/Exercises/Models/ExerciseMeasurement.swift` — nowy enum `reps`/`seconds` (`Codable`, `Sendable`, stabilne klucze) — miara serii per ćwiczenie.
- `cali-park/Features/Exercises/Models/Exercise.swift` — dodane `measurement` (default `.reps`) i `variantOf: UUID?` (default `nil`); własny `init(from:)` z `decodeIfPresent` + defaultami (wsteczna zgodność), `encode(to:)` syntezowany przez `CodingKeys`.
- `cali-park/Features/Exercises/Services/ExerciseCatalog.swift` — 46 wariantów dopisanych PO 19-tce (indeksy i UUID nietknięte), stałe UUID `…-020`…`…-065`, 6 statyk głównych (deska/L-sit/front/back lever/planche/flaga) przełączonych na `measurement: .seconds`, nowe `mainMovements` (filtr `variantOf == nil`).
- `cali-park/Features/Exercises/ViewModels/ExerciseLibraryViewModel.swift` — `displayedExercises` filtruje `variantOf == nil`; biblioteka i `ExercisePickerSheet` (reużywa VM) pokazują dokładnie 19 ruchów jak przed sprintem.
- `cali-park/Features/Skills/Models/` — `AdvancementCriterion` (`.setsOfReps`/`.setsOfHold` + `measurement`/`sets`), `ProgressionPathID` (enum String, 13 ścieżek), `ProgressionStep` (`exerciseID`, `criterion`, `equipment`, `isParallelTrack`), `ProgressionPath` (`id`, `name`, `symbolName`, `steps`, `recommendedBase`).
- `cali-park/Features/Skills/Services/ProgressionCatalog.swift` — 13 ścieżek 1:1 z `docs/PROGRESSIONS.md`, lookup `path(withID:)`.
- `docs/PROGRESSIONS.md` — dokument-prawda: wszystkie drabiny (szczeble, kryteria, sprzęt), źródła per ścieżka (RR/OG/FPU), wskazówki bazy jako niewiążące, zasady integralności, decyzje.
- Testy: `ExercisesDataTests` (rozmiar/mainMovements=19, stabilność `all[0]/[1]`, 19 UUID niezmienione, każdy `variantOf`→ruch główny, back-compat Codable bez nowych pól, statyki w sekundach), `ExerciseLibraryViewModelTests` (default = `mainMovements`, warianty ukryte), nowy `ProgressionCatalogTests` (+ `AdvancementCriterionTests`).

**Zastosowane skille:**
- `swift-api-design-guidelines-skill` — nazwy jasne w miejscu użycia (`mainMovements`, `path(withID:)`, `variantOf`), boole jako asercje (`isParallelTrack`), komentarze dokumentacyjne przy każdej nowej deklaracji, etykiety argumentów wg gramatyki. Enum `Measurement` świadomie nazwany `ExerciseMeasurement`, by nie kolidować z `Foundation.Measurement`.
- `writing-for-interfaces` — nazwy i opisy szczebli to docelowe copy PL: zwięzłe, konkretne, jedna myśl; terminy uznane (tuck, straddle, german hang) zostają jako terms of art, reszta po polsku; wskazówki bazy sformułowane jako neutralne adnotacje, nie warunki.
- `swift-testing-pro` — struktury nie klasy, `#expect`, testy parametryzowane `@Test(arguments:)` po ścieżkach/kryteriach, roundtripy Codable; zero timingu.
- `core-data-expert` (bramka persystencji) — świadomie ZERO Core Data/SwiftData: katalog i ścieżki to statyczny kod, postęp policzy się z logów w SK3. `PersistenceController` nietknięty. Nie było potrzeby STOP-a.
- `swift-architecture-skill` — bez nowych zależności/singletonów; katalogi statyczne jak istniejący `ExerciseCatalog`, DI niepotrzebne w SK1 (`ProgressionCatalog` nie wchodzi jeszcze do `AppEnvironment`).

**Odstępstwa od planu:**
- „Guma oporowa" zapisana jako `Resistance bands` (istniejący string w `Park.equipments`), nie nowy klucz PL — spójność z konwencją sprzętu. Odnotowane w `docs/PROGRESSIONS.md`.
- 46 wariantów (górna półka „~40–50"); łącznie 65 pozycji w katalogu, biblioteka nadal 19.

**Decyzje podjęte w trakcie:**
- Kryteria: dynamiczne `3×8` (RR), trudniejsze rep-rungi `3×5`/`3×3` (negatywy, jednostronne, przejścia MU); statyki `3×20 s` (OG), holdy wejściowe łatwiejsze `3×30 s`; markery opanowania — „pierwsze 5 s" (pełne dźwignie/flaga) i „pierwsze czyste" (strict MU). Wszystko udokumentowane.
- `ProgressionPathID` jako enum String (13 ścieżek) — stabilne klucze dla placementu (SK3) i kalibracji (SK4), `CaseIterable` do iteracji.
- Kryterium jest atrybutem szczebla, nie ścieżki — bo ścieżki mieszają miary (np. back lever: german hang w sek + skin the cat w powt.).
- Statyki główne (deska, L-sit, front/back lever, planche, flaga) dostały `measurement: .seconds` już teraz; nic tego jeszcze nie czyta (SetPad reps do SK2), więc runtime bez zmian.

**Znane problemy / TODO:**
- Warianty mają sensowne kategorie (basic/advanced/expert), ale nie wpływają na bibliotekę (są filtrowane) — kategoria wariantu jest tylko porządkowa.
- `ProgressionCatalog` nie jest podpięty do UI ani `AppEnvironment` (świadomie — SK3 dokłada silnik, SK5 UI).

**Wskazówki dla następnego agenta (SK2):**
- Zacznij od `docs/PROGRESSIONS.md` — to dokument-prawda; `measurement == .seconds` mają: deska, L-sit, front/back lever, planche, flaga + większość wariantów statyk (zwis, podpór na poręczach, german hang, żabka, podpór/stanie przy ścianie).
- `SetPad` ma czytać `exercise.measurement`; test back-compat Codable dla `Exercise` już jest — dołóż analogiczny dla `LoggedSet.durationSeconds`.
- Nie ruszaj UUID-ów 001–065 ani kolejności w `ExerciseCatalog.all` (`all[0]`=Podciągnięcia, `all[1]`=Pompki — zależą od tego testy i widoki).

**Do ręcznej weryfikacji przez użytkownika:**
- Build + testy w Xcode (nowy plik `ProgressionCatalogTests.swift` w targecie testowym — synchronized groups powinny podpiąć automatycznie; jeśli nie, dodać ręcznie).
- Smoke: zakładka Ćwiczenia wygląda identycznie jak przed sprintem (19 ruchów, ten sam picker w szybkim treningu i edytorze planu).
- Testy: `ExerciseCatalogTests`, `ExerciseLibraryViewModelTests`, `ProgressionCatalogTests`, `AdvancementCriterionTests` (+ regresja pozostałych — logi, plany, hero).

---

### Sprint SK2 — 2026-07-18, agent

**Zrobione:**
- `cali-park/Features/Exercises/Models/LoggedSet.swift` — nowe pole `durationSeconds: Int?` (opcjonalne → syntezowany `Codable` dekoduje brak klucza do `nil`, wstecznie zgodne jak `sessionID`); `init(value:measurement:)` (buduje serię z jednej wartości SetPada — reps albo sekundy, przy sekundach `reps = 1` jako techniczny znacznik jednego utrzymania); `isTimed`; `padValue(for:)` (wartość zwracana do SetPada przy edycji).
- `cali-park/Features/Exercises/Models/WorkoutLogEntry.swift` — `totalReps` liczy TYLKO serie repowe (utrzymania wykluczone), nowe `totalSeconds` i `isTimed` — sumy nie mieszają powtórzeń z sekundami.
- `cali-park/Features/Exercises/Models/SetLogFormat.swift` — nowy formatter: `breakdown(of:)` („6 + 6 + 8" / „3 × 20 s" przy równych / „20 + 15 + 20 s" przy różnych), `total(of:)` („20 powtórzeń" / „60 s"), `totals(reps:seconds:)` (łączy tylko obecne miary), `spokenBreakdown(of:)` (VoiceOver: „3 serie po 20 sekund").
- `cali-park/Core/Extensions/PolishPlural.swift` — `seconds(_:)` (odmiana „sekunda/sekundy/sekund" dla VoiceOver; na ekranie zostaje symbol „s").
- `cali-park/Features/Exercises/ViewModels/WorkoutLogViewModel.swift` + `SessionSetPadSheet` (w `QuickWorkoutView.swift`) — zapis serii przez `LoggedSet(value:measurement:)`; seed edycji przez `padValue(for:)`.
- `cali-park/Features/Exercises/Views/Components/SetPadEntryView.swift` — tryb sekund wg `exercise.measurement`: podtytuł „Liczysz sekundy utrzymania", sufiks „s" przy dużym wyświetlaczu, podsumowanie i etykieta dostępności zależne od miary; keypad i `SetPadInput` bez zmian.
- `cali-park/Features/Exercises/Views/WorkoutHistoryView.swift` + `WorkoutHistoryViewModel.swift` (`WorkoutHistorySection.totalSeconds`) — wiersze i nagłówek sesji przez `SetLogFormat`.
- `cali-park/Features/Home/…` — `HomeDashboardViewModel.LatestWorkout.totalSeconds`, `LastWorkoutModuleContent`, `HeroWorkoutSummary` przez `SetLogFormat` (sesja i pojedynczy wpis).
- `cali-parkTests/SetSecondsTests.swift` — nowy plik: konstrukcja repy/sekundy, back-compat Codable (`{"reps":6}` → `nil`), sumy repy/sekundy, `SetLogFormat` (parametryzowane), `PolishPlural.seconds`, oraz zapis „front lever 3 × 15 s" z `WorkoutLogViewModel` (sekundy, nie repy).

**Zastosowane skille:**
- `swift-api-design-guidelines-skill` — `init(value:measurement:)` zamiast fabryki `make…` (inicjalizator = „co tworzy"); `isTimed` jako asercja boolowska; `padValue(for:)` z etykietą przyimkową; komentarze dokumentacyjne przy każdej nowej deklaracji; `SetLogFormat` z jasnymi nazwami w miejscu użycia (`breakdown(of:)`, `total(of:)`, `totals(reps:seconds:)`).
- `swiftui-design-principles` — restraint: dołożyłem tylko podtytuł + sufiks „s" i podsumowanie, siatka 4/8 SetPada nietknięta; kolory semantyczne z AppTheme; bez `.font(.system(size:))` (jedyny istniejący `.system(.largeTitle, design:)` zostaje — to skala Dynamic Type, nie stały rozmiar); zero GeometryReader/stałych ramek.
- `writing-for-interfaces` — jednostka komunikowana jasno („s", „Liczysz sekundy utrzymania", „Każdy + to nowe utrzymanie"); dynamiczne stringi obsługują 0/1/wiele („0 powtórzeń", „3 × 20 s"); brak żargonu; symbol „s" niezmienny (jak „kg"), pełna odmiana tylko dla VoiceOver.
- `swift-testing-pro` — struktury nie klasy, `#expect`/`#require`, `@Test(arguments:)` dla form PL, formatów i `padValue`; stub `InMemoryWorkoutLogStore`; zero timingu (sekundy to dane, nie realny czas).
- `swift-architecture-skill` — MVVM zachowane: konwersja wartość→`LoggedSet` w VM/warstwie widoku z wstrzykniętym `store`; `SetLogFormat`/`PolishPlural` jako czyste, bezstanowe helpery; zero nowych zależności i singletonów; `SetPadInput` pozostaje czystym licznikiem liczb (zgodnie z planem).

**Odstępstwa od planu:**
- Formatowanie sekund realizuję prostym, deterministycznym „\(n) s" + `PolishPlural.seconds` dla VoiceOver, zamiast `Duration.UnitsFormatStyle`. Powód: `Duration` jest zależne od locale (kruche testy) i dawało „20 sek"/„20 s" niespójnie; plan dopuszczał „Text(_, format:) / Duration" jako sugestię, a wymagał dokładnego copy „20 s" / „3 × 20 s". Nadal ZERO formatów C-style.
- Zmieniłem semantykę `WorkoutLogEntry.totalReps` (teraz wyklucza utrzymania). Wstecznie bezpieczne: brak danych czasowych przed SK2, wszystkie istniejące testy (repy) przechodzą; regresja H1 nietknięta (`heroState`/`loggedTodayReps` bez zmian sygnatur).

**Decyzje podjęte w trakcie:**
- Kolaps „3 × 20 s" tylko gdy wszystkie utrzymania równe; różne → „20 + 15 + 20 s". Repy nadal zawsze „6 + 6 + 8" (brak kolapsu — identyczny wygląd jak przed sprintem).
- Sesja mieszana (repy + sekundy) w nagłówku i na Home: „N ćwiczeń · 40 powtórzeń · 60 s" (uczciwy rozdział miar).
- Timed set: `reps = 1` techniczne + `durationSeconds` = prawda. Dzięki temu liczba serii/utrzymań wynika z liczby elementów, a `totalReps` ich nie liczy.

**Znane problemy / TODO:**
- Plany (`PlannedExercise`) nie mają jeszcze celów w sekundach — `prefilledSets` dla ćwiczeń czasowych zostaje repowy (poza zakresem SK2; integracja planera to osobny plan). Seed edycji w sesji już respektuje miarę przez `padValue(for:)`.
- Hero „Zaczęte dziś: X powtórzeń" pokazuje tylko repy (plany są dziś repowe); dzień wyłącznie czasowy → linia ukryta. Do rozważenia w SK6 wraz z hero-kontekstem.
- `QuickWorkoutViewModel.DraftItem.totalReps` pozostaje (nieużywane po przejściu wiersza na `SetLogFormat`) — zostawione świadomie, bez zmiany zachowania modelu.

**Wskazówki dla następnego agenta (SK3):**
- Zliczając wolumen/XP z logów rozdzielaj miary: `WorkoutLogEntry.totalReps` (repy) vs `totalSeconds` (utrzymania) vs `isTimed`. Kryteria z `docs/PROGRESSIONS.md`: `.setsOfReps` porównuj z seriami repowymi, `.setsOfHold` z `durationSeconds`.
- `AdvancementCriterion` (SK1) już niesie `measurement`/`sets` — zestaw z `LoggedSet` per szczebel.
- Nie ruszaj `SetPadInput` (czysty licznik) ani UUID-ów katalogu; miara wynika z `Exercise.measurement`.

**Do ręcznej weryfikacji przez użytkownika:**
- Build + testy w Xcode (nowy plik `SetSecondsTests.swift` — synchronized groups powinny podpiąć automatycznie; jeśli nie, dodać do targetu testowego ręcznie).
- Smoke: otwórz statykę (np. Front lever / Plank) → SetPad pokazuje „Liczysz sekundy utrzymania" i sufiks „s" → zaloguj 15, +, 15, +, 15 → w historii widnieje „3 × 15 s", a nie „3 powtórzenia".
- Smoke: ćwiczenia repowe (Podciągnięcia) wyglądają i logują się identycznie jak przed sprintem („6 + 6 + 8", „20 powtórzeń").
- Regresja: `SetPadTests`, `QuickWorkoutTests`, `HomeHeroStateTests`, `ExercisesDataTests` (`totalRepsSumsAllSets` = 32) — bez zmian.

---

### Sprint SK3 — 2026-07-18, agent

**Zrobione:**
- `cali-park/Features/Skills/Models/SkillPlacement.swift` — deklarowany szczebel startowy per ścieżka (`declaredRungByPath: [ProgressionPathID: Int]`) + posiadany sprzęt + `declaredAt`; helpery `declaredRung(for:)`, `ownsEquipment(_:)`, `.empty`. `Codable`/`Sendable`.
- `cali-park/Features/Skills/Models/RungProgress.swift` — postęp do kryterium jednego szczebla (`bestValue` = najsłabsza z najlepszych `sets` serii w jednej sesji), `isMet`, `fractionComplete`, `targetSets`/`targetValue`.
- `cali-park/Features/Skills/Models/PathState.swift` — wyliczony stan ścieżki (rungCount, currentRungIndex, conqueredRungCount, currentProgress), `isComplete`, `isConquered(rungAt:)`, `isCurrent(rungAt:)`.
- `cali-park/Features/Skills/Models/PlayerLevel.swift` — poziom z XP (krzywa `500·(L-1)²`), `forXP(_:)`, `threshold(forLevel:)`, `xpToNextLevel`, `progressToNextLevel`.
- `cali-park/Features/Skills/Models/Badge.swift` — enum 6 odznak (statyczne copy PL: tytuł, wymaganie, `symbolName` w stylu Watch): `firstWorkout`, `tenTrainingDays`, `weekStreak`, `firstSkill`, `threeSkills`, `thousandReps`.
- `cali-park/Features/Skills/Models/RungReference.swift` + `SkillProgress.swift` — trwałe „uczczone" awanse (`Set<RungReference>` + `celebratedLevel`) dla idempotentnej celebracji (SK6).
- `cali-park/Features/Skills/Services/ProgressionEngine.swift` — czyste, deterministyczne funkcje statyczne: `pathStates(logs:placement:)`, `pathState(for:logs:placement:)`, `rungProgress(for:in:)`, `experiencePoints(for:)`, `playerLevel(for:)`, `earnedBadges(from:calendar:today:)`.
- `cali-park/Features/Skills/Services/SkillPlacementStore.swift` — `PlacementStoring` + `FileSkillPlacementStore` (JSON w `documentsDirectory`) + `InMemorySkillPlacementStore`.
- `cali-park/Features/Skills/Services/SkillProgressStore.swift` — `SkillProgressStoring` + File/InMemory.
- `cali-park/Features/Skills/Models/AdvancementCriterion.swift` — dodane `targetValue` (reps/sekundy, additive; silnik porównuje z nim `reps`/`durationSeconds`).
- `cali-park/Core/AppEnvironment.swift` — rejestracja `placementStore` i `skillProgressStore` (domyślnie File; `seeded(…, placement:)` wstrzykuje InMemory dla previews/SK5).
- `cali-parkTests/ProgressionEngineTests.swift` — testy: szczebel z logów (3×8 w jednej sesji vs rozbite), postęp do kryterium, kryteria czasowe (3×20 s vs 3×15 s), ukończenie ścieżki, max(deklaracja, logi) w obie strony, niezależność ścieżek („70 podciągnięć, zero muscle-upa"), XP wstecz (wolumen + bonus za szczeble), brak XP z deklaracji, progi poziomów (parametryzowane), odznaki (kalendarz UTC), roundtripy store'ów (JSON + File + InMemory).

**Zastosowane skille:**
- `swift-concurrency-pro` — silnik to czyste funkcje statyczne na typach wartościowych (zero stanu współdzielonego, zero wyścigów); da/kalendarz wstrzykiwane do `earnedBadges` dla determinizmu (wzorzec z `WorkoutStreak`); zero `DispatchQueue`. Store'y trzymają istniejący wzorzec projektu (`struct` File + `final class` InMemory za protokołem, dostęp przez `@MainActor AppEnvironment`) zamiast dodawać `actor` — spójność ze `WorkoutLogStore`/`WorkoutPlanStore`; brak asynchronicznego I/O, więc `actor` byłby niespójną nadmiarowością.
- `swift-security-expert` (bramka storage) — placement/progres/XP to NIE sekrety: JSON w `documentsDirectory` jest OK (świadoma decyzja). ZERO tokenów/credentials/kluczy w tych plikach i ZERO w UserDefaults; żadnych flag „premium" persystowanych lokalnie. Keychain niepotrzebny (brak sekretów w zakresie). Gdy wejdzie backend — tokeny wyłącznie Keychain (poza tym planem).
- `swift-api-design-guidelines-skill` — nazwy jasne w miejscu użycia (`pathStates(logs:placement:)`, `experiencePoints(for:)`, `earnedBadges(from:calendar:today:)`, `threshold(forLevel:)`, `declaredRung(for:)`); boole jako asercje (`isMet`, `isComplete`, `isConquered(rungAt:)`); komentarze dokumentacyjne przy każdej nowej deklaracji; `targetValue` dodane do kryterium jako naturalne, additive API.
- `swift-testing-pro` — struktury nie klasy, `#expect`/`try #require`, testy parametryzowane `@Test(arguments:)` (progi poziomów), fikstury bez timingu, kalendarz UTC + stałe „dziś" (odznaki streak deterministyczne), File store na unikatowym katalogu tymczasowym z `defer` cleanup.
- `core-data-expert` (bramka persystencji) — świadomie ZERO Core Data/SwiftData: statyczny katalog + JSON w plikach, progres liczony z logów. `PersistenceController` nietknięty. Bez STOP-a (bramka przeszła).
- `swift-architecture-skill` — MVVM/DI zachowane: nowe store'y za protokołami wstrzykiwane przez `AppEnvironment` (composition root), silnik bezstanowy jak `WorkoutStreak`/katalogi (nie wchodzi do DI, bo nie ma stanu), zero singletonów i nowych zależności.

**Odstępstwa od planu:**
- `earnedBadges` ma sygnaturę `(from:calendar:today:)`, nie planowane `(logs:pathStates:)`. Powód: odznaki muszą wynikać WYŁĄCZNIE z logów (deklaracja nie daje nagród), więc silnik sam liczy stany log-only (`placement: nil`) wewnątrz — brak ryzyka podania „napompowanych" placementem `pathStates`. Ta sama zasada co „placement nie daje XP".
- „Okno ostatnich sesji" z planu realizuję jako **najlepszą sesję z całej historii** (bez okna czasowego). Powód: zaliczony szczebel nie może się cofać po słabym tygodniu (plan wprost: „rekalibracja w dół nie kasuje szczebli zaliczonych z logów"), a to eliminuje zależność od kalendarza w `pathStates` → pełny determinizm. Kryterium nadal wymaga kompletu serii w JEDNEJ sesji (3×8 rozbite na 3 sesje = niezaliczone).

**Decyzje podjęte w trakcie:**
- Model XP: 10 XP/powtórzenie, 1 XP/sekunda holdu (holdy nabijają dużo sekund, więc niższa stawka), +100 XP za każdy szczebel zaliczony z logów. Krzywa poziomów: próg poziomu L = `500·(L-1)²` (L2=500, L3=2000, L4=4500 — szybkie wczesne poziomy, rosnące później). Stałe są `static let` w silniku/`PlayerLevel` — łatwe do strojenia w SK6.
- „Zaliczony przez logi" = najwyższy szczebel, którego kryterium spełniono w jednej sesji; wszystko poniżej liczy się jako zaliczone (jeśli robisz pełne podciągnięcia 3×8, negatywy masz z głowy — nie trzeba ich logować). `current = max(deklaracja, logi) + 1`, przycięte do szczytu.
- Postęp częściowy: gdy w sesji jest mniej serii niż wymaga kryterium, `bestValue = 0` (nie ma „3×coś" z 2 serii). Świadome i testowane.
- `SkillProgress` trzyma `Set<RungReference>` zamiast słownika enum→Set (czytelniejszy, type-safe roundtrip JSON).

**Znane problemy / TODO:**
- Bez placementu near-miss na ćwiczeniu wyższego szczebla (np. podciągnięcia 8/6/7 u świeżaka) pokazuje szczebel bazowy (dead hang), bo niższych szczebli nie zalogowano — to zamierzone: placement (SK4) ustawia punkt startowy, potem logujesz na swoim szczeblu. Test `currentRungProgress…` używa placementu, by to udokumentować.
- Silnik NIE jest jeszcze konsumowany przez UI (SK5) ani przez pętlę celebracji (SK6). `skillProgressStore` zarejestrowany, ale bez konsumenta (jak `reminderScheduler`).
- `Badge` niesie docelowe copy PL i symbole — SK6 renderuje sekcję odznak; kolejność/priorytet wyświetlania do ustalenia w SK6.

**Wskazówki dla następnego agenta (SK4):**
- Placement zapisujesz przez `AppEnvironment.placementStore` (`PlacementStoring`); mapowanie odpowiedzi liczbowych → indeks szczebla to `SkillPlacement.declaredRungByPath[pathID] = index` (0-based w `ProgressionPath.steps`). „Mam gumę" → `ownedEquipment.insert("Resistance bands")` (spójne z `Park.equipments`).
- Regresja do sprawdzenia w SK4: deklaracja NIE daje XP — `ProgressionEngine.experiencePoints(for:)` nie przyjmuje placementu (strukturalnie niemożliwe), jest test `declarationsNeverGrantXP`.
- „Ustaw poziom" w dół nie może kasować szczebli z logów — silnik już to gwarantuje (`max(deklaracja, logi)`), więc UI po prostu zapisuje nową deklarację.
- Indeksy szczebli są 0-based i stabilne (kolejność `ProgressionCatalog` = kolejność `docs/PROGRESSIONS.md`); mapowania w SK4 opieraj na `ProgressionCatalog.path(withID:)?.steps`.

**Do ręcznej weryfikacji przez użytkownika:**
- Build + testy w Xcode (nowy plik `ProgressionEngineTests.swift` w targecie testowym — synchronized groups powinny podpiąć automatycznie; jeśli nie, dodać ręcznie). Nowe pliki źródłowe w `Features/Skills/{Models,Services}` powinny podpiąć się same.
- Testy: `ProgressionEngineTests` (wszystkie suity) + regresja `ProgressionCatalogTests`/`AdvancementCriterionTests` (dodane `targetValue` nie zmienia istniejących), `SetSecondsTests`, `ExercisesDataTests`, `HomeHeroStateTests`.
- Zero zmian w UI (DoD SK3) — apka wygląda i działa jak po SK2; `AppEnvironment` ma dwa nowe store'y bez konsumentów.

---

### Sprint SK4 — 2026-07-18, agent

**Zrobione:**
- `cali-park/Features/Skills/Models/RepCountBucket.swift` — enum kubełków samooceny (`none`/`few`/`several`/`many`) z etykietami realnych liczb ("0", "1–4", "5–8", "9+"); ulotny input UI, nieperystowany.
- `cali-park/Features/Skills/Models/RepCountQuestion.swift` — model pytania liczbowego (1 na ścieżkę repową): `path`, `prompt`, `rungForBucket` (kubełek → szczebel 0-based) + `rung(for:)`.
- `cali-park/Features/Skills/Models/SkillQuestion.swift` — model checkboxa skilla: `id`, `path`, `label`, `rung` (>0, żeby deklaracja realnie przesuwała start).
- `cali-park/Features/Skills/Services/PlacementCalibration.swift` — **jedyne źródło mapowania** (współdzielone przez onboarding i sheet): 4 pytania repowe (podciąganie/pompki/dipy/przysiady) + 3 checkboxy (muscle-up, pełny L-sit, pistolet) + guma; reduktor `placement(repAnswers:masteredSkills:ownsBand:declaredAt:)` bierze **max szczebla per ścieżka** i odrzuca deklaracje rung-0 (no-op).
- `cali-park/Features/Skills/ViewModels/PlacementCalibrationViewModel.swift` — `@Observable @MainActor`: stan odpowiedzi, `select/toggleMastery`, `placement` (computed), `save()` przez `PlacementStoring`; wstrzykiwana data (`now:`) dla determinizmu; preload `ownsBand` z istniejącej deklaracji.
- `cali-park/Features/Skills/Views/PlacementFormView.swift` — reużywalny formularz (sekcje pytań repowych jako single-select, checkboxy skilli, toggle gumy); bez własnego ScrollView (kontener daje konsument), semantyczne kolory AppTheme, siatka 8/12/32, `clipShape(.rect(cornerRadius:))`, etykiety dostępności + `.isSelected`.
- `cali-park/Features/Skills/Views/PlacementCalibrationSheet.swift` — sheet kalibracji (NavigationStack + Anuluj/Zapisz + alert błędu + dismiss po zapisie). Punkty wejścia (pierwszy kontakt ze Skillami, „Ustaw poziom" w detalu ścieżki) podepnie SK5.
- `cali-park/Features/Onboarding/OnboardingView.swift` — strona „Jaki jest Twój poziom?" (3 atrapy, odpowiedź wyrzucana) → **„Co już potrafisz?"** z `PlacementFormView`; `init(environment:)` buduje VM; „Rozpocznij" zapisuje placement. Wyczyszczone deprecated API: `foregroundColor`→`foregroundStyle`, `cornerRadius`→`clipShape(.rect(cornerRadius:))`, `PageTabViewStyle`→`.page`, `SwitchToggleStyle(tint:)`→`.tint`, `PreviewProvider`→`#Preview`, `edgesIgnoringSafeArea`→`ignoresSafeArea`; hero-ikony na `@ScaledMetric` (Dynamic Type).
- `cali-park/Core/AppEnvironment.swift` — `makePlacementCalibrationViewModel()`.
- `cali-park/App/cali_parkApp.swift` — `OnboardingView(environment:)`.
- `cali-parkTests/PlacementCalibrationTests.swift` — mapowanie repowe (parametryzowane, 16 przypadków), skille, max-per-path (pistolet vs przysiady), guma, integralność (każdy szczebel = poprawny indeks; skille rung>0), save/load przez VM + preload gumy + błąd zapisu, regresja SK3 (deklaracja = 0 XP).

**Zastosowane skille:**
- `writing-for-interfaces` — pytania placementu to najważniejsze copy: jedna myśl na pytanie, realne liczby jako opcje ("0/1–4/5–8/9+"), zero żargonu w pytaniach ("Ile pełnych podciągnięć…"); tytuł strony „Co już potrafisz?" + jednozdaniowe „Zaczniesz od właściwego szczebla, nie od zera." (front-loaded benefit); komunikat błędu konkretny i bez „Ups". Odrzucone: em-dash w podtytule (skill: dashes przerywają skan) — rozbite na krótkie zdanie.
- `swiftui-design-principles` — restraint: single-select przez jeden stan (nie 4 toggle), pojedynczy boolean gumy jako `Toggle` z widoczną etykietą (nie `.labelsHidden()`); siatka 8/12/16/24/32; semantyczne kolory AppTheme; `clipShape(.rect(cornerRadius: 12))` (10–12 pt); zero GeometryReader/stałych ramek; `@ScaledMetric` zamiast twardego `.font(.system(size: 80))` na hero-ikonach; formularz bez własnego ScrollView (konsument = jeden kontener, brak zagnieżdżonego scrolla).
- `swift-testing-pro` — struktury nie klasy, `#expect`/`try #require`, parametryzacja przez `@Test(arguments:)` z nazwanym `RepCase: Sendable` (uniknięcie kruchej inferencji krotek z `Int?`), stub `FailingPlacementStore`, wstrzyknięta stała data (zero timingu).
- `swift-security-expert` (bramka storage) — potwierdzone: placement to dane treningowe, NIE sekrety. Zero tokenów/credentials/flag „premium" w plikach i UserDefaults; guma trzymana jako string sprzętu (`Resistance bands`), nie flaga uprawnień. Keychain niepotrzebny (brak sekretów w zakresie). Reużyto istniejący `FileSkillPlacementStore` (SK3) — brak nowego I/O.
- `swift-architecture-skill` — MVVM/DI jak w całym projekcie: VM `@Observable @MainActor` z wstrzykniętym `PlacementStoring`, fabryka w `AppEnvironment` (composition root), mapowanie jako czysta, bezstanowa warstwa (`PlacementCalibration`); zero singletonów i nowych zależności; `OnboardingView(environment:)` spójne z `MainTabView`.

**Odstępstwa od planu:**
- Plan wymieniał „tuck front lever" jako przykładowy checkbox skilla. Świadomie zastąpiony **pistoletem**: tuck front lever to szczebel 0 ścieżki `frontLever`, a deklaracja rung-0 jest w silniku tożsama z brakiem deklaracji (`max(0, logi)`) — byłaby no-opem. Wybrałem 3 checkboxy o realnym efekcie (rung>0): muscle-up (3), pełny L-sit (3), pistolet (5, czyli szczyt `legs`, którego pytanie o przysiady celowo nie kredytuje). Egzekwuje to test integralności (`rung > 0`).
- Onboarding pyta o kilka ścieżek (4 repowe + 3 skille), reszta ścieżek zostaje bez deklaracji i startuje od dołu — zgodnie z modelem (`SkillPlacement`: brak ścieżki = brak deklaracji), plan dopuszczał „kilka szybkich pytań".

**Decyzje podjęte w trakcie:**
- Mapowanie kubełków → szczeble (1:1 z `docs/PROGRESSIONS.md`, wszystko udokumentowane w `PlacementCalibration`): podciąganie none→2(negatywy)/few→4(pełne)/several→5(L-pull)/many→6(archer); pompki 2/3/4/5; dipy 1/2/2/3; przysiady 0/1/2/3 (pistolet celowo tylko z checkboxa, nie z liczby przysiadów dwunożnych).
- Reduktor bierze **max per ścieżka** gdy kilka odpowiedzi celuje w tę samą ścieżkę (pistolet vs przysiady → `legs`); spójne z zasadą silnika „wszystko poniżej aktualnego = zaliczone".
- Deklaracje rung-0 odrzucane w reduktorze (minimalna, sensowna mapa; identyczny efekt jak brak wpisu).
- Rekalibracja: sheet **zapisuje nową deklarację** (nie merge z poprzednią) — plan chroni tylko szczeble z LOGÓW (silnik `max(deklaracja, logi)`), a „rekalibracja w dół" jest zamierzona. Preload z poprzedniej deklaracji ograniczony do gumy (jednoznaczny); kubełki/skille nie są rekonstruowane (rung→kubełek jest niejednoznaczne) — świadomie, patrz TODO.
- Copy: „Ustaw poziom" jako nazwa sheetu i (docelowo) CTA w detalu ścieżki — jeden wzorzec językowy dla kalibracji.

**Znane problemy / TODO:**
- Sheet kalibracji przy rekalibracji nie prezaznacza wcześniejszych odpowiedzi repowych/skilli (tylko gumę). Świadomie — mapowanie rung→kubełek jest stratne. Jeśli SK5/SK6 zechce prezaznaczać, dodać czysty `PlacementCalibration.selection(from:)` (odwrotne, deterministyczne dopasowanie po dokładnym szczeblu) + testy.
- „Ustaw poziom" per ścieżka (detal ścieżki) i „pierwszy kontakt ze Skillami bez placementu" — sheet gotowy i reużywalny, ale **punkty wejścia podpina SK5** (zakładka Skille jeszcze nie istnieje — to Społeczność do SK5). Nie ruszałem `MainTabView`.
- Strona celów onboardingu nadal nie persystuje wyboru (jak przed planem) — poza zakresem SK4; plan mówił „strona celów zostaje".
- `PlacementCalibrationSheet` i `PlacementFormView` nie mają jeszcze konsumenta w runtime poza onboardingiem (previews działają) — SK5 je zamontuje.

**Wskazówki dla następnego agenta (SK5):**
- Placement czytasz/piszesz przez `AppEnvironment.placementStore`; VM buduj `environment.makePlacementCalibrationViewModel()`. Do kalibracji w apce prezentuj `PlacementCalibrationSheet(viewModel:)`.
- Pierwszy kontakt ze Skillami bez placementu: `placementStore.load() == nil` → pokaż sheet (istniejący użytkownicy nie przechodzą onboardingu ponownie). „Ustaw poziom" w `PathDetailView` → ten sam sheet.
- Stany ścieżek do UI bierz z `ProgressionEngine.pathStates(logs:placement:)` (SK3); po zapisie placementu odśwież stan (przeładuj z `placementStore`).
- Kolejność/etykiety pytań i mapowanie są w `PlacementCalibration` (jedno źródło) — nie duplikuj w UI.

**Do ręcznej weryfikacji przez użytkownika:**
- Build + testy w Xcode (nowe pliki w `Features/Skills/{Models,ViewModels,Services,Views}` i `cali-parkTests/PlacementCalibrationTests.swift` — synchronized groups powinny podpiąć automatycznie; jeśli nie, dodać ręcznie).
- Testy: `PlacementCalibrationTests` (wszystkie suity) + regresja `ProgressionEngineTests` (`declarationsNeverGrantXP`), `ProgressionCatalogTests`, `SetSecondsTests`, `ExercisesDataTests`, `HomeHeroStateTests`.
- Smoke (świeży użytkownik): onboarding → strona „Co już potrafisz?" → zaznacz np. podciąganie „9+", muscle-up, „Mam gumę oporową" → „Rozpocznij" → w `skill-placement.json` (documents) zapisany placement (pullUp=6, muscleUp=3, guma). (Zakładka Skille pokaże właściwe szczeble dopiero po SK5.)
- Smoke (regres onboardingu): strony Witaj / Cele / Lokalizacja wyglądają jak przed sprintem; Dynamic Type nie psuje hero-ikon (skalują się).

---

### Sprint SK5 — 2026-07-18, agent

**Zrobione:**
- `cali-park/Features/Skills/Models/SkillPathSummary.swift` — model prezentacji: `ProgressionPath` + wyliczony `PathState` w jednej wartości (`currentStep`, `currentProgress`); `Identifiable`/`Equatable`/`Sendable`, wyłącznie derived (nieperystowany).
- `cali-park/Features/Skills/Services/ProgressionFormat.swift` — czysty formatter copy: `criterion` („3 × 8", „3 × 20 s", markery „pierwsze czyste" / „pierwsze 5 s"), `best`, `progressLine` („3 × 8 — Twoje najlepsze: 3 × 6"), `equipment` („Masa ciała" gdy brak), `spokenCriterion` (VoiceOver: „3 serie po 20 sekund"). Symbol „s" niezmienny, pełna odmiana tylko dla VoiceOver.
- `cali-park/Features/Skills/Services/ProgressionCatalog.swift` — nowy lookup `paths(containing:)` (ścieżki zawierające dany ruch — link „Progresje" w detalu ruchu).
- `cali-park/Features/Exercises/Services/ExerciseCatalog.swift` — nowy `variants(of:)` (warianty ruchu w kolejności katalogu, drill-in w pickerze).
- `cali-park/Features/Skills/ViewModels/SkillPathsViewModel.swift` — `@Observable @MainActor`: `summaries` (13 ścieżek z `ProgressionEngine.pathStates`), `level` (`playerLevel`), `hasPlacement`, `recentlyAdvancedPaths` (diff conquered między loadami — hook dla SK6), `summary(for:)`, `rungProgress(for:)`; ładowanie synchroniczne (store'y synchroniczne, jak `HomeDashboardViewModel`).
- `cali-park/Features/Skills/Views/SkillPathsView.swift` — przegląd: nagłówek poziomu + pasek XP (`contentTransition(.numericText())`), siatka kart ścieżek (`LazyVGrid` 2 kol.), prompt kalibracji przy pierwszym kontakcie bez placementu (auto-sheet raz + banner + toolbar „Ustaw poziom"), `navigationDestination(for: ProgressionPathID.self)`. 3 previews (świeżak / placement średni / weteran).
- `cali-park/Features/Skills/Views/PathDetailView.swift` — pionowa drabina (`RungRail` timeline: marker + ciągła linia, ring postępu na aktualnym), stany zaliczony/aktualny/przyszły BEZ kłódek (przyszłe przygaszone, ale tapowalne), niewiążąca notka bazy (`recommendedBase`), „Ustaw poziom". Reload po zamknięciu sheetu treningu/kalibracji.
- `cali-park/Features/Skills/Views/StepDetailSheetView.swift` — detal szczebla: ikona + opis, „Cel" + `progressLine`, sprzęt, „Jak wykonać" (technika z katalogu), CTA **„Trenuj"** → `SetPadSheetView` (miara reps/sekundy wg `exercise.measurement` z SK2).
- `cali-park/Features/Main/MainTabView.swift` — zakładka `Społeczność` → **`Skille`** (`trophy.fill`, nowe Tab API); `CommunityView` zostaje w repo, znika z tab bara.
- `cali-park/Core/AppEnvironment.swift` — `makeSkillPathsViewModel()` + preview `skillsVeteran` (kilka drabin dynamicznych zaliczonych z logów + front lever w połowie).
- `cali-park/Features/Exercises/Views/ExerciseDetailView.swift` — zwięzła sekcja „Progresje" (link do drabiny ścieżki przez `ProgressionPathID`, nie lista wariantów inline).
- `cali-park/Features/Exercises/Views/ExerciseLibraryView.swift` — `navigationDestination(for: ProgressionPathID.self)` → `PathDetailView` (wejście z detalu ruchu).
- `cali-park/Features/Exercises/Views/ExercisePickerSheet.swift` — wiersz ruchu z wariantami dostaje disclosure → `VariantPickerView` (drill-in konkretnego wariantu); ruchy bez wariantów wybierają się jednym tapnięciem jak dotąd.
- `cali-parkTests/SkillPathsViewModelTests.swift` — testy: `ProgressionFormat` (kryteria/best/progressLine/sprzęt/VoiceOver), `advances(from:to:)` (pierwszy load nie świętuje, wzrost conquered = awans, brak zmian = brak), mapowanie VM (świeżak od dołu, placement ustawia szczebel, logi awansują + poziom, `rungProgress` per szczebel, reload po treningu wykrywa świeży awans).

**Zastosowane skille:**
- `swiftui-design-principles` — siatka 4/8/12/16/24, kolory semantyczne z AppTheme, karty `componentBackground` + `clipShape(.rect(cornerRadius: 12))`, ring aktualnego szczebla ma tę samą grubość tła i wypełnienia (3 pt), zero GeometryReader/stałych ramek (drabina przez layout HStack/VStack + rozciągana linia rail, `contentTransition(.numericText())` na poziomie i XP). `ProgressView(value:)` zamiast ręcznego rysowania paska. Restraint: jedna informacja na wiersz.
- `writing-for-interfaces` — copy stanów szczebla („Zaliczone", „Trenujesz teraz"), kryterium z realnym postępem („3 × 8 — Twoje najlepsze: 3 × 6"), CTA „Trenuj"/„Ustaw poziom" (spójny wzorzec z SK4), notka bazy jako neutralna adnotacja (info.circle, nigdy warunek), „Zaloguj serię, aby zmierzyć postęp" gdy brak zapisów; zero żargonu poza terms of art; brak em-dash w UI poza „—" łączącym cel z najlepszym (celowo, czytelny separator).
- `swift-concurrency-pro` — `load()` synchroniczne, bo store'y są synchroniczne (JSON/InMemory) — brak async I/O, więc brak `Task`/anulowania (spójne z `HomeDashboardViewModel`); silnik to czyste funkcje statyczne; `advances(from:to:)` czysta funkcja statyczna, deterministyczna; zero `DispatchQueue`. Świadomie NIE dodawałem uchwytów zadań tam, gdzie nie ma zadań.
- `swift-testing-pro` — struktury nie klasy, `#expect`/`#require`, `@MainActor` na suitach dotykających VM, store'y InMemory jako stuby, zero timingu; `ProgressionFormat` testowany bez `@MainActor` (czysty).
- `swift-architecture-skill` — MVVM/DI jak w całym projekcie: VM za fabryką w `AppEnvironment`, widoki tworzą VM przez `@State` + `environment.make…`, formatter/summary jako czyste warstwy; jeden VM (`SkillPathsViewModel`) obsługuje przegląd i detal (bez mnożenia typów), reużyty przez oba wejścia (Skille + detal ruchu).

**Odstępstwa od planu:**
- Detal ścieżki reużywa `SkillPathsViewModel` (świeża instancja per ekran) zamiast osobnego `PathDetailViewModel` — plan nazwał tylko `SkillPathsViewModel`; jeden VM liczy wszystkie ścieżki tanio, a detal bierze `summary(for:)`/`rungProgress(for:)`. Działa z obu wejść (zakładka Skille + „Progresje" w detalu ruchu bez instancji z zakładki).
- „Świeże awanse" zrealizowane jako czysty diff `conquered` między dwoma snapshotami (`advances(from:to:)`), bez persystencji „uczczonych" — to należy do SK6 (kolejka celebracji + `SkillProgressStore`). SK5 daje tylko hook + test.

**Decyzje podjęte w trakcie:**
- Ikona zakładki: `trophy.fill` (skille + docelowo odznaki z SK6).
- Rail drabiny: marker (checkmark/ring/okrąg) + ciągła linia z dwóch rozciąganych prostokątów — bez GeometryReader; kolor linii akcent do zaliczonych, `divider` dalej.
- Pierwszy kontakt bez placementu: auto-sheet raz na cykl życia widoku (`hasOfferedCalibration`) + trwały banner i przycisk w toolbarze — nie nagabuje po anulowaniu, ale zostaje łatwo dostępny.
- Copy poziomu: „Poziom N" + „X XP do poziomu N+1" (krzywa bez maksimum, więc zawsze jest następny poziom).
- Drill-in wariantów: disclosure (chevron) tylko dla ruchów z wariantami; ruch bez wariantów = jeden tap (jak dotąd) — „jeden dodatkowy krok tylko dla tych, którzy go potrzebują".

**Znane problemy / TODO:**
- Celebracja awansu, XP toast, sekcja odznak, realny moduł osiągnięć na Home, hero-kontekst i wyłączenie atrap leaderboard/feed — całość SK6. `recentlyAdvancedPaths` czeka jako hook; `skillProgressStore` (SK3) nadal bez konsumenta.
- `AchievementsModuleContent` (Home) nadal hardkoduje „12/30" — do podmiany w SK6.
- `CommunityView` pozostaje w repo (poza tab barem) — wróci z backendem.
- Detal ścieżki i przegląd liczą stan niezależnie (dwie instancje VM); po SK6 warto rozważyć wspólny strumień, jeśli celebracja ma reagować natychmiast między ekranami.

**Wskazówki dla następnego agenta (SK6):**
- Hook awansów: `SkillPathsViewModel.recentlyAdvancedPaths` (diff po `load()`); do idempotencji użyj `skillProgressStore` (SK3, `RungReference`/`celebratedLevel`) — celebruj tylko awanse z LOGÓW, nie z deklaracji (placement nie rusza XP ani odznak — patrz `ProgressionEngine`).
- Odznaki: `ProgressionEngine.earnedBadges(from:calendar:today:)` + `Badge` (copy/symbole gotowe) — sekcję wepnij w `SkillPathsView`.
- Poziom/XP do Home: `ProgressionEngine.playerLevel(for:)`; `AchievementsModuleContent` podmień na realne dane, tap → zakładka Skille (indeks 3 w `MainTabView`).
- Nie ruszaj miary SetPada — `StepDetailSheetView` CTA „Trenuj" już wybiera reps/sekundy wg `exercise.measurement`.
- Reduce Motion i idempotencja celebracji (jeden strumień zdarzeń, nie rozproszone boole) — patrz `swift-concurrency-pro`.

**Do ręcznej weryfikacji przez użytkownika:**
- Build + testy w Xcode (nowe pliki w `Features/Skills/{Models,ViewModels,Services,Views}` i `cali-parkTests/SkillPathsViewModelTests.swift` — synchronized groups powinny podpiąć automatycznie; jeśli nie, dodać ręcznie).
- Testy: `SkillPathsViewModelTests` (wszystkie suity) + regresja `ProgressionEngineTests`, `ProgressionCatalogTests`, `PlacementCalibrationTests`, `SetSecondsTests`, `ExercisesDataTests`, `ExerciseLibraryViewModelTests`, `HomeHeroStateTests`.
- Smoke (świeżak): zakładka **Skille** → auto-sheet „Ustaw poziom" → zadeklaruj np. podciąganie „9+" → karty pokazują właściwe szczeble; wejdź w Podciąganie → drabina bez kłódek, aktualny szczebel z ringiem; tap na szczebel → detal → „Trenuj" → zaloguj 3×8 → po powrocie drabina i XP zaktualizowane.
- Smoke (statyka sekundowa): wejdź np. w Front lever → szczebel „Tuck front lever" → „Trenuj" → SetPad w trybie sekund („Liczysz sekundy utrzymania").
- Smoke (warianty bez bałaganu): zakładka Ćwiczenia nadal 19 ruchów; detal np. Podciągnięcia → sekcja „Progresje" prowadzi do drabiny; „Szybki trening" → picker → przy ruchu z wariantami chevron → lista wariantów (np. „Negatywy podciągnięć") → wybór loguje wariant.
- Dostępność: VoiceOver czyta karty i szczeble („… Cel: 3 serie po 8 powtórzeń"); brak ikon kłódek; Dynamic Type nie łamie układu.
