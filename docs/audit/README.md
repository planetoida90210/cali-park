# Audyt CaliPark, 2026-11-03

Audyt objął 7 obszarów: logikę Skills, logikę treningów i planera, trwałość danych, współbieżność i Swift 6, SwiftUI/UX/dostępność, architekturę oraz gotowość produkcyjną. Każdy obszar przeczytał jeden agent, a drugi próbował obalić każde znalezisko w kodzie. **136 znalezisk przeszło weryfikację i żadne nie zostało obalone.** 40 z nich potwierdzono częściowo, z obniżoną wagą albo węższym zakresem. Weryfikatorzy dodali 5 własnych. Wiele znalezisk to ten sam problem wyłapany przez kilka obszarów, więc niżej są pogrupowane. Sam raport też przeszedł niezależną kontrolę zgodności ze znaleziskami.

- Szczegóły każdego znaleziska z dowodem, skutkiem i fixem są w [findings.md](findings.md). Identyfikatory `A-1`, `B-2` prowadzą tam, a `X-V1` to znaleziska dodane przez weryfikatora.
- Research skilli Swift dla Claude Code: [skills-research.md](skills-research.md).

**Latentne** oznacza bug obecny w kodzie, którego dziś nic nie wyzwala. Odpali się dopiero przy zmianie modelu, backendzie albo Premium.

## Stan wyjściowy

| | |
|---|---|
| Build (Swift 5, Debug) | ✅ przechodzi, 0 warningów |
| Testy jednostkowe | ✅ 512/512 (270 testów + parametryzowane), Swift Testing, w większości deterministyczne (kilka zależy od zegara, G-20) |
| Build w trybie Swift 6 (strict concurrency) | ❌ pada; pierwsze błędy są w Parks (`Park.mock`/publiczny `ParkTag`, `static var defaultValue` w PreferenceKey) |
| Gotowość do App Store | ❌ jest bloker uploadu i ryzyka review (niżej) |

## Co jest dobre

- Katalog progresji zgadza się 1:1 z `docs/PROGRESSIONS.md`: 64 unikalne ID, zero duplikatów UUID. Formuły XP i poziomów są poprawne.
- Parsowanie SetPada, mapowanie dni tygodnia i liczenie streaka są poprawne. Według analizy kodu dotyczy to też zmiany czasu (DST), ale testów na DST brak (B-16).
- Nowsze moduły (Home dashboard, Ćwiczenia, Planer, Ścieżki) są nowoczesne: `@Observable` + `@MainActor`, API `Tab`, `navigationDestination`, dwuargumentowe `onChange`, podgląd przy każdym widoku.
- Zapisy na dysk są atomowe, a cały dostęp do danych idzie przez main actor, więc nie ma wyścigów między wątkami.
- Testy domeny są porządne: wstrzyknięty kalendarz UTC, katalogi tymczasowe, żadnego `UserDefaults.standard`.

Pod względem stylu apka ma dwie połowy. Nowsze moduły są zrobione nowocześnie. Parks, Profile, Community i moduły zastępcze na Home to starszy kod na mockach i tam siedzi większość naruszeń reguł oraz blokerów Swift 6. **Najpoważniejsze bugi (dane, nagrody, Home) są jednak w nowszej połowie.**

---

## P0: dane i zaufanie użytkownika

| # | Problem | Znaleziska | Wysiłek |
|---|---|---|---|
| 1 | **Ryzyko cichego wipe'u dziennika (latentne).** Store'y dziennika i planów przy błędzie odczytu lub dekodowania zwracają pustą listę (`(try? decode) ?? []`). Następny zapis nadpisuje plik tą pustą listą plus nowym wpisem. Dziś nic tego nie wyzwala, ale pierwsza niekompatybilna zmiana modelu albo jeden uszkodzony rekord skasuje całą historię lub plany bez komunikatu. Store'y placementu i postępu też połykają błąd i zwracają `nil`, co kończy się ponowną kalibracją albo cichym resetem celebracji. Żaden z tych błędów nie jest nigdzie logowany. | B-2, C-1, D-4, F-1, G-4, G-10 | M |
| 2 | **Trening w trakcie znika** po swipe-down albo „Anuluj”, bez pytania. To samo dotyczy edytora planu i SetPada. | B-1, E-3 | S |
| 3 | **Rekalibracja kasuje deklaracje.** „Ustaw poziom”, także wywołane z jednej ścieżki, otwiera pusty formularz całej kalibracji i zapisuje tylko ścieżki odpowiedziane w tej sesji. Pozostałe zadeklarowane poziomy startowe znikają. Postępy z logów zostają. | A-1, C-6 | M |
| 4 | **Fałszywe celebracje i XP.** Po obniżeniu poziomu stare szczeble świętują się drugi raz z „+100 XP”. Celebracja jest oznaczana jako pokazana już w chwili, gdy trafia do kolejki. Pokazywane XP nie zgadza się z faktycznym przyrostem, a toast XP pojawia się podwójnie. | A-2, A-4, A-10, C-7, F-4, D-V1 | S–M |
| 5 | **Guma jako obowiązkowy szczebel.** Silnik ignoruje `isParallelTrack`, więc początkujący bez gumy dostaje „Podciągnięcia z gumą” jako następny krok. Odpowiedź „Mam gumę” niczego nie zmienia. | A-3 | M |
| 6 | **Home pokazuje nieaktualny stan.** Bez odświeżania przez `scenePhase` „dziś” zatrzymuje się po północy. Niezależnie od tego wybór planu ignoruje ukończenie: zrobiony plan dalej ma „Dziś · Rozpocznij”, a drugi plan tego samego dnia jest nieosiągalny. Trening usunięty z podsumowania szybkiego treningu uruchomionego z Home wisi na Home do zmiany zakładki. | B-3, D-17, B-5, B-4 | S–M |

## P0: App Store

**Bloker uploadu:**

| # | Problem | Znaleziska |
|---|---|---|
| 7 | **Brak `PrivacyInfo.xcprivacy`.** Apka używa `UserDefaults`, czyli API z wymaganym powodem, a App Store Connect odrzuca taki upload (ITMS-91053). | C-2, G-1 |

**Ryzyka review** (wytyczne 2.1, 2.3, 3.1.1, 5.1.1):

| # | Problem | Znaleziska |
|---|---|---|
| 8 | **Mocki w produkcji.** Każdy użytkownik to „Michał” z wpisanym na sztywno celem tygodniowym. Na Home domyślnie włączony jest moduł z fałszywą pogodą i parkami z Warszawy (widać go po rozwinięciu). Parki to mock z 15 fałszywymi opiniami na park („do testu paginacji”). Zdjęcia są hotlinkowane z Unsplash. „Tłok” jest losowany przy każdym renderze. Dołączanie do wydarzeń woła udawany `CalendarService`. „Premium” istnieje bez StoreKit. „Najbliżej” liczy się od sztywnego punktu w Warszawie. Profil to 6 martwych wierszy, w tym „Wyloguj”. Onboarding nie zapisuje wybranych celów, a przełącznik lokalizacji nic nie robi. | E-2, F-2, G-2, E-4, G-5, C-3, E-7, G-V1, G-V2, C-V1, F-V1 |
| 9 | **Opisy uprawnień i konfiguracja.** Opis zapisu do biblioteki zdjęć nie ma żadnego użycia. Opis aparatu dotyczy przepływu za nieosiągalnym Premium, a sam aparat nie sprawdza dostępności (crash na Symulatorze). Lokalizacji używa tylko przycisk na mapie. iPhone ma włączony landscape, a apka jest Universal (iPad) bez layoutów pod iPada. Do uporządkowania są też bundle ID, nazwa i wersjonowanie. | G-6, E-27, G-11, G-24 |

**Jakość przed wydaniem** (nie blokuje review, ale widać to od pierwszego dnia):

| # | Problem | Znaleziska |
|---|---|---|
| 10 | **Brak lokalizacji.** Region deweloperski to `en` i nie ma String Catalog. Na polskim telefonie daty i dni tygodnia wychodzą po angielsku w środku polskiego UI, a App Store pokaże język jako angielski. | G-3, E-14 |
| 11 | **Dostępność.** `AppTheme` nadpisuje style tekstu SwiftUI stałymi rozmiarami, więc Dynamic Type nie działa w całej apce. Do tego 12× `onTapGesture` zamiast `Button`, 15 przycisków-ikon bez etykiety, przeciąganie modułów bez alternatywy, wymuszony ciemny motyw i kontrast poniżej WCAG AA. | E-1, F-10, E-10, E-11, E-12, E-13, E-15 |

## P1: dane długoterminowo

- **Brak wersjonowania formatu plików** (C-4). Blokuje bezpieczne zmiany schematu, patrz #1.
- Deklaracje poziomu i rekord celebracji trzymają **indeks szczebla**. Wstawienie, usunięcie albo przestawienie szczebla w drabinie po cichu przesunie te zapisy. Dziś to ryzyko latentne (A-6, C-5). Wcześniejsza zmiana mapowania kubełków nie zmigrowała zapisanych placementów (A-7).
- **Edytor planu gubi `reminderTime`** przy zapisie, bo przebudowuje plan od zera. To latentne, bo dziś nic nie ustawia `reminderTime`. Naprawić przed Sprintem 2 (przypomnienia), razem z `WorkoutPlanService` (B-6, C-13, F-5, G-17).
- **Diagnostyka.** W całej apce jest jeden `Logger`, każdy `catch` gubi błąd i nie ma MetricKit (G-10).

## P1: Swift 6 i struktura kodu

**Swift 6.** Pełna ścieżka migracji jest w podsumowaniu sekcji D w [findings.md](findings.md). W skrócie:
1. Na Swift 5 ustawić `SWIFT_STRICT_CONCURRENCY=complete`, `SWIFT_APPROACHABLE_CONCURRENCY=YES` i `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`.
2. Naprawić 2 trywialne blokery: `ParkTag`/`Park.mock` i `static var defaultValue` w PreferenceKey. Martwe Core Data usunąć przy okazji; to porządek, nie bloker.
3. Oznaczyć protokoły serwisów jako `Sendable`.
4. Oznaczyć czystą warstwę domeny jako `nonisolated`: modele Parks, `ProgressionEngine`, `RewardEvaluator`, katalogi, `WorkoutReminderPlanner`. Bez tego domyślna izolacja MainActor zepsuje aktory-stuby i testy silnika.
5. Zmigrować 8 typów `ObservableObject` na `@Observable`.
6. Zastąpić `DispatchQueue` i `Task.sleep(nanoseconds:)`.
7. Naprawić reentrancy join/leave w `ParkEventsViewModel` (D-5).
8. Przenieść I/O poza `init` view modeli.
9. Przełączyć `SWIFT_VERSION=6`.

Znaleziska: D-1…D-19, G-19.

**Struktura kodu** (analiza w stylu `/code-structure`). Ta sama logika operacyjna jest skopiowana do wielu przepływów. Kilka bugów z P0 wynika wprost z tych kopii.

| Zduplikowana operacja | Gdzie | Docelowo |
|---|---|---|
| load → mutate → save pliku JSON | store'y dziennika i planów (wipe), placement i postęp (połykanie błędów) | `JSONFileStore<Value>`: rzuca błąd przy uszkodzonym pliku, odkłada kopię uszkodzonego pliku, zapisuje wersjonowaną kopertę, loguje |
| „zaloguj trening” (zbuduj wpis, dopisz, przelicz serie, odśwież) | SetPad, Quick Workout, StepDetail, Home | `TrainingJournal` (`@Observable`, jedna instancja): `log`, `logSession`, `delete(ids:)`, `revision` |
| postęp z logów i pętla nagród (XP, celebracje) | osobny `SkillPathsViewModel` na każdy ekran, Home przy każdym renderze | `ProgressService` (snapshot liczony raz na każdą zmianę `revision` dziennika) + jeden `RewardCenter` na całą apkę |
| zmiana planu → przypomnienia | brak punktu orkiestracji | `WorkoutPlanService` (save/delete + reschedule) |
| formatowanie serii i kryteriów | `SetLogFormat`, `ProgressionFormat`, widoki | jeden `MeasureFormat` |

Znaleziska: F-1, F-3, F-4, F-5, F-6, F-13, A-11.

Do tego:
- Parks działa na drugiej, starszej architekturze (F-9).
- `AppEnvironment` jest `ObservableObject`, który nic nie publikuje, a środowiska podglądów są w kodzie produkcyjnym (F-7, D-12).
- Jest martwy kod: Core Data, cały nieużywany feature, nieosiągalne moduły (F-12, C-10, G-25).
- `ExerciseCatalog` to 1180 linii danych wpisanych w kod (F-11).
- 44 pliki mają po kilka typów (F-15).

Docelowy układ folderów to `App/`, `Domain/`, `Services/`, `Features/<X>/{Views,ViewModels}`, `DesignSystem/` i `PreviewSupport/` (`#if DEBUG`). Szczegóły są w sekcji F w [findings.md](findings.md).

## P2: narzędzia i testy

- Brak CI. Każdy dokument sprintu zabraniał też agentom uruchamiać `xcodebuild`, więc nikt automatycznie nie sprawdzał buildu ani testów (G-7). Zakaz jest już zdjęty w `CLAUDE.md`.
- Brak SwiftLint/SwiftFormat. Reguły istnieją tylko jako proza i są szeroko łamane: 122× `foregroundColor`, 11× `cornerRadius` (G-18, E-23…E-25).
- Brak współdzielonego schematu i test planu. UI testy to nietknięty szablon Xcode (G-15, G-16).
- Ryzykowny kod bez testów: Parks VM, preferencje modułów i prawdziwy scheduler (G-14). Testy kompatybilności Codable nie używają formatu z dysku (G-13). Asercje mogą wywalić cały proces testów (G-12).
- `project-rules.mdc` wprowadza w błąd co do domyślnej izolacji `MainActor` w tym projekcie (G-9). Korekta jest w `CLAUDE.md`.
- Claude Code nie widział ani reguł z `.cursor/rules`, ani skilli z `.agents/skills` (G-8). **Częściowo naprawione 2026-11-03:**
  - `CLAUDE.md` importuje reguły.
  - Skille Swift są podlinkowane lokalnie w `.claude/skills/`, łącznie z nowym SwiftUI Pro.
  - Skille nadal są gitignorowane, więc świeży klon ich nie ma.
- Nagłówek parku liczy paralaksę w globalnych współrzędnych i stosuje ją dwa razy. Wiersz wydarzenia ucina się przy większym tekście (E-18).

## Drobniejsze bugi warte szybkiego fixa

- Ćwiczenie dodane drugi raz w tym samym szybkim treningu nie liczy się do awansu, bo silnik ocenia wpisy, a nie sesje (A-5).
- Wyszukiwarka parków kasuje spację wpisaną na końcu, więc nazwy z kilku słów nie da się normalnie wpisać (D-9, E-5).
- Pull-to-refresh wydarzeń kasuje zapisy na wydarzenia (E-9).
- Arkusz szczebla pokazuje nieaktualny wynik po treningu (A-12, E-19).
- Brak zabezpieczeń przed podwójnym zapisem i zamykanie arkusza opinii mimo błędu. Dziś to głównie teoria, realny jest tylko podwójny upload zdjęcia. Fix defensywny jest tani (C-12, D-15, E-20).
- Latentne:
  - galeria może crashować po usunięciu ostatniego zdjęcia, ale dopiero z Premium albo prawdziwym backendem (E-8, D-8);
  - ulubione spoza bieżącej listy znikną, gdy parki będą stronicowane (C-14).
