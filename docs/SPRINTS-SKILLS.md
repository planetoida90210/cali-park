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
| SK2 | Sekundy w dzienniku: `LoggedSet.durationSeconds` (wstecznie zgodny), SetPad w trybie sekund wg `exercise.measurement`, historia/podsumowania „3 × 20 s", testy Codable back-compat + odmiana PL | oczekuje | — |
| SK3 | Silnik + placement (bez UI): ProgressionEngine (stany ścieżek z logów + deklaracji, ścieżki w pełni niezależne), SkillPlacement + PlacementStoring, XP/poziomy wstecz z historii, odznaki, SkillProgressStore, testy parametryzowane | oczekuje | — |
| SK4 | Placement UI: przebudowa strony poziomu w OnboardingView na placement per ścieżka (pytania liczbowe + skille + guma), arkusz kalibracji w apce, testy mapowania odpowiedzi → szczeble | oczekuje | — |
| SK5 | Zakładka Skille zamiast Społeczności: SkillPathsView (poziom + XP + karty ścieżek), PathDetailView (drabina, bez kłódek), StepDetailSheetView (kryterium + postęp + CTA Trenuj), sekcja „Progresje" w detalu ruchu, drill-in wariantów w pickerze, previews, testy VM | oczekuje | — |
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
