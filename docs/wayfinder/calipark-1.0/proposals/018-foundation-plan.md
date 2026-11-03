# Propozycja: plan fundamentu przed TestFlightem z samym treningiem

Ticket: [018 Plan fundamentu](../tickets/018-foundation-plan.md). Podstawa: [audyt](../../../audit/README.md), decyzje 010, 017, 019, 022.

Status: **propozycja**. Wybory techniczne (kolejność, Swift 6, CI, lint) właściciel oddał koordynatorowi, więc są tu już rozstrzygnięte. Do decyzji właściciela zostają tylko pytania produktowe na końcu.

## W skrócie

- **Już zrobione:** Faza 0 (pliki JSON bez cichego wipe'u, wersjonowanie, stabilne ID szczebli), privacy manifest, tylko iPhone w pionie, szkice, świeży Home, przypomnienia i `WorkoutPlanService` (B-5, B-7).
- **W toku:** rewizja drabin (015), potem programy (016).
- **Zostaje pięć kroków, F1–F5.** Żaden nie wymaga płatnego konta Apple. Konto (017) jest potrzebne dopiero do samego uploadu na TestFlight.
- **CI od razu na GitHub Actions** (repo jest publiczne, więc runnery macOS są darmowe). Xcode Cloud dopiero po zakupie konta i tylko do wysyłki buildów na TestFlight.
- **Lint bez zewnętrznych zależności:** `swift format lint`, który jest w Xcode, plus kilka prostych reguł w CI (np. zakaz `foregroundColor` i `cornerRadius`).

## Kroki

| Krok | Co | Znaleziska | Zależy od | Równolegle z |
|---|---|---|---|---|
| **F0 · CI** | GitHub Actions: build + testy jednostkowe na każdym pushu na `main`; `swift format lint` i reguły z `project-rules.mdc` jako osobny job, najpierw tylko raport, potem blokada | G-7, G-18 | nic | wszystkim |
| **F1 · Apka bez mocków** | wycięcie mocków i martwego kodu z buildu TestFlight z samym treningiem: Premium bez StoreKit, nieosiągalna Społeczność, `CalendarService`, hotlinki Unsplash, fałszywa pogoda, „Michał” i sztywny cel tygodniowy, losowy „tłok”, martwy Core Data. Zakładka Parków zgodnie z pytaniem P1. Home, Profil i onboarding według ticketów 024–026 | E-2, F-2, G-2, E-4, G-5, C-3, E-7, G-V1, G-V2, C-V1, F-V1, F-12, C-10, G-25 | decyzje 024–026 | F0 |
| **F2 · Jeden dziennik** | `TrainingJournal` (jedno miejsce zapisu treningu), `ProgressService` (postęp liczony raz na zmianę dziennika), jeden `RewardCenter` (koniec podwójnego toastu XP), wspólny `MeasureFormat` | F-3, F-4, F-6, F-13, A-5, A-10, A-11, A-12, D-V1 | programy (016) zmergowane | F0 |
| **F3 · Swift 6** | ścieżka z audytu: najpierw `SWIFT_STRICT_CONCURRENCY=complete` i domyślna izolacja `MainActor` na Swift 5, potem `nonisolated` dla domeny, `@Observable` zamiast `ObservableObject`, na końcu `SWIFT_VERSION=6` | D-1…D-19, G-19 | F1 (mniej kodu do migracji), F2 | F0 |
| **F4 · Dane na lata** | przeniesienie plików z Documents do Application Support z migracją, eksport i import treningów do jednego pliku (P3), B-8 i B-9 | B-8, B-9, P1 audytu | F2 | F5 |
| **F5 · Jakość przed TestFlightem** | String Catalog i polski region deweloperski (daty i dni tygodnia po polsku), Dynamic Type, przyciski zamiast `onTapGesture`, etykiety ikon | G-3, E-14, E-1, F-10, E-10, E-11, E-12, E-13, E-15 | F3 | F4 |

**Dlaczego taka kolejność:**
- F1 idzie pierwsze, bo usuwa najwięcej kodu, a każdy następny krok ma wtedy mniej do przerobienia.
- F2 przed F3, bo nowe serwisy piszemy od razu pod Swift 6, zamiast migrować stare kopie.
- F2 i F3 nie mogą iść równolegle, bo dotykają tych samych view modeli.
- F5 po F3, bo String Catalog i Dynamic Type dotykają każdego widoku.

**Po F5 i zakupie konta (017):** bundle ID i team, ikona (identyfikacja wizualna), upload, TestFlight dla ekipy. Potem sync (Ad Hoc, 022) i Społeczność.

## Szacunek

Każdy krok to jeden worker na 1–2 dni, F3 może zająć dwa. Bez czekania na odpowiedzi: ok. 2 tygodnie do buildu gotowego na TestFlight. Dłużej potrwa tylko F1, jeśli 024–026 nie będą rozstrzygnięte.

## Pytania do właściciela

- **P1. Zakładka Parków w TestFlighcie z samym treningiem:**
  - schowana (rekomendacja: nie ma czego testować, a review betki nie lubi niedziałających ekranów),
  - ekran „Wkrótce”,
  - mapa tylko do odczytu z Parkami z OSM wbudowanymi w apkę (ok. 390 w Polsce, bez opinii i zgłoszeń; ok. 2–3 dni pracy).
- **P2. Nazwa zakładki „Siłownie” zmienia się na „Parki”**, zgodnie ze słownikiem. Rekomendacja: tak.
- **P3. Eksport i import treningów do pliku w 1.0:** jeden plik JSON przez arkusz udostępniania i wczytanie go z powrotem. Rekomendacja: tak, w Profilu. To jedyny backup do czasu syncu przez iCloud.
