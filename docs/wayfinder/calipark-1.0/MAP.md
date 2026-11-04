---
title: CaliPark 1.0
label: wayfinder:map
---

# CaliPark 1.0

## Cel

Zdecydowany spec CaliPark 1.0: zakres, backend, model danych, wygląd kluczowych ekranów i plan wydania pocięty na sprinty, gotowy do wykonania. Docelowo App Store przed kwietniem 2027, a zimą 2026/27 TestFlight z ekipą.

## Notatki

- **Domena:** apka do kalisteniki, czyli trening działający bez Konta plus mapa Parków ze Społecznością. Słownik: [GLOSSARY.md](../../../GLOSSARY.md). Stan kodu i znane bugi: [docs/audit/README.md](../../audit/README.md). Jak działa ten tracker: [README.md](../README.md).
- **Właściciel dopiero zaczyna w Swift/iOS.** Wybory techniczne iOS tłumacz prosto, z jedną rekomendacją. Decyzje produktowe, estetyczne i finansowe należą do właściciela.
- **Skille:**
  - `grilling` i `domain-modeling` przy każdym tickecie HITL,
  - `research` przy researchowych, `prototype` przy prototypach,
  - `swiftui-pro` i `swiftui-design-principles` przy UI,
  - `swift-concurrency-pro` przy backendzie i syncu,
  - `core-data-expert` przy syncu przez CloudKit,
  - `swift-testing-pro` przy planie testów.
- **Stałe preferencje:**
  - dane w UE,
  - koszt backendu do ok. 100 zł/mies. przy ~10k aktywnych użytkowników, bez własnego serwera,
  - bezpieczeństwo z kontrolą dostępu na poziomie wierszy,
  - trening zawsze darmowy i bez Konta,
  - commity prosto na `main`, bez trailerów.
- **Właściciel kupi Apple Developer Program później** (2026-11-04, brak budżetu). Do zakupu robimy tylko to, co nie wymaga płatnego konta.
- **Planowanie, ale z równoległym wykonaniem prac „bez żalu”.** Mapa kończy się na specu. Właściciel (2026-11-03) zgodził się, żeby równolegle do niej szły w wątkach-workerach prace potrzebne przy każdej decyzji: Faza 0 fundamentu (P0 z audytu, privacy manifest, iPhone-only), prototypy do ticketów i propozycje do potwierdzenia.
- **Koordynacja.** Jeden wątek-koordynator prowadzi mapę, zleca pracę workerom, merguje na `main` i jako jedyny zadaje właścicielowi pytania. Workerzy nigdy nie pytają właściciela, tylko zgłaszają pytania koordynatorowi. Gdy kontekst koordynatora dojdzie do ok. 200–250k tokenów, przekazuje rolę świeżemu wątkowi przez handoff.

## Decyzje do tej pory

- [Zakres CaliPark 1.0: decyzje z chartingu](tickets/001-zakres-1-0.md):
  - start w Polsce po polsku,
  - Sign in with Apple, publiczny tylko Pseudonim,
  - Społeczność v1 to Parki, opinie i zdjęcia z moderacją, a zgłoszenia są darmowe,
  - treningi przez iCloud,
  - backend w UE do ok. 100 zł/mies.,
  - v1 darmowe, tylko iPhone,
  - prawdziwa pogoda, rewizja programów,
  - najpierw fundament, App Store przed kwietniem 2027.
- [Backend dla Parków i Społeczności: opcje i koszty](tickets/002-backend-research.md):
  - ranking: Supabase Cloud Pro Frankfurt (25 USD/mies. do ok. 45k MAU), potem własne API na Hetznerze (ok. 15–31 €/mies.), potem PocketBase,
  - Rust sam nie daje bezpieczeństwa,
  - limit zapisów i uzasadnienia usunięć (DSA) budujemy sami.
- [Sync treningów przez iCloud: technologia i migracja](tickets/003-sync-research.md):
  - CKSyncEngine na prywatnej bazie iCloud, pliki JSON zostają źródłem prawdy,
  - Faza 0 (naprawa danych) nie wymaga płatnego konta,
  - schemat zamraża pierwszy build TestFlight z syncem.
- [Parki z OpenStreetMap w Polsce i licencja ODbL](tickets/004-osm-research.md):
  - ok. 390 pewnych Parków w Polsce, ok. 107 w 5 miastach,
  - użycie OSM wymaga udostępnienia danych Parków na ODbL,
  - innych źródeł nie wolno importować.
- [Drabiny progresji i gotowe programy ze źródeł](tickets/005-progressions-research.md):
  - większość drabin trzyma się źródeł,
  - do poprawy: handstand, L-sit, planche, flaga, nogi,
  - programy: Minimum od razu, Fundamenty po nowych drabinach, Skille tylko handstand i L-sit,
  - najpierw stabilne ID szczebli.
- [Wymagania App Store i RODO dla 1.0](tickets/006-compliance-research.md):
  - privacy manifest blokuje upload,
  - Społeczność wymaga zgłoszeń, blokowania, reakcji w 24h i kasowania treści z Kontem,
  - Konto 16+ daje apkę 16+,
  - RODO: polityka, umowy powierzenia i usuwanie EXIF,
  - DSA: zgłoszenia także bez Konta i uzasadnienia usunięć.
- [Wybór backendu](tickets/007-backend-choice.md):
  - Supabase Cloud Pro, Frankfurt,
  - 8 GB na bazę i 100 GB na zdjęcia (ok. 300 tys. zdjęć),
  - RLS, własne limity, DSA, DPA,
  - odrzucone: Rust/Hetzner, PocketBase, Firebase, CloudKit public.
- [Technologia syncu treningów](tickets/009-sync-tech.md): CKSyncEngine na prywatnym iCloud, pliki JSON jako źródło prawdy, bez Konta.
- [Warstwa danych treningów: naprawione pliki JSON czy SwiftData](tickets/010-training-persistence.md):
  - utwardzone pliki JSON (Faza 0: bez cichego wipe'u, wersjonowanie, stabilne ID szczebli),
  - SwiftData odrzucone.

- [Panel moderacji: w apce, strona www czy oba](tickets/008-moderation-panel.md): strona www dla Moderatorów, w apce tylko zgłaszanie.
- [Wygląd mapy parków](tickets/011-map-look.md): wariant A (wyciszona) na MapKit, lista z C jako przełącznik.
- [Model Parku i sprzętu](tickets/012-park-model.md): model z propozycji; Park = drążek albo poręcze (definicja bez zmian); miejsca z OSM bez opisanego sprzętu nie są Parkami (2026-11-04).
- [Status „Zweryfikowany” i poprawki do parków](tickets/014-verified-parks.md): tak, status dla Parków odwiedzonych przez ekipę i poprawki przez kolejkę moderacji.
- [Rewizja drabin progresji](tickets/015-ladders-revision.md): z propozycji, 11 nowych szczebli, statyki 3×20 s, guma jako tor równoległy.
- [Gotowe programy treningowe w 1.0](tickets/016-programs-v1.md): Minimum, Fundamenty, Pierwsze podciągnięcie i Skille.
- [Przypomnienia o treningu w 1.0](tickets/019-reminders-v1.md): tak, lokalne, zgoda przy pierwszym włączeniu.
- [Import z OSM i otwarte dane Parków (ODbL)](tickets/020-osm-odbl.md): tak, cotygodniowy, dane Parków jako plik na ODbL.
- [Minimalny wiek Konta i kategoria wiekowa apki](tickets/021-account-age.md): 16+, apka 16+ (decyzja właściciela wbrew rekomendacji 13+).
- [Kolejność wydań: TestFlight z samym treningiem, potem Społeczność](tickets/022-release-order.md): TestFlight z samym treningiem, sync najpierw Ad Hoc, potem Społeczność.
- [Formularz zgłoszenia parku](tickets/013-submission-form.md): układ B (jeden arkusz), zdjęcia z aparatu i galerii, same poręcze też robią Park, Konto przy „Wyślij”.
- [Plan fundamentu: kolejność P0, Swift 6, CI](tickets/018-foundation-plan.md): F0–F5 przed TestFlightem; zakładka Parków zostaje z mapą Parków z OSM tylko do odczytu, nazwa „Siłownie” zostaje, eksport i import w 1.0.
- [Home w 1.0](tickets/024-home-v1.md): moduły dalej do przestawiania (z alternatywą dla VoiceOver), bez mocków, cel tygodniowy w osobnym tickecie.
- [Profil i ustawienia w 1.0](tickets/025-profile-settings-v1.md): statystyki, cel, historia, eksport i import, pomoc, „O apce”; Konto ze Społecznością.
- [Onboarding w 1.0](tickets/026-onboarding-v1.md): powitanie, test poziomu, program, cel tygodniowy; zgody i Konto dopiero przy użyciu.
- [Karta parku](tickets/023-park-card.md): najpierw zdjęcia, pełna karta jako arkusz, opinie od razu, zdjęcia po moderacji, średnia od 3 opinii, pogoda dopiero z WeatherKit; ulubione Parki na telefonie (2026-11-04).
- [Cel tygodniowy](tickets/027-weekly-goal.md): 1–3 cele (dni, plany, objętość), pierwszy tydzień rozgrzewkowy, pauza do 90 dni bez utraty serii, seria tygodni w hero (wzór: Apple Watch).
- Ulubione ćwiczenia (2026-11-04, właściciel przy Q26): gwiazdka przy ćwiczeniu, sekcje „Ulubione” i „Ostatnio” (do 5 z historii) na górze każdego wyboru ćwiczeń, ulubione w backupie.
- Strona startowa (2026-11-04, Q32): na Vercelu właściciela (Pro), nie na GitHub Pages; opis apki, polityka prywatności, dane Parków (ODbL), pomoc. Publikacja dopiero po akceptacji tekstu przez właściciela.
- Diagnostyka (2026-11-04, Q33, decyzja delegowana koordynatorowi): tylko narzędzia Apple, czyli raporty crashy z TestFlight i App Store w Xcode Organizer oraz MetricKit trzymany na telefonie; raport wychodzi tylko wtedy, gdy użytkownik sam go wyśle mailem z „Pomoc i opinie”. Bez zewnętrznego SDK.
- Motyw (2026-11-04, Q34): w 1.0 tylko ciemny.
- Ikona (2026-11-04, Q38): koncept D „Drabinka” (drabinka progresji, szczeble jaśnieją ku górze, limonka na ciemnym tle); ten sam znak jako logo strony.

## Postęp wykonania

Prace „bez żalu” z workerów, zmergowane na `main`. Testy: build bez warningów, wszystkie testy jednostkowe zielone.

**Faza 0 z mapy jest w całości zrobiona** (punkty 1–4 z „Warstwa danych treningów”); zostaje przeniesienie plików do Application Support oraz eksport i import.

- **Faza 0a: bezpieczeństwo danych i blokery uploadu** (`daf0492`, `7a802c5`, `e6fc8a9`, 2026-11-03):
  - wspólny `JSONFileStore` dla 4 store'ów: uszkodzony plik jest odkładany na bok, nigdy nie nadpisywany, błąd pokazuje alert i trafia do logów (B-2, C-1, D-4, F-1, G-4, G-10),
  - wersjonowana koperta `schemaVersion: 1`, stary format dalej się czyta (C-4),
  - testy na prawdziwych plikach z dysku (G-13),
  - `PrivacyInfo.xcprivacy` z `UserDefaults` `CA92.1` (C-2, G-1),
  - tylko iPhone i pion, bez Maca i Vision Pro (G-11), poprawione teksty uprawnień (G-6),
  - testy: 302 (544 przypadki), było 270 (512).
- **Faza 0c: szkice i nieaktualny Home** (`e03695d`, `5012b44`, 2026-11-03):
  - szybki trening, edytor planu i SetPad pytają przed odrzuceniem wpisanych danych, a swipe w dół jest wtedy zablokowany (B-1, E-3),
  - Home odświeża „dziś” po powrocie do apki i o północy (B-3, D-17) oraz po zamknięciu szybkiego treningu z Home (B-4),
  - edytor planu nie gubi pól, których nie edytuje, np. `reminderTime` (B-6, C-13),
  - testy: 329 (575 przypadków).
- **Faza 0b: integralność danych Skills** (`d4e1011`, 2026-11-03):
  - szczeble zapisane po ID ćwiczenia zamiast indeksu, z migracją starych plików przez zamrożoną kolejność drabin (`LadderOrderV1`), wersja pliku 2 (A-6, C-5); to odblokowuje „Rewizja drabin progresji”,
  - „Ustaw poziom” startuje z zapisanych odpowiedzi i nie kasuje ścieżek, których nie ruszasz (A-1, C-6),
  - koniec fałszywego „+100 XP” po obniżeniu poziomu (A-2),
  - celebracja liczy się jako pokazana dopiero po zamknięciu, a plik postępu nie jest przepisywany przy każdym wczytaniu (A-4, C-7),
  - nie zrobione: A-7 (stare mapowanie kubełków, nie da się go pewnie rozpoznać), podwójny toast XP (F-4, D-V1, A-10, wymaga wspólnego koordynatora nagród); A-3 zrobione w rewizji drabin,
  - testy: 355 (618 przypadków).
- **Rewizja drabin** (`c6182dd`, 2026-11-04, „Rewizja drabin progresji”):
  - 11 nowych szczebli, L-sit w kolejności GMB (pełny 3 × 20 s), wejścia na podwyższenie jako tor równoległy; `PROGRESSIONS.md` i katalog 1:1,
  - przy każdym kryterium źródło („Skąd to kryterium?”: RR, OG2, GMB, SBW, Cali Move, konwencja CaliPark), tempo negatywów i pauza w opisie,
  - ruchy jednostronne z dopiskiem „na rękę / na nogę / na stronę”, format logów bez zmian,
  - sprzęt: „Pionowy drążek” (`fitness_pole`), „Drabinki gimnastyczne” (`wall_bars`), „Drabinka pozioma”,
  - silnik pomija tory równoległe przy wyborze aktualnego szczebla, więc guma nie jest już obowiązkowa (A-3),
  - kalibracja wskazuje szczeble po ID; dipy „12+” startują od podporu na kółkach,
  - jednorazowy skok XP za nowe niższe szczeble (np. +100 XP przy pełnych podciągnięciach, maks. +1100 XP), przyjęty w 015,
  - testy: 426 (722 przypadki).
- **Ikona** (`dcb3b26`, `5d62d4a`, 2026-11-04, Q38): „Drabinka” jako ikona Liquid Glass (`AppIcon.icon`, ręcznie z SVG) z obrazkami dla iOS 18 (domyślny, ciemny, barwiony); ten sam znak jako logo, favicon i obrazek OG strony. Źródła w `brand/`, generator `scripts/brand/build-icons.mjs`; zamiana na „Pinezkę” to jedna linia w `brand/ACTIVE`.
- **Wydajność dziennika i Home** (`cc0a77f`…`d18a229`, 2026-11-04): pomiar przy 10 tys. wpisów (2,6 MB): zapis treningu trwał 133–167 ms na głównym wątku, czyli ok. 10 klatek; teraz zapis idzie w tle, w kolejności wywołań, a ekran stoi poniżej 1 ms (C-8, D-7). Home liczy hero, serię, ostatni trening i podpowiedź raz na zmianę dziennika, planów lub dnia (`HomeSnapshot`, B-14); fabryki tylko w `AppEnvironment`, wszystkie parametry wymagane (F-7). Przyjęty limit: ok. 10 tys. wpisów (intensywny użytkownik ma ok. 5 tys. po 3 latach). Status audytu: 108 naprawionych, 5 otwartych. Testy: 947 (1433 przypadki).
- **Testy i narzędzia** (`8b1e0d4`…`1410aaf`, 2026-11-04): wspólne pomocniki testów (kalendarz UTC, daty, katalogi tymczasowe sprzątane po teście, dublery dziennika) (G-21), zegar wstrzykiwany do szybkiego treningu (G-20), dokładne asercje i szpieg zapisów (G-22), testy zmiany czasu dla przypomnień i celu tygodniowego (B-16), testy `CoreLocationProvider` (G-14), wspólny schemat, test plan i testy bez startu całej apki (G-16), `HomeModule` jako enum i nowe nazwy typów (F-14), komentarze bez kodów sprintów (G-23), instalacja skilli w README (G-8). Status audytu: 104 naprawione, 9 otwartych. Testy: 928 (1394 przypadki).
- **Diagnostyka** (`e25a224`, 2026-11-04, Q33): raporty MetricKit (crashe, zawieszki, CPU, zapisy na dysk, wolny start) zostają na telefonie przez 30 dni (maks. 50); Profil → „Pomoc i opinie” → „Diagnostyka” pokazuje je i pozwala wysłać mailem albo udostępnić plik; nic nie jest wysyłane samo (G-10). Testy: 901 (1360 przypadków).
- **Strona startowa, szkic** (`4792e96`, 2026-11-04, Q32): `site/` w Next.js dla Vercela: strona główna, polityka prywatności sprawdzona z kodem, dane Parków (ODbL), pomoc; szkic opisu do App Store i odpowiedzi „App Privacy” w `docs/release/`; job CI „Site build”. Nieopublikowana: czeka na tekst, domenę, mail i administratora od właściciela.
- **Spójny wygląd** (`e36857f`…`01b931d`, 2026-11-04): jeden styl przycisku głównego (limonkowy) i jeden drugorzędny zamiast ok. 14 ręcznych, skala zaokrągleń 8/12/18, kolory z katalogu zamiast `Color.orange` i `white.opacity` (E-21); jeden alert błędu zamiast 17 kopii i wspólne chipy kategorii (F-10); ostatnie przyciski z `Label` (E-23); „Rozpocznij” pulsuje 3 razy i przestaje, bez pulsu przy „Ogranicz ruch”, widoczny tor pierścienia celu (E-30); podglądy w rozmiarze AX5 (E-28). Testy: 865 (1323 przypadki).
- **Status audytu** (`2a2c469`…`95299af`, 2026-11-04): [docs/audit/STATUS.md](../../audit/STATUS.md) klasyfikuje wszystkie 141 znalezisk: 89 naprawionych, 25 zniknęło ze starym kodem, 4 świadomie odłożone, 23 otwarte (12 częściowo); wszystkie P0 zamknięte. Przy okazji ok. 20 drobnych poprawek (m.in. podwójny zapis z SetPada C-12, haptyka pierwszej celebracji A-9, odmiana „do pierwszych 5 s” A-13, podglądy tylko na danych w pamięci, testy zmiany czasu B-16). Testy: 859 (1313 przypadków).
- **Jakość przed TestFlightem, krok F5 fundamentu** (`9d340c9`…`ccc1023`, 2026-11-04): **fundament F0–F5 jest zrobiony.**
  - tekst rośnie z rozmiarem czcionki w ustawieniach (Dynamic Type), a przy dużych rozmiarach układy się przelewają (kafelki, wiersze, hero, onboarding) (E-1, F-10),
  - String Catalog z polskim jako językiem źródłowym, ok. 270 tekstów z view modeli przepuszczonych przez lokalizację; treści katalogów (ćwiczenia, programy, drabiny) dopiero przy drugim języku (E-14),
  - kontrast szarego tekstu zgodny z WCAG AA i warianty dla „Zwiększ kontrast”; apka zostaje tylko ciemna (E-15),
  - nagłówki sekcji dla VoiceOvera (E-13), przegląd etykiet przycisków i `onTapGesture` w całej apce (E-10, E-11),
  - reguły lintu z `project-rules.mdc` blokują CI; `swift-format` dalej tylko raportuje,
  - testy: 843 (1285 przypadków).
- **Ulubione ćwiczenia** (`f6ed20f`, `3ec8014`, 2026-11-04, prośba właściciela przy Q26/Q30): gwiazdka na ekranie ćwiczenia i w menu po przytrzymaniu; w każdym wyborze ćwiczeń najpierw „Ulubione” (w kolejności dodania), potem „Ostatnio” (do 5 z dziennika), potem wszystkie jak dotąd; ulubione w backupie; testy: 839 (1278 przypadków).
- **Swift 6, krok F3 fundamentu** (`22b8994`, 2026-11-04):
  - wszystkie targety w trybie Swift 6 z pełnym sprawdzaniem współbieżności, domyślna izolacja `MainActor` w apce, czysta domena oznaczona `nonisolated` (G-19),
  - koniec `ObservableObject`, Combine i `DispatchQueue`; `AppEnvironment` to zwykła klasa (D-10, D-11, D-12),
  - toast XP nie chowa nowszego toastu (D-13), szybki trening nie zapisze się dwa razy (D-15), view modele nie czytają plików w `init` (D-6, D-7); reszta znalezisk D była już naprawiona albo zniknęła ze starym kodem,
  - testy: 803 (1238 przypadków).
- **Tylko Parki z drążkiem albo poręczami** (`8f58aab`, 2026-11-04, „Model Parku i sprzętu”, Q28/Q29): świeże dane z OSM (2026-11-04), 233 Parki zamiast 330, 97 miejsc bez opisanego sprzętu wypadło; ID pozostałych Parków bez zmian, więc ulubione działają; „Sprzęt nieznany” usunięty z apki; testy: 800 (1235 przypadków).
- **Polski region i poprawki z przeglądu** (`e2e3335`…`c83865a`, 2026-11-04):
  - polski region deweloperski: daty, dni tygodnia, liczby i przyciski systemowe po polsku (G-3), nazwa apki „CaliPark”,
  - Home: pierścień celu tygodniowego zawsze w hero (pod „Rozpocznij”), powitanie według godziny („Dobrej nocy” w nocy), kalendarz serii od poniedziałku z nagłówkiem dni, ozdobne ikony ukryte przed VoiceOverem,
  - „Anuluj” zaraz po „Utwórz plan” usuwa plan, drugi plan z tego samego programu wymaga potwierdzenia,
  - toast XP pod paskiem nawigacji i ogłaszany VoiceOverowi, celebracja modalna (reszta E-13),
  - „Historia treningów”, trening z planu nazwany jak plan, linia „Skąd to kryterium?” bez skrótu, minione plany jednorazowe oznaczone „Minął · …”, zakresy liczb bez łamania linii,
  - testy: 798 (1233 przypadki).
- **Prawdziwa karta Parku** (`76b46c3`…`bb51815`, 2026-11-04, „Karta parku”):
  - kompaktowa karta (nazwa, okolica, odległość, etykieta „Z OSM”, ikony sprzętu, „Nawiguj”) i pełna karta jako arkusz w kolejności A, tylko z sekcjami, które wypełnia OSM: sprzęt z liczbą sztuk („Sprzęt nieznany” dla miejsc bez opisu), „Skąd te dane” z linkiem do OpenStreetMap, szczegóły (nawierzchnia, oświetlenie, dach, dostęp, godziny otwarcia po polsku),
  - zdjęcia, opinie, pogoda i zgłoszenia dojdą z backendem; bez atrap,
  - „Ulubione” na telefonie, bez Konta: serce na karcie, filtr na liście, w backupie (osobny commit `bb51815`, czeka na odpowiedź właściciela),
  - dostępność całej zakładki (nagłówki, etykiety ikon, odległość „od Ciebie”),
  - prototypy karty i wyglądu mapy usunięte (zrzuty zostają),
  - testy: 768 (1185 przypadków).
- **Przegląd wizualny nowych ekranów** (`c660092`, 2026-11-04): ok. 100 zrzutów od świeżej instalacji; onboarding, cel tygodniowy, przypomnienia, programy, eksport i import oraz kolejka celebracji działają. 8 poprawek: polskie nazwy sprzętu, „Usuń” zamiast „Delete”, alert importu z „Anuluj”, kafelki Profilu, podwójny przycisk w pustym szybkim treningu, atrybucja OSM, VoiceOver serii. Potwierdzone do zrobienia: angielskie daty mimo polskiego regionu (G-3), stały rozmiar czcionek (E-1), drobiazgi na Home. Testy: 773 (1190 przypadków).
- **Resztki Home** (`16467aa`, 2026-11-04, „Home w 1.0”):
  - preferencje modułów jako `@Observable` z `AppEnvironment`; zapisany układ użytkowników zostaje,
  - kolejność modułów zmienisz bez przeciągania: „Zmień kolejność” na ekranie wyboru modułów oraz akcje VoiceOver „Przesuń wyżej / niżej” z komunikatem o pozycji (E-12); przeciąganie ma podgląd i przyciemnia moduł,
  - nagłówki modułów mówią „rozwinięty / zwinięty” (część E-13),
  - usunięte atrapy i martwy kod: leaderboard, feed, `MockDataProvider`, nieosiągalna Społeczność, martwy tryb edycji (F-12),
  - testy: 736 (1125 przypadków).
- **Dane na lata, krok F4 fundamentu** (`e3e2a39`, 2026-11-04):
  - pliki treningów przeniesione z Documents do `Application Support/CaliPark/`; migracja przy starcie przenosi plik tylko, gdy w nowym miejscu go nie ma, a przy błędzie apka czyta stary plik (C-15),
  - jedno `DefaultsKey` na klucze `UserDefaults` (C-15), martwe Core Data usunięte razem z pustym plikiem bazy (C-10, G-25),
  - plan jednorazowy nie zapisze się z datą w przeszłości (B-8); dni planów zapisane jako dzień kalendarza, więc nie przesuwają się po zmianie strefy czasowej, stary format dalej się czyta, backup w wersji 2 (B-9),
  - testy: 722 (1103 przypadki).
- **Mapa Parków z OSM** (`34554ab`, `d1d1736`, 2026-11-04, „Wygląd mapy parków”, „Model Parku i sprzętu”, „Import z OSM i otwarte dane Parków (ODbL)”, „Plan fundamentu”):
  - skrypt `scripts/osm/build_parks_snapshot.py` (jedno zapytanie Overpass) daje 330 Parków z OSM (stan 2026-11-03), wbudowanych w apkę i opublikowanych w `data/` na ODbL,
  - nowy model Parku z 012, nazwy tylko z OSM (np. „Drążki · Park Jordana”, „Street workout · …”), stabilne ID,
  - zakładka „Siłownie”: wyciszona mapa (wariant A), grupowanie, karta jako arkusz z „Z OSM” i „Nawiguj”, przełącznik mapa/lista, wyszukiwanie bez polskich znaków (E-5, D-9), atrybucja OSM,
  - o lokalizację pytamy dopiero przy pierwszym otwarciu mapy; przy odmowie cała Polska bez udawanej pozycji,
  - stare Parki z mockami usunięte (C-3, E-8, E-9, E-18, F-9, C-14, F-V1, G-V1, D-5), moduł Home „Najbliższy Park” z prawdziwym Parkiem,
  - nie zrobione: własne ikony sprzętu, ulubione Parki, pola z backendu (woda, WC),
  - testy: 690 (1066 przypadków).
- **Profil, onboarding, eksport i import** (`89a3528`, 2026-11-04, „Profil i ustawienia w 1.0”, „Onboarding w 1.0”):
  - Profil: statystyki (treningi, seria dni z rekordem, seria tygodni, poziom i XP), cel tygodniowy z edytorem, historia, eksport i import, „Pomoc i opinie”, „O apce” ze źródłami i OSM/ODbL; bez „Michała” na Home (E-4, G-V2),
  - eksport do jednego pliku `calipark-backup-RRRR-MM-DD.json`; import sprawdza cały plik, pokazuje podsumowanie i zastępuje dane „wszystko albo nic”, bez fałszywych celebracji,
  - onboarding: powitanie → test poziomu → program → cel tygodniowy (1–7 dni, domyślnie z programu); bez pytania o cele, lokalizacji i „Mam gumę”,
  - nie zrobione: prawdziwy adres w „Pomoc i opinie” (na razie `kontakt@calipark.example`), ulubione Parki poza backupem do czasu nowych Parków,
  - testy: 650 (1002 przypadki).
- **Jeden dziennik, krok F2 fundamentu** (`688ee1e`, 2026-11-04):
  - `TrainingJournal` to jedyne miejsce zapisu treningów (SetPad, szybki trening, historia, Home, arkusz szczebla); `ProgressService` liczy postęp raz na zmianę dziennika (F-3, F-6, A-11),
  - `RewardCenter`: jedna kolejka celebracji dla szczebli, poziomów i celu tygodniowego; koniec podwójnego toastu XP, a ostatnia celebracja pokazuje sumę „Razem +N XP” (F-4, D-V1, A-10),
  - to samo ćwiczenie dwa razy w jednym treningu liczy się do awansu (A-5), holdy zapisane jako powtórzenia liczą się jako sekundy (A-8), arkusz szczebla pokazuje świeży wynik (A-12, E-19), jeden `MeasureFormat` (F-13),
  - testy: 605 (951 przypadków).
- **Cel tygodniowy** (`8d07335`, 2026-11-04, „Cel tygodniowy”):
  - 1–3 cele (dni treningowe, treningi z planów albo „wszystkie zaplanowane”, objętość ćwiczenia), jeden główny; każda zmiana to nowa wersja, zamknięte tygodnie liczą się według swojej,
  - pierwszy niepełny tydzień rozgrzewkowy, pauza 1–90 dni, tydzień z pauzą neutralny (chyba że cel i tak zrobiony),
  - hero: pierścień celu głównego i seria tygodni (seria dni została tylko w module „Seria dni”); moduł „Cel tygodniowy” do przestawiania; edytor po przytrzymaniu pierścienia; celebracja bez XP,
  - bez zapisanego celu działa domyślne 3 dni; mock „75 podciągnięć” usunięty,
  - nie zrobione: „wszystkie zaplanowane” dla zamkniętych tygodni liczy według dzisiejszych planów; onboarding i Profil jeszcze bez edytora celu,
  - testy: 575 (921 przypadków).
- **Gotowe programy** (`3bbf358`, 2026-11-04, „Gotowe programy treningowe w 1.0”):
  - Minimum, Fundamenty, Pierwsze podciągnięcie i Skille jako szablony z podpisem źródła; `docs/PROGRAMS.md` i `ProgramCatalog` 1:1,
  - „Gotowe programy” w planerze: podgląd na Twoich szczeblach i „Utwórz plan”, który daje zwykły plan do edycji z `programID` i wersją,
  - nowe opcjonalne pola planu (drabina, zakresy, holdy, przerwy, pary i obwody), stare pliki dalej się wczytują, koperta zostaje w wersji 1,
  - trening z planu idzie na aktualnym szczeblu drabiny; holdy podpowiadają sekundy (część A-8),
  - onboarding: krok „Program na start” po teście poziomu,
  - nie zrobione: podpowiedź przejścia z „Pierwszego podciągnięcia” do „Fundamentów”, pary i obwody na ekranie treningu, reszta A-8,
  - testy: 482 (800 przypadków).
- **Przypomnienia bez zrobionych dni** (`78df41e`, `8a8a469`, 2026-11-04):
  - przypomnienia na konkretne daty zamiast powtarzanych, maks. 64 najbliższe; dzień, w którym plan jest zrobiony, nie dostaje przypomnienia,
  - zapis albo usunięcie treningu od razu przelicza przypomnienia, a odświeżanie w tle (`BGAppRefreshTask`) dokłada je raz na dobę,
  - granica: przy 3 planach po 3 dni w tygodniu przypomnienia sięgają ok. 7 tygodni naprzód, jeśli apka nie zostanie otwarta, a iOS nie uruchomi odświeżania w tle,
  - testy: 501 (822 przypadki).
- **Planer: zaliczenie planu i przypomnienia** (`bfb3796`, 2026-11-04):
  - plan jest zaliczony na dany dzień, gdy któryś wpis z tego dnia ma jego id; Home proponuje następny niezaliczony plan na dziś, a po wszystkich pokazuje „Dziś · Zrobione” (B-5),
  - przełącznik „Przypomnienie” i godzina w edytorze planu, zgoda pytana dopiero przy pierwszym włączeniu, a przy odmowie krótkie wyjaśnienie z linkiem do Ustawień („Przypomnienia o treningu w 1.0”),
  - `WorkoutPlanService` zapisuje i usuwa plany oraz synchronizuje przypomnienia po każdej zmianie, przy starcie i powrocie do apki; uszkodzony plik planów nie kasuje przypomnień,
  - scheduler: limit 64 powiadomień (najbliższe pierwsze), kolejne zmiany się nie przeplatają, błędy trafiają do logów, bez `.badge` (B-7),
  - nie zrobione: B-8 (plan jednorazowy z datą w przeszłości), B-9 (strefa czasowa),
  - testy: 393 (656 przypadków).
- **CI, krok F0 fundamentu** (`449024e`, `45de40c`, `3b5dd4a`, 2026-11-04):
  - GitHub Actions na każdym pushu na `main` (poza samymi dokumentami): build i testy jednostkowe na `macos-26` z Xcode 26.6, zero warningów albo czerwono (G-7),
  - lint na razie tylko raportuje: reguły z `project-rules.mdc` z bazową liczbą naruszeń (122× `foregroundColor` itd.) i `swift-format` (G-18),
  - pierwszy run wyłapał linię, której starszy kompilator nie przepuszczał; poprawione.
- **Prototyp mapy** do „Wygląd mapy parków” (`bb42651`, `2e553c8`): tylko w buildzie Debug.
- **Prototyp zgłoszenia Parku** do „Formularz zgłoszenia parku” (`19d525a`, 2026-11-04): tylko w buildzie Debug (argument `-PrototypeParkSubmission`), dwa układy formularza (A · Kroki, B · Jeden arkusz), 24 zrzuty w [prototypes/park-submission](prototypes/park-submission/README.md).
- **Prototyp karty Parku** do „Karta parku” (`0ffae07`, 2026-11-04): tylko w buildzie Debug (`-PrototypeParkCard`), karta kompaktowa i pełna jako arkusz, 4 stany Parku, dwie kolejności sekcji, zgłaszanie poprawek i treści; 31 zrzutów w [prototypes/park-card](prototypes/park-card/README.md).
- **Propozycje do potwierdzenia:** drabiny i programy (`29e6d99`), model Parku i wiek Konta (`824e987`).

## Jeszcze nieokreślone

Wyjęte z mgły 2026-11-04 jako tickety: [Karta parku](tickets/023-park-card.md), [Home w 1.0](tickets/024-home-v1.md), [Profil i ustawienia w 1.0](tickets/025-profile-settings-v1.md), [Onboarding w 1.0](tickets/026-onboarding-v1.md), [Cel tygodniowy](tickets/027-weekly-goal.md).

- **Identyfikacja wizualna:** ikona wybrana (Q38, „Drabinka”), spójny styl przycisków i promieni zrobiony; zostaje dopracowanie stylu całej apki, czyli to samo „stylowo” co przy mapie.
- **Diagnostyka:** zdecydowana (Q33, tylko Apple + MetricKit); analityka poza zakresem 1.0.
- **Wydanie:** strona startowa apki (Vercel, Q32) z polityką prywatności, regulaminem i adresem kontaktowym (ten sam adres trafi do „Pomoc i opinie”, Q25); opis, screeny (od kwietnia 2027 także iPhone Duo) i kategoria w App Store; zbieranie feedbacku od ekipy z TestFlight.
- **Zasady Społeczności i regulamin:** treść regulaminu (zero tolerancji, licencja na treści, wymogi DSA), powiadamianie autorów o wyniku moderacji, blokowanie użytkowników. Zależy od wyboru backendu i minimalnego wieku Konta.

## Poza zakresem

- Model monetyzacji i ceny. Decyzja zapada po starcie, gdy będzie wiadomo, czy ludziom się podoba; v1 jest darmowe ([Zakres CaliPark 1.0](tickets/001-zakres-1-0.md)).
- Tłumaczenia na angielski i ukraiński. Wchodzą po starcie; w zakresie jest tylko infrastruktura String Catalog ([Zakres CaliPark 1.0](tickets/001-zakres-1-0.md)).
- Wydarzenia, tłok, feed i leaderboard, które przechodzą do v1.1 ([Zakres CaliPark 1.0](tickets/001-zakres-1-0.md)).
- iPad i orientacja pozioma ([Zakres CaliPark 1.0](tickets/001-zakres-1-0.md)).
