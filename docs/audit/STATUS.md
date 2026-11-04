# Stan znalezisk audytu, 2026-11-04

Każde znalezisko z [findings.md](findings.md) sprawdzone na kodzie po fundamencie F0–F5 i po porządkach z tego przeglądu (gałąź przeglądu `w-audit-sweep`). Wszystkie 141 identyfikatorów: 136 znalezisk audytu i 5 dodanych przez weryfikatora (`*-V*`).

## Podsumowanie

| Status | Liczba |
|---|---|
| naprawione | 110 |
| zniknęło | 25 |
| świadomie odłożone | 3 |
| otwarte | 3 |
| **razem** | **141** |

- **Wszystkie P0 z audytu są zamknięte**: dane i zaufanie (#1–#6), bloker uploadu (#7), mocki i uprawnienia (#8, #9), lokalizacja i dostępność (#10, #11). Swift 6, CI i lint też.
- Ten przegląd zamknął 13 znalezisk, które jeszcze były otwarte: A-9, A-13, A-14, B-12, B-15, C-4, C-12, C-16, E-15, E-22, E-24, E-26, G-12. Do tego resztki D-13 i F-12 oraz część B-16, C-8/D-7, E-28, E-30, F-7, F-11, F-15, G-10, G-20, G-23 i G-24.
- Gałąź testów i narzędzi (`w-tests-tooling`) zamknęła 9 kolejnych: B-16, F-14, G-8, G-14, G-16, G-20, G-21, G-22 i G-23.
- 25 znalezisk zniknęło razem ze starym kodem, głównie ze starymi Parkami i Społecznością na atrapach (`34554ab`).
- Gałąź `w-ui-consistency` zamknęła spójność UI: E-21, E-23, E-28, E-30 i F-10 (jeden alert błędu, jeden styl przycisku akcentowego i drugorzędnego, skala promieni, kolory z katalogu, podglądy AX5). Gałąź `w-tests-tooling` zamknęła testy i narzędzia: B-16, F-14, G-8, G-14, G-16, G-20, G-21, G-22, G-23.
- Gałąź `w-perf` zamknęła wydajność przy dużym dzienniku i korzeń kompozycji: C-8, D-7, B-14 i F-7. Pomiary i przyjęty limit są w sekcji „Duży dziennik: pomiar i limit” niżej.
- Gałąź `w-views` zamknęła porządek w widokach i resztę korzenia kompozycji: E-25 (duże widoki rozbite na `Components/`, widoki z właściwości `var x: some View` jako osobne struktury), F-15 (dublery i środowiska podglądów tylko w buildzie Debug, `cali-park/PreviewSupport/`) i resztę F-7 (edytor celu i formularz poziomu czytają store dopiero przy pokazaniu).
- Otwarte zostały przenosiny folderów po TestFlighcie (F-8), testy UI (G-15) i katalog ćwiczeń, który czeka na drugi język (F-11). Rekomendacje są w tabeli niżej.

Statusy:

- **naprawione**: kod robi to, czego chciał audyt. Commit wskazuje naprawę.
- **zniknęło**: kodu, którego dotyczyło znalezisko, już nie ma (np. stare Parki z atrapami usunięte w `34554ab`).
- **otwarte**: coś z opisu dalej jest w kodzie. „Częściowo” znaczy, że większość jest naprawiona, a w uwagach jest to, co zostało.
- **świadomie odłożone**: mapa albo ticket odkłada resztę (backend, Społeczność, decyzja właściciela).

Commity od `2a2c469` do `dd2dc49` pochodzą z tego przeglądu; pozostałe opisuje „Postęp wykonania” w [MAP](../wayfinder/calipark-1.0/MAP.md).

## Co zostało otwarte i co z tym zrobić

Żadne otwarte znalezisko nie dotyczy utraty danych ani blokera App Store. Zostały porządki w kodzie, testy UI oraz drobiazgi wymagające decyzji.

| ID | Wysiłek | Decyzja właściciela | Rekomendacja |
|---|---|---|---|
| F-8 | M–L | tylko nazwy folderów | Jeden commit z samym przenoszeniem plików po TestFlighcie: `Domain/` (modele treningu, katalogi) i `Services/` (dziennik, postęp, nagrody, plany, store'y). |
| F-11 | M | **tak** przy drugim języku | Katalog ćwiczeń jako JSON dopiero razem z lokalizacją treści (String Catalog nie wyciąga tekstów z JSON). Do tego czasu zostaje w kodzie; ciche zastępstwa już usunięte. |
| G-15 | M | tylko wybór 3 ścieżek | Argument `-uitest-reset` budujący `AppEnvironment.seeded(...)`, identyfikatory dostępności i 3 testy UI (onboarding → Home, szybki trening → Historia, plan → Home). |

## Duży dziennik: pomiar i limit

Pomiar z `cali-parkTests/JournalWriteBenchmarkTests.swift` (poza zwykłym przebiegiem testów; uruchamia go `TEST_RUNNER_CALIPARK_BENCHMARK=1` z `-parallel-testing-enabled NO`). Dziennik 10 000 wpisów (ok. 6 lat po 4 treningi tygodniowo po 8 ćwiczeń), plik 2,6 MB, symulator iPhone 17 Pro Max na Macu, mediana z 7 prób. Zakres to Debug i Release z kilku przebiegów.

| Co | Przed (`521b254`) | Po |
|---|---|---|
| `load()` przy starcie | 62–77 ms | 54–72 ms (bez zmian, raz przy starcie) |
| Zapis jednego treningu (`log`, `delete(ids:)`), całość | 133–167 ms na main actorze | 96–185 ms poza main actorem |
| Najdłuższa blokada main actora podczas zapisu | cały zapis | poniżej 1 ms |
| Praca dziennika w pamięci po zapisie | 15–34 ms (sortowanie wszystkiego) | 0,5–1,5 ms |
| Home po zmianie (`HomeEngine.snapshot`) | kilka razy na render | 27–36 ms, raz na zmianę |
| Postęp po zmianie (`ProgressionEngine.snapshot`) | 30–63 ms, raz na zmianę | bez zmian |

Przyjęty limit: do ok. 10 000 wpisów. Realny intensywny użytkownik ma po 3 latach ok. 5000. Zapis nie blokuje już interfejsu. Zostają dwie świadome rzeczy na main actorze: jeden odczyt pliku przy starcie (przed pierwszym ekranem, żeby nigdy nie pokazać pustego dziennika) i przeliczenie postępu oraz Home raz po każdej zmianie. Przy 10 000 wpisów to razem ok. 60–100 ms, czyli kilka klatek po zapisie. Gdy dzienniki zbliżą się do tego rozmiaru, następny krok to liczenie `ProgressionEngine.snapshot` i `HomeEngine.snapshot` poza main actorem (obie funkcje są czyste i `nonisolated`) albo plik dzielony na lata.

## Wszystkie znaleziska

| ID | Tytuł skrócony | Status | Gdzie / commit | Uwagi |
|---|---|---|---|---|
| A-1 | Rekalibracja kasuje deklaracje | naprawione | `d4e1011` | Formularz startuje z zapisu, `PlacementCalibration.merging` zmienia tylko ruszone ścieżki. |
| A-2 | Fałszywe „+100 XP” po obniżeniu progu | naprawione | `d4e1011` | Szczeble poniżej progu są zapisywane jako już widziane. |
| A-3 | Guma jako obowiązkowy szczebel | naprawione | `c6182dd` | `nextMainLineRung` pomija tory równoległe, podpowiedź też. |
| A-4 | Celebracja oznaczana przed pokazaniem | naprawione | `d4e1011`, `688ee1e` | `RewardCenter.markCelebrated` zapisuje dopiero po zamknięciu. |
| A-5 | Awans liczony per wpis, nie trening | naprawione | `688ee1e` | `ScoringLog` łączy wpisy po treningu i ćwiczeniu. |
| A-6 | Szczebel zapisany jako indeks | naprawione | `d4e1011` | ID ćwiczenia zamiast indeksu, migracja przez `LadderOrderV1`. |
| A-7 | Stare mapowanie kubełków bez migracji | świadomie odłożone | MAP, Faza 0b | Starego zapisu nie da się pewnie rozpoznać; apka nie wyszła poza urządzenia deweloperskie. |
| A-8 | Holdy zapisane jako powtórzenia | naprawione | `3bbf358`, `688ee1e`, a32ffc8 | Silnik czyta je jako sekundy, prefill bierze miarę ćwiczenia; dziennik czyta stare holdy jako sekundy, więc historia, Home, cel objętości i eksport też (plik zostaje bez zmian). |
| A-9 | Pierwsza celebracja bez haptyki i pulsu | naprawione | `7df43bf` | Wyzwalacz ustawiany przy pojawieniu się, więc pierwsza i jedyna też gra. |
| A-10 | Pokazane XP różni się od zdobytego | naprawione | `688ee1e` | Jeden `RewardCenter`, „Razem +N XP” na ostatniej celebracji. |
| A-11 | Silnik wielokrotnie skanuje dziennik | naprawione | `688ee1e` | Snapshot postępu raz na rewizję dziennika. |
| A-12 | Arkusz szczebla ze starym wynikiem | naprawione | `688ee1e` | Arkusz czyta postęp na żywo. |
| A-13 | Niegramatyczne „do pierwsze 5 s” | naprawione | `a58b20a` | „Jeszcze 2 s do pierwszych 5 s” przez `MeasureFormat.criterionGoal`. |
| A-14 | Nieaktualne specyfikacje i martwy stan | naprawione | `688ee1e`, `d4e1011`, `beb38c8` | Kod czysty; stare plany i trackery oznaczone jako archiwum z odsyłaczem do `PROGRESSIONS.md`. |
| B-1 | Szybki trening ginie bez pytania | naprawione | `5012b44` | Pytanie przed odrzuceniem i blokada swipe'a w każdym szkicu. |
| B-2 | Błąd odczytu JSON kasuje dziennik | naprawione | `daf0492` | `JSONFileStore` odkłada uszkodzony plik i blokuje zapis. |
| B-3 | „Dziś” na Home nie odświeża się | naprawione | `e03695d` | `scenePhase`, zmiana dnia i zmiana czasu systemowego. |
| B-4 | Usunięty trening wisi na Home | naprawione | `e03695d`, `688ee1e` | Home obserwuje dziennik. |
| B-5 | Zrobiony plan dalej „Rozpocznij” | naprawione | `bfb3796` | Następny niezaliczony plan, potem „Dziś · Zrobione”. |
| B-6 | Zapis planu gubi `reminderTime` | naprawione | `5012b44` | Edytor zmienia kopię oryginału. |
| B-7 | Scheduler bez limitu i kolejki | naprawione | `bfb3796`, `78df41e` | Aktor, limit 64, konkretne daty, bez `.badge`. |
| B-8 | Plan jednorazowy w przeszłości | naprawione | `e3e2a39`, `5c97449` | Najwcześniejsza data w pickerze i „Minął · …”. |
| B-9 | Dni planu przesuwają się ze strefą | naprawione | `e3e2a39` | `CalendarDay`. |
| B-10 | Usuwanie treningu w N zapisach | naprawione | `688ee1e` | Jeden zapis `delete(ids:)`. |
| B-11 | `weeklyPullUps` omija kalendarz | zniknęło | `8d07335` | Zastąpione celem tygodniowym. |
| B-12 | Holdy źle w prefillu i sumach | naprawione | `3bbf358`, `01523f0` | „Zaczęte dziś” liczy też sekundy holdów. |
| B-13 | I/O w `init` view modeli | naprawione | `7ac1773`, `688ee1e` | Inicjalizatory niczego nie czytają. |
| B-14 | Home przelicza wszystko przy renderze | naprawione | `052396e` | `HomeSnapshot` (hero, następny i ostatni trening, seria, osiągnięcia, podpowiedź) liczony przez `HomeEngine` raz na rewizję dziennika, zmianę planów, rewizję postępu i dzień. Cel tygodniowy już był z cache'u `WeeklyGoalService`. |
| B-15 | Martwy kod w view modelach | naprawione | `16467aa`, `d163d01` | Usunięte ostatnie: fabryka edytora na Home i `totalTargetSets`. |
| B-16 | Testy dat tylko w UTC | naprawione | `e3e2a39`, `e03695d`, `dd2dc49`, `112365d` | Testy stref, odświeżania Home, DST dla serii i harmonogramów, przypomnień o 02:30 (godzina, której nie ma, i powtórzona) i granicy tygodnia celu. |
| C-1 | Błąd odczytu kasował dziennik | naprawione | `daf0492` | Plik odkładany na bok, zapis zablokowany, alert. |
| C-2 | Brak manifestu prywatności | naprawione | `7a802c5` | `UserDefaults` `CA92.1`, bez śledzenia. |
| C-3 | Opinie i zdjęcia tylko w pamięci | zniknęło | `34554ab` | Społeczność wróci z backendem. |
| C-4 | Brak wersjonowania plików | naprawione | `daf0492`, `4a7661a` | Koperta `schemaVersion`; harmonogram planu ma zamrożony format niezależny od nazw case'ów. |
| C-5 | Indeksy szczebli zamiast ID | naprawione | `d4e1011` | Plik postępu w wersji 2. |
| C-6 | Rekalibracja nadpisuje deklaracje | naprawione | `d4e1011` | Jak A-1. |
| C-7 | Celebracja oznaczana przy kolejkowaniu | naprawione | `d4e1011`, `688ee1e` | Zapis po zamknięciu, tylko przy zmianie, błędy w logach. |
| C-8 | Synchroniczne I/O całego pliku | naprawione | `688ee1e`, `d3fbbe1`, `cc0a77f` | Zapis dziennika poza main actorem (`@concurrent` w `JSONFileStore`), po kolei, w kolejności wywołań. Odczyt przy starcie zostaje synchroniczny; limit niżej. |
| C-9 | Daty planów a strefa czasowa | naprawione | `e3e2a39` | `CalendarDay`, stary format dalej się czyta. |
| C-10 | Martwe Core Data przy starcie | naprawione | `e3e2a39` | Usunięte, pusty plik bazy kasowany raz. |
| C-11 | Onboarding kończy się mimo błędu | naprawione | `89a3528` | Alert, koniec dopiero po „Rozumiem”. |
| C-12 | Podwójny zapis po podwójnym tapnięciu | naprawione | `22b8994`, `2a2c469` | Szybki trening i SetPad ignorują drugi zapis. |
| C-13 | Edytor planu gubi `reminderTime` | naprawione | `5012b44` | Jak B-6. |
| C-14 | Ulubione z widocznych Parków | zniknęło | `34554ab` | Nowe `ParkFavorites` (`bb51815`) trzymają też ID spoza snapshotu. |
| C-15 | Higiena przechowywania danych | naprawione | `e3e2a39`, `16467aa` | Application Support, `DefaultsKey`, wstrzykiwane `UserDefaults`; domyślna ochrona plików celowo (`research/training-sync.md`). |
| C-16 | Domyślne store'y poza korzeniem | naprawione | `688ee1e`, `5f7775f` | Żaden init bez wstrzyknięcia; podglądy tylko w pamięci, `AppEnvironment.preview` usunięte. |
| C-17 | Brak eksportu dziennika | naprawione | `89a3528` | Eksport i import w Profilu. |
| C-V1 | Onboarding gubi cele i lokalizację | zniknęło | `89a3528` | Nowy onboarding bez tych stron. |
| D-1 | Niesendowalne `Park.mock`, `PersistenceController` | zniknęło | `34554ab`, `e3e2a39` | |
| D-2 | `static var` w `PreferenceKey` | zniknęło | `34554ab` | W apce nie ma `PreferenceKey`. |
| D-3 | Niesendowalne protokoły serwisów | zniknęło | `34554ab` | Nowe protokoły między izolacjami są `Sendable` (`e09f965`, `7047560`). |
| D-4 | Błąd dekodowania kasuje historię | naprawione | `daf0492` | Jak B-2. |
| D-5 | Reentrancy w wydarzeniach Parku | zniknęło | `34554ab` | Wydarzenia w v1.1. |
| D-6 | Init view modeli z efektami ubocznymi | naprawione | `688ee1e`, `7ac1773` | |
| D-7 | Synchroniczne I/O na main actor | naprawione | `7ac1773`, `688ee1e`, `d3fbbe1`, `cc0a77f` | Jak C-8. Zdjęcia Parków zniknęły w `34554ab`. |
| D-8 | Usuwanie z galerii poza zakresem | zniknęło | `34554ab` | |
| D-9 | Wyszukiwarka ucina spację | naprawione | `d1d1736` | Nowe wyszukiwanie niczego nie zapisuje z powrotem. |
| D-10 | `ObservableObject` i `@EnvironmentObject` | naprawione | `16467aa`, `7ac1773` | Zero `ObservableObject` i Combine. |
| D-11 | Timery `DispatchQueue` | zniknęło | `16467aa`, `34554ab` | |
| D-12 | Nieczytany `AppEnvironment` | naprawione | `7ac1773` | Zwykła klasa. |
| D-13 | `Task.sleep(nanoseconds:)`, toast chowa nowszy | naprawione | `7ac1773`, `3398af3` | Ostatnie `try? await Task.sleep` wraca przy anulowaniu. |
| D-14 | Domknięcia widoku w view modelu | zniknęło | `34554ab` | |
| D-15 | Podwójny zapis opinii, zdjęcia, treningu | naprawione | `22b8994` | Opinie i zdjęcia zniknęły. |
| D-16 | `PhotosPicker` w `Task` z `onChange` | zniknęło | `34554ab` | `Task` w `onChange` w `ParksView` tylko odświeża lokalizację; to akceptowalne. |
| D-17 | Brak odświeżania przez `scenePhase` | naprawione | `e03695d` | Jak B-3. |
| D-18 | Optymistyczne zdjęcie bez wycofania | zniknęło | `34554ab` | |
| D-19 | Przypomnienia bez serializacji | naprawione | `bfb3796` | Łańcuch synchronizacji w `WorkoutPlanService`. |
| D-V1 | Podwójny toast „+N XP” | naprawione | `688ee1e` | Jedno źródło toastu. |
| E-1 | Dynamic Type zepsuty przez `AppTheme` | naprawione | `9d340c9`, `7975b76`, `ccc1023` | |
| E-2 | Zmyślona pogoda i „Michał” na Home | naprawione | `34554ab`, `89a3528`, `16467aa` | |
| E-3 | Szkice znikają bez pytania | naprawione | `5012b44` | |
| E-4 | Atrapy i martwe przyciski | świadomie odłożone | MAP, Profil (Q25) | Został tylko `kontakt@calipark.example`; prawdziwy adres przyjdzie z „Wydaniem”. |
| E-5 | Wyszukiwarka usuwa spacje | zniknęło | `34554ab` | Nowe `ParkSearch` (`d1d1736`). |
| E-6 | Blokery Swift 6 w widokach | zniknęło | `34554ab` | |
| E-7 | Losowy „Tłok” | zniknęło | `34554ab` | Tłok w v1.1. |
| E-8 | Crash galerii | zniknęło | `34554ab` | |
| E-9 | Odświeżenie kasuje wydarzenia | zniknęło | `34554ab` | |
| E-10 | `onTapGesture` zamiast `Button` | naprawione | `34554ab`, `e90075c` | Lint: 0. |
| E-11 | Przyciski-ikony bez etykiety | naprawione | `34554ab`, F5 | |
| E-12 | Kolejność modułów niedostępna | naprawione | `16467aa` | „Zmień kolejność” i akcje VoiceOvera. |
| E-13 | Luki w strukturze VoiceOvera | naprawione | `e90075c`, `16467aa`, `d8dfaae` | |
| E-14 | Brak lokalizacji | naprawione | `7888036`, `830bdfe`, `37628e0`, `e2e3335` | Tłumaczenia po starcie (MAP). |
| E-15 | Wymuszony ciemny motyw, kontrast | naprawione | `1151ff1`, `45e3157` | Tylko ciemny motyw to decyzja (F5); `UIUserInterfaceStyle = Dark` i ciemny ekran startowy. |
| E-16 | Home przelicza silnik przy renderze | naprawione | `688ee1e`, `16467aa` | Silnik raz na rewizję; resztę przeliczeń opisuje B-14. |
| E-17 | View modele z I/O w `View.init` | naprawione | `7ac1773` | |
| E-18 | Paralaksa w karcie Parku | zniknęło | `34554ab` | |
| E-19 | Arkusz szczebla nieaktualny | naprawione | `688ee1e` | |
| E-20 | Arkusz opinii gubi tekst | zniknęło | `34554ab` | |
| E-21 | Niespójny motyw, kolory, promienie | naprawione | `b115b59` | `AccentButtonStyle` i `SecondaryButtonStyle` zamiast 14 ręcznych CTA i stylu hero; `AppRadius` 8/12/18 zamiast 9 promieni; `Warning`, `Danger`, `Streak`, `ControlFill`, `Divider` w katalogu zamiast `Color.orange`, kolorów statusu i `white.opacity`. Przyciski karty Parku (kapsuły na szkle) zostają osobnym stylem mapy. |
| E-22 | Martwy kod widoków | naprawione | `16467aa`, `d163d01` | Usunięte `hideKeyboard()` i `statusGreen`; prototypy tylko w Debug, celowo. |
| E-23 | Przestarzałe modyfikatory | naprawione | `c01ada3` | Ostatnie przyciski z `Label` (10 i menu „Dodaj cel”) na `Button(_:systemImage:)` ze stylem; `fontWeight` zastąpione `bold(_:)`. |
| E-24 | `DispatchQueue`, `sleep(nanoseconds:)`, `String(format:)` | naprawione | `7ac1773`, `4114c35` | Lint: 0 dla wszystkich trzech. |
| E-25 | `ObservableObject`, `AnyView`, wiele typów | naprawione | `0f5a3e2`, `fe53c2f`, `47326e5`, `2c7ab22` i dalsze z gałęzi `w-views` | `ExerciseLibraryView`, `ExerciseDetailView`, `PlanEditorView`, `PathDetailView` i inne ekrany rozbite na pliki w `Views/Components/`; widoki z właściwości ponad kilka linii są osobnymi strukturami. Zostały tylko jednolinijkowe właściwości i świadome wyjątki (szczegóły w raporcie gałęzi). |
| E-26 | Sortowanie i filtrowanie w `body` | naprawione | `688ee1e`, `5c74141` | Rodzic i warianty ćwiczenia z gotowych indeksów. |
| E-27 | Kamera bez sprawdzenia | zniknęło | `34554ab` | |
| E-28 | Podglądy bez wariantów dostępności | naprawione | `e07dfb7` | Warianty `.accessibility5` dla Home, hero, listy ćwiczeń, ścieżki, edytora planu i karty Parku; podglądy dla widoków bez nich (poza prototypami). |
| E-29 | Drobiazgi nawigacji w Parkach | zniknęło | `34554ab` | |
| E-30 | Pierścień, puls, haptyka, siatka | naprawione | `1bf6fdc` | „Rozpocznij” pulsuje 3 razy po pojawieniu się (`PulsePhases`), bez pulsu przy Ograniczeniu ruchu; ścieżka pierścienia w `Color.divider`. Siatka i haptyka wcześniej (`8d07335`, `f152d6e`, `191dabd`). |
| F-1 | Kopie store'ów kasują dane | naprawione | `daf0492` | Wszystkie store'y na `JSONFileStore`. |
| F-2 | Atrapy na Home | naprawione | `16467aa`, `8d07335`, `d1d1736` | |
| F-3 | „Zaloguj trening” w każdym flow | naprawione | `688ee1e` | `TrainingJournal`. |
| F-4 | Stan nagród w każdym ekranie | naprawione | `688ee1e` | `RewardCenter`. |
| F-5 | Brak koordynacji przypomnień | naprawione | `bfb3796`, `5012b44` | `WorkoutPlanService`. |
| F-6 | Postęp liczony wielokrotnie | naprawione | `688ee1e` | `ProgressService`. |
| F-7 | Problemy korzenia kompozycji | naprawione | `7ac1773`, `5f7775f`, `052396e`, `6a6f7bb` | Home bierze modele arkuszy z `AppEnvironment`, wszystkie parametry `AppEnvironment.init` są wymagane, `ProgramDetailViewModel` czyta w `.task`. Edytor celu tygodniowego i formularz poziomu czytają store w `load()` przy pokazaniu, nie w `init` (`6a6f7bb`). |
| F-8 | Foldery a własność domeny | otwarte | `Features/` | Wspólna domena treningu leży w folderach funkcji. |
| F-9 | Parki na starej architekturze | zniknęło | `34554ab`, `d1d1736` | |
| F-10 | Fonty i trzy systemy przycisków | naprawione | `9d340c9`, `f7332b3`, `b115b59` | Typografia na stylach tekstu; jeden `errorAlert`/`messageAlert` zamiast 17 kopii `errorBinding`; wspólne `ExerciseCategoryChips`; bez `.blur` na jednolitym kolorze; jeden system przycisków (E-21). |
| F-11 | Katalog ćwiczeń jako kod | otwarte | `ExerciseCatalog.swift` | Ciche zastępstwa usunięte (`89a63d0`); dane w kodzie do drugiego języka. |
| F-12 | Martwy kod | naprawione | `16467aa`, `e3e2a39`, `34554ab`, `d163d01` | |
| F-13 | Powielone formatowanie | naprawione | `688ee1e` | `MeasureFormat`. |
| F-14 | Niespójne nazwy, ID modułów | naprawione | `06fc6a4` | `enum HomeModule: String` z tymi samymi surowymi wartościami (test starej zapisanej tablicy), `CaliParkApp`, `SkillPlacementStoring`; reszta nazw zniknęła ze starym kodem. |
| F-15 | Wiele typów w pliku, dublery w produkcji | naprawione | `7b3d3fa`, `97f1a75` | Dublery `InMemory…`, `FixedLocationProvider`, `DiagnosticPreviewData`, `UserDefaults.throwaway()` i `AppEnvironment.seeded(...)`/`preview…` w `cali-park/PreviewSupport/` pod `#if DEBUG`, razem z `#Preview`, które ich używają. Build Release kompiluje się bez ostrzeżeń, a jego binarka nie zawiera żadnego dublera. |
| F-V1 | Odległości od sztywnej Warszawy | naprawione | `d1d1736` | `LocationProviding`. |
| G-1 | Brak manifestu prywatności | naprawione | `7a802c5` | |
| G-2 | Atrapy na Home | naprawione | `16467aa`, `89a3528` | |
| G-3 | Daty po angielsku | naprawione | `e2e3335`, `7888036` | |
| G-4 | Nieczytelny plik nadpisywany | naprawione | `daf0492` | |
| G-5 | Demo Parki, Premium, Unsplash | zniknęło | `34554ab` | |
| G-6 | Opisy uprawnień | naprawione | `e6fc8a9`, `d1d1736` | Zostało tylko używane uprawnienie lokalizacji. |
| G-7 | Brak CI | naprawione | `449024e`, `45de40c`, `3b5dd4a` | |
| G-8 | Claude nie widzi reguł i skilli | naprawione | `af013d3` | `CLAUDE.md` importuje reguły; README opisuje instalację skilli Swift (`npx skills add … -a claude-code` albo dowiązanie do `.claude/skills/`); skille celowo lokalne. |
| G-9 | `project-rules.mdc` błędne | naprawione | `e09f965` | Domyślna izolacja `MainActor` jest teraz włączona. |
| G-10 | Brak diagnostyki | naprawione | `daf0492`, `3398af3`, `e25a224` | Logowanie przez `os.Logger` wszędzie; raporty MetricKit zostają na telefonie i wysyła je tylko użytkownik („Diagnostyka”, Q33). |
| G-11 | Landscape i iPad | naprawione | `e6fc8a9` | |
| G-12 | Asercje wywalające testy | naprawione | `4041ab2` | `try #require` zamiast `try!` i indeksów po `#expect`; stałe katalogu w fixture'ach zostają. |
| G-13 | Testy Codable bez formatu z dysku | naprawione | `daf0492` | Złote pliki w `Fixtures/`. |
| G-14 | Ryzykowny kod bez testów | naprawione | `5fa6577`, `070794c` | `CoreLocationProvider` nad protokołem `LocationManaging`, testy oczekujących, zmian uprawnień, świeżości pozycji i timeoutu; wykrywanie hosta testów w `CaliParkApp` ma test. |
| G-15 | UI testy z szablonu | otwarte | `cali-parkUITests/` | |
| G-16 | Brak schematu i test planu | naprawione | `070794c` | Współdzielony schemat i `cali-park.xctestplan`, `.timeLimit` w zestawach z testami asynchronicznymi, host testów bez `AppEnvironment.live()`. `xcschememanagement.plist` celowo dalej śledzony (usunięcie z indeksu skasowałoby go właścicielowi). |
| G-17 | Przypomnienia bez konsumenta | naprawione | `5012b44`, `bfb3796` | |
| G-18 | Brak lintu | naprawione | `449024e`, `bdade25`, `4114c35` | Reguły blokują CI; `swift-format` tylko raportuje (poza zakresem). |
| G-19 | Swift 5 | naprawione | `e09f965`, `7047560`, `22b8994` | |
| G-20 | Testy zależne od zegara | naprawione | `4041ab2`, `fb93d80` | Zegar wstrzyknięty do `QuickWorkoutViewModel`; pomocniki testów bez domyślnych `.now`/`.current`. |
| G-21 | Zduplikowane fixture'y | naprawione | `8b1e0d4` | `cali-parkTests/Support/`: `TestCalendar`, `TestDate`, cecha `.temporaryDirectories` sprzątająca po teście, wspólne dublery dziennika. |
| G-22 | Słabe asercje | naprawione | `2da1e34` | Store-szpieg liczy zapisy, dokładne komunikaty błędów i wartości, `== false` zamiast `!` (147 miejsc). |
| G-23 | Nieaktualne dokumenty sprintów | naprawione | `beb38c8`, `7fa140c` | Trackery i plany oznaczone jako archiwum; kody sprintów w komentarzach zastąpione opisem zachowania. |
| G-24 | Tożsamość i Info.plist | świadomie odłożone | `757d57f`, `45e3157`; ticket 017 | Nazwa, styl, ekran startowy i szyfrowanie zrobione; bundle ID i zespół po zakupie konta. |
| G-25 | Core Data przy starcie | naprawione | `e3e2a39` | |
| G-V1 | Fałszywe opinie Parków | zniknęło | `34554ab` | |
| G-V2 | Profil jako atrapa | naprawione | `89a3528` | |
