# Propozycja: gotowe programy treningowe w 1.0

Ticket: [016 Gotowe programy treningowe w 1.0](../tickets/016-programs-v1.md). Podstawa: [research ze źródłami](../../research/progressions-programs.md), §6. Drabiny w wersji z [propozycji 015](015-ladders.md).

Status: **propozycja do akceptacji**. Kod nie jest zmieniony. Wszystkie opisy w apce piszemy sami, po polsku, bez tłumaczenia tekstu źródeł.

## W skrócie

| Program | Dla kogo | Dni / tydz. | Czas | Na dzisiejszych drabinach? | Rekomendacja na 1.0 |
|---|---|---|---|---|---|
| **Minimum** | mało czasu, start, zdrowie | 3 (siła) albo codziennie | ok. 15–25 min *(szacunek)* | tak, brakuje jednego ćwiczenia (deska z dotknięciem barku) | **tak, pierwszy** |
| **Fundamenty** | początkujący i średni, pełny trening siłowy | 3, z dniem przerwy | ok. 45–60 min | tak, w wersji „inspirowane RR” | **tak** |
| **Pierwsze podciągnięcie** | 0–3 czyste podciągnięcia | 3 | ok. 30–40 min *(szacunek)* | tak | **tak** |
| **Skille** | dodatek: stanie na rękach i L-sit | 2–3 | ok. 15–20 min *(szacunek)* | tak, potrzebuje bloków na czas | **tak, jeśli zdążymy**; wycinamy jako pierwszy |

Każdy program wskazuje **drabinę**, nie konkretne ćwiczenie. W dniu treningu apka podstawia aktualny szczebel użytkownika. Kiedy ktoś awansuje, program sam „rośnie” razem z nim, a zasadą awansu pozostaje kryterium szczebla (3 × 8 itd., patrz 015).

## Wspólne zasady

- **Progresja w obrębie szczebla (RR):** zaczynasz od najtrudniejszego szczebla, który robisz w 3 × 5. Na każdym treningu dokładasz po jednym powtórzeniu na serię, aż dojdziesz do 3 × 8. Wtedy przechodzisz na następny szczebel i znowu zaczynasz od 3 × 5. Kończysz serię z około jednym powtórzeniem w zapasie. Jeśli powtórzenia spadają między seriami, odpoczywasz do 3 min. Źródło: [RR][rr].
- **Holdy:** 3 serie po 10–30 s. Awans przy kryterium szczebla.
- **Jak użytkownik wybiera program:**
  - w Plannerze jest sekcja „Gotowe programy”;
  - po teście startu (placement) apka podpowiada jeden program: 0 podciągnięć → Pierwsze podciągnięcie, w pozostałych przypadkach Fundamenty, a Minimum jako opcja „mam mało czasu”;
  - wybór tworzy zwykły `WorkoutPlan` z harmonogramem (np. pn/śr/pt), który można edytować, z zapisanym pochodzeniem (`programID`).
- **Licencja:** metoda, kolejność i serie/powtórzenia są wolne do użycia (research §7). Nazwy programów są nasze. Nigdy nie piszemy „oficjalny RR”. Programy oparte na RR zostają darmowe, a moderatorzy RR odcinają się od płatnych aplikacji z RR.
- **Bezpieczeństwo:** potrzebna jest krótka notka „przerwij przy bólu; skonsultuj się z lekarzem przy problemach zdrowotnych”. Research tego nie sprawdzał; należy to do ticketu compliance.

## Program 1: „Minimum”

**Źródło:** Minimalist Routine z wiki r/bodyweightfitness ([min][minr]), która wywodzi się z „Concept Wednesday” użytkownika /u/m092.
**Dla kogo:** ktoś, kto zaczyna, ma 20 minut albo chce trenować dla zdrowia. Najtańszy program do zbudowania i dobry na start TestFlightu.
**Dni:** 3 × w tygodniu na siłę albo codziennie dla zdrowia (źródło podaje oba warianty).

**Sesja:** obwód, czyli 4 ćwiczenia jedno po drugim bez przerwy. Robisz 2–6 obwodów. Przerwa między obwodami wg potrzeby, ok. 1–2 min *(szacunek CaliPark)*.

| Kolejność | Drabina | Szczebel | Seria |
|---|---|---|---|
| 1 | `legs` | od wykroków (albo niższy, jeśli tam jesteś) w górę | 1–2 powtórzenia przed upadkiem mięśniowym, na nogę |
| 2 | `pushUp` | aktualny | 1–2 przed upadkiem |
| 3 | `row` | aktualny | 1–2 przed upadkiem |
| 4 | — | deska z dotknięciem barku (**nowe ćwiczenie**, poza drabiną) | 1–2 przed upadkiem, na stronę |

**Progresja:** źródło każe przejść dalej przy „co najmniej trzech seriach po 8–10 powtórzeń”. To się zgadza z kryterium 3 × 8, więc awans liczy zwykły silnik drabin.
**Linia z podziękowaniem:** „Na podstawie Minimalist Routine z wiki r/bodyweightfitness. CaliPark nie jest z nią powiązany.”
**Brakuje w apce:** obwodu jako grupy, liczby rund (2–6) zamiast stałej liczby serii, celu „X w zapasie” zamiast stałych powtórzeń oraz ćwiczenia „Deska z dotknięciem barku” (`plankShoulderTapsID`, powt. na stronę, wariant `plankID`).
**Zależność:** wykroki muszą zostać w drabinie `legs`. Propozycja 015 je zostawia.

## Program 2: „Fundamenty”

**Źródło:** Recommended Routine ([RR][rr]): 3 × w tygodniu, co najmniej jeden dzień przerwy między treningami, „about an hour”.
**Dla kogo:** początkujący i średniozaawansowani, którzy chcą pełnego treningu siłowego całego ciała. Osoby z 0 podciągnięciami dostają podpowiedź, żeby zacząć od „Pierwszego podciągnięcia”.
**Dni:** pn/śr/pt albo inne 3 dni z przerwą. Dla zupełnie początkujących RR pozwala na 1–2 serie, 2 dni w tygodniu albo tylko 1 ćwiczenie na pchanie, 1 na ciągnięcie i 1 na nogi.

**Sesja (wersja „inspirowane RR”, na obecnych drabinach):**

| Blok | Drabiny (aktualny szczebel) | Serie | Przerwa |
|---|---|---|---|
| Rozgrzewka | własna treść CaliPark, 5–10 min | — | — |
| Para 1 | `pullUp` ↔ `legs` | 3 × 5–8 każde, na przemian | 90 s po każdej serii |
| Para 2 | `dip` ↔ `core` | 3 × 5–8 / holdy 3 × 10–30 s | 90 s |
| Para 3 | `row` ↔ `pushUp` | 3 × 5–8 każde | 90 s |

- Kto nie ma poręczy albo wybiera stanie na rękach, może zamienić `dip` na szczeble pchania z drabiny `handstand` (pompki pike i wyżej, patrz 015). RR podaje pompki w staniu jako ścieżkę alternatywną dla pompek i dipów.

**Wersja „wierna RR” (opcja, patrz pytanie 2):** para 2 to `dip` ↔ **zawias biodrowy**, a na koniec dochodzi trójka core: `core` ↔ **antyrotacja** ↔ **ekstensja**, 3 × 8–12, przerwa 60 s. Wymaga trzech nowych drabin:

| Nowa drabina | Szczeble wg RR | Sprzęt | Uwaga |
|---|---|---|---|
| Zawias biodrowy | martwy ciąg rumuński → martwy ciąg na jednej nodze → negatywy nordyckie z gumą → nordyckie z gumą → nordyckie ([hinge][rrhinge]) | Resistance bands przy 2 szczeblach; stopy zaczepione pod ławką albo niskim drążkiem | RR ma ścieżki alternatywne bez gumy (hamstring slides, Harop curls) |
| Antyrotacja | Pallof press z gumą (główna). Alternatywa: seria Copenhagen plank ([core][rrcore]) | Resistance bands albo ławka | dokładne szczeble alternatywy trzeba spisać ze strony RR przy implementacji |
| Ekstensja | reverse hyperextension na ławce. Alternatywa: arch raises → arch body hold → arch body rocks ([core][rrcore]) | ławka | — |

Koszt wersji wiernej: ok. 10–12 nowych ćwiczeń i trzy nowe ruchy główne. Łamie to zasadę integralności nr 6 („dokładnie 19 ruchów głównych”), więc trzeba by ją świadomie zmienić. Dwa szczeble zawiasu i główna antyrotacja wymagają gumy.

**Progresja:** zasada RR z „Wspólnych zasad”. Awans szczebla liczy silnik drabin.
**Linia z podziękowaniem:** „Struktura na podstawie Recommended Routine społeczności r/bodyweightfitness. Program nie jest oficjalny ani zatwierdzony przez jej autorów.” Wersja bez zawiasu i pełnego core ma dopisek „inspirowane”.
**Brakuje w apce:** odwołania do drabiny, zakresu powtórzeń, czasu dla holdów, przerwy i par (patrz [Czego brakuje w modelu planu](#czego-brakuje-w-modelu-planu)). Do tego podpowiedzi „+1 powtórzenie na serię względem ostatniego treningu”.

## Program 3: „Pierwsze podciągnięcie”

**Źródło:** to nasza kompozycja z zasad RR ([pull-up][rrpull]), StartBodyweight ([pull-up][sbwpull]) i Cali Move ([challenge][cmpull]). Nie jest to opublikowany program, a struktury płatnego „8 Weeks Pull Up Challenge” nie kopiujemy.
**Dla kogo:** 0–3 czyste podciągnięcia. Apka podpowiada ten program, gdy w teście startu padnie „0” przy podciąganiu.
**Dni:** 3 × w tygodniu, z dniem przerwy.

| Kolejność | Drabina | Co robisz na swoim szczeblu | Źródło |
|---|---|---|---|
| 1 (na świeżo) | `pullUp` | zwis 3 × 10–30 s; ściąganie łopatek 3 × 5–8 z pauzą 3–5 s; arch hang 3 × 5–8; negatywy 3 × 3–5 ze zjazdem 5–10 s; podciągnięcia 3 × 5–8 | RR, SBW (zjazd 5 s) |
| 1a (opcja) | `pullUp`, tor równoległy | podciągnięcia z gumą, która pozwala na ok. 4–8 powtórzeń | Cali Move |
| 2 | `row` | 3 × 5–8 | RR: wiosłowania „nie da się zastąpić”; SBW: ciągnięcie poziome i pionowe „pomagają sobie nawzajem” |
| 3 | `pushUp` ↔ `legs` | 3 × 5–8 każde, w parze, 90 s przerwy | RR |

**Progresja:**

- awans szczebla jak w drabinie;
- przy więcej niż 3 czystych podciągnięciach znikają negatywy, bo według Cali Move od tego momentu nie są już tak skuteczne;
- **wyjście:** przy 3 × 8 podciągnięć apka proponuje przejście na Fundamenty.

**Linia z podziękowaniem:** „Program CaliPark oparty na zasadach z Recommended Routine (r/bodyweightfitness), StartBodyweight i Cali Move.”
**Brakuje w apce:** to samo co w Fundamentach. Do tego wskazówka wykonania przypisana do szczebla (pauza, tempo zjazdu) i reguła wyjścia z programu.
**Związek z 015:** ten program to odpowiedź na „ścieżka podciągania jest wymyślona”. Każdy szczebel i liczba w nim ma źródło. Zwis na drążku jest opisany jako konwencja CaliPark.

## Program 4: „Skille” (dodatek)

**Źródło:** bloki A i B pochodzą z Skill Day z wiki r/bodyweightfitness ([skill][skillday]). Blok C opiera się na tabeli izometrii OG2 ([tabela][ogtable]) i artykule Stevena Lowa ([plateau][ogplateau]).
**Dla kogo:** dodatek do Fundamentów albo Pierwszego podciągnięcia dla osób, które chcą stania na rękach i L-situ. Warunek RR przed staniem na rękach to 30 s deski.
**Dni:** 2–3 × w tygodniu, w dni wolne od siły albo przed treningiem siłowym (RR dopuszcza oba warianty).

| Blok | Drabina | Na sesji | Awans |
|---|---|---|---|
| A. Stanie na rękach | `handstand`, tylko szczeble trzymane (podpór przy ścianie, potem stanie przy ścianie) | 5–10 min praktyki, przerwy wg potrzeby | kryterium szczebla (3 × 30 s) |
| B. L-sit | `lSit`, aktualny | łącznie 2–3 min holdów po 10–30 s | kryterium szczebla (3 × 20 s); RR przechodzi dalej przy 30 s |
| C. Jedna statyka (opcja, **w dni siłowe**, nie w Skille) | `frontLever`, `backLever`, `planche` albo `humanFlag` | test maksymalnego holdu, potem serie × czas z tabeli OG2, np. max 10 s → 5 × 7 s, max 20 s → 4 × 14 s, max 30 s → 3 × 20 s | 3 × 20 s, czyli kryterium szczebla |

- **Blok C nie należy do Skill Day.** RR wprost wyklucza z niego dźwignie, planche i flagę jako „strength skills”. Dlatego C dopinamy do dni siłowych i podpisujemy jako OG2, nie RR. W danym czasie trenujemy jedną statykę *(konwencja CaliPark)*.
- **Szczeble pchania z drabiny `handstand`** (pompki pike i wyżej) to siła, więc trafiają do Fundamentów, nie do Skilli.
- Tabeli OG2 nie odtwarzamy jako obrazka. W kodzie implementujemy regułę „60–70% maksymalnego czasu” plus liczby serii z tabeli i podajemy źródło.

**Linia z podziękowaniem:** „Bloki stania na rękach i L-situ na podstawie Skill Day z wiki r/bodyweightfitness. Statyki według zasad Stevena Lowa (Overcoming Gravity).”
**Brakuje w apce:** bloku na czas („5–10 min”), celu w sumie sekund („2–3 min”), wyboru tylko szczebli trzymanych z drabiny, a dla bloku C także testu maksymalnego holdu i reguły z tabeli.
**Rekomendacja:** w 1.0 bloki A i B. Blok C w 1.1.

## Czego brakuje w modelu planu

Dziś `PlannedExercise` (`cali-park/Features/Planner/Models/PlannedExercise.swift`) ma tylko stałe `exerciseID`, `targetSets?` i `targetReps?`. `WorkoutPlan` ma nazwę, listę, harmonogram i przypomnienie. Harmonogram (`WorkoutSchedule.weekly`) już obsługuje „3 × w tygodniu” i „codziennie”.

| Brak | Potrzebne w | Propozycja (wszystkie pola opcjonalne, więc stare pliki się wczytają) |
|---|---|---|
| odwołanie do drabiny | wszystkie | `PlannedExercise.pathID: ProgressionPathID?`. Przy starcie sesji podstawiamy aktualny szczebel z `ProgressionEngine`. |
| zakres powtórzeń | Fundamenty, Pierwsze podciągnięcie | `targetRepsMin: Int?` obok `targetReps` |
| czas dla holdów | wszystkie | `targetSeconds: Int?`. Dziś `QuickWorkoutViewModel` wpisuje do holdów powtórzenia (audyt A-8), więc to trzeba naprawić przy okazji. |
| przerwa | Fundamenty, Pierwsze podciągnięcie | `restSeconds: Int?` |
| para lub obwód | Minimum, Fundamenty, Pierwsze podciągnięcie | `group: Int?` (ten sam numer to ta sama para lub obwód) oraz `rounds: ClosedRange<Int>?` dla obwodu |
| cel „X w zapasie” | Minimum | `repsInReserve: Int?` |
| blok na czas i suma sekund | Skille | `timeBoxMinutes: Int?`, `totalSeconds: Int?` |
| na stronę | Minimum, nogi, L-sit | flaga `isUnilateral` przy ćwiczeniu (z 015), nie w planie |
| wskazówka wykonania (pauza, tempo) | Pierwsze podciągnięcie | przy szczeblu lub ćwiczeniu w katalogu, nie w planie |
| pochodzenie programu | wszystkie | `WorkoutPlan.programID: String?`, `programVersion: Int?`. Pozwalają pokazać linię z podziękowaniem, zaktualizować szablon i zaproponować wyjście z programu. |
| podpowiedź „+1 powtórzenie” | Fundamenty, Pierwsze podciągnięcie | czysta funkcja w nowym enumie (np. `ProgramPrescriber`) liczona z ostatniego logu, tak jak `ProgressionEngine` |

Same programy żyją w kodzie jako statyczny katalog (`ProgramCatalog`, wzorem `ProgressionCatalog`) plus dokument-prawda `docs/PROGRAMS.md`, synchronizowany 1:1. Nowe pola `WorkoutPlan` i `PlannedExercise` trzeba dodać **przed** pierwszym buildem TestFlight z syncem, bo ten build zamraża schemat ([003](../tickets/003-sync-research.md), [009](../tickets/009-sync-tech.md)).

## Pytania do właściciela

1. **Które programy w 1.0?** *Rekomendacja: Minimum, Fundamenty i Pierwsze podciągnięcie na pewno. Skille (bloki A i B) jeśli zdążymy, i wycinamy je jako pierwsze. Blok statyk z testem OG2 w 1.1.*
2. **Fundamenty „inspirowane RR” (obecne drabiny) czy „wierne RR” (3 nowe drabiny: zawias, antyrotacja, ekstensja, ok. 10–12 ćwiczeń, część z gumą)?** *Rekomendacja: w 1.0 „inspirowane RR” z uczciwym dopiskiem, a drabinę zawiasu dodać w 1.1. Najmniej pracy przy tej samej wartości dla początkujących.*
3. **Jak użytkownik dostaje program: edytowalna kopia jako zwykły plan w Plannerze czy zablokowany szablon?** *Rekomendacja: edytowalna kopia z zapamiętanym pochodzeniem. Planner już to obsługuje, a użytkownik może dopasować dni.*
4. **Czy test startu ma podpowiadać program** (0 podciągnięć → Pierwsze podciągnięcie, w przeciwnym razie Fundamenty)? *Rekomendacja: tak, jako podpowiedź z możliwością zmiany, bez wymuszania.*
5. **Nazwy programów: „Minimum”, „Fundamenty”, „Pierwsze podciągnięcie”, „Skille” — zostają?** *Rekomendacja: tak. Są nasze, po polsku i nie sugerują oficjalnego RR.*

[rr]: https://www.reddit.com/r/bodyweightfitness/wiki/kb/recommended_routine/
[rrpull]: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/pullup/
[rrhinge]: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/hinge/
[rrcore]: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/core/
[minr]: https://www.reddit.com/r/bodyweightfitness/wiki/minroutine
[skillday]: https://www.reddit.com/r/bodyweightfitness/wiki/kb/skillday
[sbwpull]: http://www.startbodyweight.com/p/pull-up-progression.html
[cmpull]: https://blog.calimove.com/2023/05/11/8-weeks-pull-up-challenge/
[ogtable]: https://stevenlow.org/wp-content/uploads/2016/12/isometrictable.jpg
[ogplateau]: https://stevenlow.org/how-to-program-for-advanced-isometric-movements-after-a-plateau/
