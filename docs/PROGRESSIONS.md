# Ścieżki progresji kalisteniki — dokument-prawda

Ten dokument jest **jedynym źródłem prawdy** dla treści ścieżek progresji. Kod
(`ProgressionCatalog` + warianty w `ExerciseCatalog`) jest jego wiernym
odbiciem 1:1 — jeśli coś zmienia się tutaj, zmienia się i tam (i odwrotnie).
Kolejne sprinty (SK2–SK6) opierają się na tym dokumencie, nie na własnych
domysłach.

Plan źródłowy: [.cursor/plans/skill_tree_kalisteniki_4d366e3c.plan.md](../.cursor/plans/skill_tree_kalisteniki_4d366e3c.plan.md)
Tracker: [docs/SPRINTS-SKILLS.md](SPRINTS-SKILLS.md)

## Źródła

Drabiny nie są wymyślone. Każdy szczebel i każde kryterium ma etykietę źródła.
Kryterium bez źródła nazywamy uczciwie „konwencja CaliPark”. W razie
wątpliwości wybieramy wersję ze źródła, nie własną. Rewizja z 2026-11
(ticket 015, [propozycja](wayfinder/calipark-1.0/proposals/015-ladders.md),
[research](wayfinder/research/progressions-programs.md)) dodała 11 szczebli i
etykiety źródeł.

| Etykieta | Źródło |
|---|---|
| **RR** | Recommended Routine, wiki r/bodyweightfitness ([RR][rr], strony ćwiczeń: [pull-up][rrpull], [dip][rrdip], [squat][rrsquat], [push-up][rrpush], [row][rrrow]). Drabiny dynamiczne. Zasada przejścia: **3 × 8 czysto → następny szczebel** (start 3 × 5 na nowym). Zasada holdów: 30 s we wszystkich 3 seriach. |
| **OG2 L*n*** | Overcoming Gravity, 2. wydanie, Steven Low: poziom z chartu ([arkusz][ogsheet]). Kolejność szczebli statyk. Dodatkowa kolumna nóg w arkuszu jest oznaczona „not in the book”, więc piszemy „OG2 (arkusz)”. |
| **OG2 (tabela)** | tabela izometrii OG2 ([obraz][ogtable], [artykuł][ogpril]). Nasze **3 × 20 s** jest z niej **wyprowadzone**: to ostatni wiersz tabeli (max ≈ 30 s). Publiczne materiały OG nie podają tego jako reguły awansu. |
| **GMB** | 6 kroków L-situ ([snapshot][gmb]). |
| **SBW** | StartBodyweight ([routine][sbw], [pull-up][sbwpull]). |
| **Cali Move** | [8-tygodniowe wyzwanie podciągnięć][cmpull]. Bierzemy z niego tylko fakty o gumie i negatywach, nie strukturę programu. |
| **konwencja CaliPark** | nasza reguła, bez źródła. Pokazujemy ją jako naszą. |

W kodzie etykieta kryterium to `ProgressionStep.criterionSource`
(`CriterionSource`: `rr`, `og2`, `og2Table`, `gmb`, `sbw`, `caliMove`,
`caliPark`). Arkusz szczebla pokazuje ją jako „Skąd to kryterium?”. Źródło
samego szczebla (kolumna „Źródło szczebla”) jest tylko w tym dokumencie.

## Jak czytać kryteria

Każdy szczebel ma **kryterium**, czyli cel, który uznajemy za jego zaliczenie:

| Kryterium | Gdzie | Etykieta |
|---|---|---|
| `3 × 8` | szczeble dynamiczne | RR (SBW tak samo) |
| `3 × 30 s` | holdy wejściowe (zwis, podpór, german hang, żabka, ściana, deska) | RR |
| `3 × 20 s` | statyki dźwigni, planche, flagi, L-situ | OG2 (tabela), wyprowadzone |
| `3 × 5`, `3 × 3` | negatywy, ruchy jednostronne, przejścia muscle-upa | konwencja CaliPark (RR stosuje 3 × 5–8 wszędzie; niższe cele są celowe) |
| `pierwsze czyste`, `pierwsze 5 s` | pełne dźwignie, planche, flaga, strict muscle-up | konwencja CaliPark: marker opanowania („masz to”), żadne źródło go nie definiuje |
| `1 × 60 s` | podpór na kółkach | RR (warunek przed dipami na kółkach) |

- Kryterium z jedną serią aplikacja czyta jako „pierwsze …”: `1 × 60 s` to
  „pierwsze 60 s”, czyli pierwsze utrzymanie 60 s.
- **Dopisek do kryterium** (`criterionNote`) mówi, jak musi wyglądać
  powtórzenie, gdy samo „3 × 5” tego nie powie: „zjazd 5–10 s” przy negatywach
  (RR każe dojść do 10 s, SBW stosuje 5 s), „pauza 3–5 s na górze” przy
  ściąganiu łopatek. Tempa nie liczymy, kryterium zostaje w powtórzeniach.
- **Ruchy jednostronne** (`Exercise.isUnilateral`) liczymy na stronę:
  „3 × 5 na rękę”, „3 × 8 na nogę”, „3 × 20 s na stronę”. Wpisujesz wynik
  słabszej strony. Format logów się nie zmienia; osobne logowanie lewej i
  prawej strony to przyszła zmiana schematu.
- **Wskazówka** (`tip`) przy szczeblu jest niewiążąca, nigdy nie jest warunkiem.

Sprzęt zapisujemy kluczami spójnymi z `Park.equipments`. Starsze klucze są
angielskie (`Pull-up bar`, `Dip bar`, `Parallel bars`, `Rings`,
`Push-up handles`, `Resistance bands`, `Monkey bars`), nowe to wartości OSM z
[modelu Parku](wayfinder/calipark-1.0/proposals/012-park-model.md)
(`fitness_pole` „Pionowy drążek”, `wall_bars` „Drabinki gimnastyczne”).
`Monkey bars` ma etykietę „Drabinka pozioma”. Lista sprzętu szczebla znaczy
**„którykolwiek z”**: `Pull-up bar, Parallel bars` to drążek albo poręcze.
„—” znaczy masę ciała (ławka czy podwyższenie nie mają klucza).

**Tor równoległy** (`isParallelTrack`) to opcja, nie obowiązek: guma przy
podciąganiu i wejścia na podwyższenie przy nogach. Silnik nigdy nie robi z
niego aktualnego szczebla (pomija go przy wyborze następnego kroku), ale
zalogowany liczy się jak każdy inny szczebel.

Stany szczebla: **zaliczony** (z deklaracji placementu albo z logów),
**aktualny** (tu trenujesz), **przyszły** (widoczny, opisany, bez kłódek).
Wszystko poniżej najwyższego zaliczonego szczebla jest zaliczone. Drabina jest
mapą i miernikiem, nigdy bramką: logować i ustawiać jako aktualny można każdy
szczebel.

---

## Drabiny dynamiczne (kryterium bazowe: 3 × 8, RR)

### Podciąganie — `pullUp`

Ruch główny: **Podciągnięcia** (`pullUpsID`). Źródła: RR, OG2, SBW, Cali Move.

| # | Szczebel | Ćwiczenie | Kryterium | Źródło szczebla / kryterium | Sprzęt | Uwaga |
|---|---|---|---|---|---|---|
| 1 | Zwis na drążku | `deadHangID` (sek) | 3 × 30 s | konwencja CaliPark (przygotowanie chwytu) / RR | Pull-up bar | siła chwytu |
| 2 | Ściąganie łopatek w zwisie | `scapularPullsID` | 3 × 8, pauza 3–5 s na górze | RR / RR | Pull-up bar | aktywacja pleców |
| 3 | Zwis z wygięciem (arch hang) | `archHangID` | 3 × 8 | RR / RR | Pull-up bar | |
| 4 | Negatywy podciągnięć | `negativePullUpsID` | 3 × 5, zjazd 5–10 s | RR, OG2 L2 / konwencja CaliPark | Pull-up bar | fundament zero→jeden |
| 5 | Podciągnięcia z gumą | `bandPullUpsID` | 3 × 8 | Cali Move (guma na ok. 4–8 powtórzeń) / RR | Pull-up bar, Resistance bands | **tor równoległy** (opcja) |
| 6 | Pełne podciągnięcia | `pullUpsID` | 3 × 8 | RR, OG2 L3 / RR | Pull-up bar | ruch główny |
| 7 | L-pull-ups | `lPullUpsID` | 3 × 5 | RR (gałąź), OG2 L4 / konwencja CaliPark | Pull-up bar | + napięcie core |
| 8 | Podciągnięcia łucznicze | `archerPullUpsID` | 3 × 5 na rękę | RR (gałąź), OG2 L7 / SBW (≤ 6 na rękę) | Pull-up bar | krok do jednorącz |

- RR traktuje L-pull-ups i łucznicze jako dwie alternatywne gałęzie po 3 × 8
  podciągnięć. Zostawiamy jedną linię w kolejności poziomów OG2 (L4 → L7), bo
  drabina i tak nie blokuje żadnego szczebla.
- Skoki do podciągnięć (OG2 L1) pomijamy, bo negatywy pełnią tę rolę. Żadne
  źródło nie ma zwisu jako szczebla.

### Wiosłowanie — `row`

Ruch główny: **Podciągnięcia australijskie** (`australianPullUpsID`). Źródło: RR.
Wskazówka bazy: „Wiosłowanie i podciąganie budują się razem — to dwie strony
siły pleców."

| # | Szczebel | Ćwiczenie | Kryterium | Źródło kryterium | Sprzęt | Uwaga |
|---|---|---|---|---|---|---|
| 1 | Wiosłowanie na podwyższeniu | `inclineRowsID` | 3 × 8 | RR | Pull-up bar, Parallel bars | |
| 2 | Podciągnięcia australijskie | `australianPullUpsID` | 3 × 8 | RR | Pull-up bar, Parallel bars | |
| 3 | Wiosłowanie szerokie | `wideRowsID` | 3 × 8 | RR | Pull-up bar, Parallel bars | |
| 4 | Wiosłowanie łucznicze | `archerRowsID` | 3 × 5 na rękę | konwencja CaliPark | Pull-up bar, Parallel bars | |
| 5 | Wiosłowanie w tuck front lever | `tuckFrontLeverRowsID` | 3 × 8 | RR | Pull-up bar, Rings | wskazówka: „RR najpierw chce 20–30 s tuck front levera.” |

### Pompki — `pushUp`

Ruch główny: **Pompki** (`pushUpsID`). Źródło: RR.

| # | Szczebel | Ćwiczenie | Kryterium | Źródło kryterium | Sprzęt |
|---|---|---|---|---|---|
| 1 | Pompki od ściany | `wallPushUpsID` | 3 × 8 | RR | — |
| 2 | Pompki na podwyższeniu | `inclinePushUpsID` | 3 × 8 | RR | — |
| 3 | Pompki z kolan | `kneePushUpsID` | 3 × 8 | RR | — |
| 4 | Pełne pompki | `pushUpsID` | 3 × 8 | RR | — |
| 5 | Pompki diamentowe | `diamondPushUpsID` | 3 × 8 | RR | — |
| 6 | Pompki pseudo-planche | `pseudoPlanchePushUpsID` | 3 × 8 | RR | — (RR: „Nothing! Or rings”) |

### Dipy — `dip`

Ruch główny: **Dipy** (`dipsID`). Źródła: RR, OG2. Szczebel wejściowy to hold (sek).

| # | Szczebel | Ćwiczenie | Kryterium | Źródło szczebla / kryterium | Sprzęt |
|---|---|---|---|---|---|
| 1 | Podpór na poręczach | `parallelBarSupportID` (sek) | 3 × 30 s | RR, OG2 L1 / RR (zasada holdów; strona dipów RR chce 3 × 60 s) | Dip bar, Parallel bars |
| 2 | Negatywy dipów | `negativeDipsID` | 3 × 5, zjazd 5–10 s | RR, OG2 L2 / konwencja CaliPark | Dip bar, Parallel bars |
| 3 | Dipy na poręczach | `dipsID` | 3 × 8 | RR, OG2 L3 / RR | Dip bar, Parallel bars |
| 4 | Podpór na kółkach | `ringSupportHoldID` (sek) | 1 × 60 s, docelowo z kółkami obróconymi na zewnątrz | RR (warunek: 60 s podporu RTO), OG2 L1–L2 / RR | Rings |
| 5 | Dipy na kółkach | `ringDipsID` | 3 × 8 | RR, OG2 L4 / RR | Rings |

### Nogi — `legs`

Ruchy główne: **Przysiady** (`squatsID`), **Wykroki** (`lungesID`),
**Pistolety** (`pistolSquatsID`). Źródła: RR, OG2 (arkusz).

| # | Szczebel | Ćwiczenie | Kryterium | Źródło szczebla / kryterium | Sprzęt | Uwaga |
|---|---|---|---|---|---|---|
| 1 | Przysiad z asystą | `assistedSquatsID` | 3 × 8 | RR / RR | — | |
| 2 | Pełny przysiad | `squatsID` | 3 × 8 | RR / RR | — | |
| 3 | Wykroki | `lungesID` | 3 × 8 na nogę | OG2 (arkusz) L1 / RR | — | zostają dla programu „Minimum” |
| 4 | Przysiad wykroczny | `splitSquatID` | 3 × 8 na nogę | RR, OG2 (arkusz) L2 / RR | — | |
| 5 | Przysiad bułgarski | `bulgarianSplitSquatID` | 3 × 8 na nogę | RR / RR | — (ławka) | |
| 6 | Wejścia na podwyższenie | `stepUpsID` | 3 × 8 na nogę | RR (gałąź obok pistoletów) / RR | — | **tor równoległy** (opcja) |
| 7 | Pistolet z asystą | `assistedPistolSquatsID` | 3 × 5 na nogę | RR (partial pistol) / konwencja CaliPark | — | |
| 8 | Pistolet | `pistolSquatsID` | 3 × 5 na nogę | RR, OG2 L4 / konwencja CaliPark | — | |

- RR odróżnia przysiad wykroczny od wykroków. Wykroki stoją przed nim tak jak w
  dodatkowej kolumnie arkusza OG2.
- Shrimp squat (RR) i deep step-up zostawiamy na później.

### Core — `core`

Ruchy główne: **Deska** (`plankID`), **Wznosy nóg w zwisie**
(`hangingLegRaisesID`). Źródło: RR. Szczebel wejściowy to hold (sek).

| # | Szczebel | Ćwiczenie | Kryterium | Źródło kryterium | Sprzęt |
|---|---|---|---|---|---|
| 1 | Deska | `plankID` (sek) | 3 × 30 s | RR | — |
| 2 | Unoszenie kolan w zwisie | `hangingKneeRaisesID` | 3 × 8 | RR | Pull-up bar |
| 3 | Unoszenie nóg w zwisie | `hangingLegRaisesID` | 3 × 8 | RR | Pull-up bar |
| 4 | Nogi do drążka | `toesToBarID` | 3 × 8 | RR | Pull-up bar |

### Muscle-up — `muscleUp`

Ruch główny: **Muscle-up** (`muscleUpID`). Źródła: RR, OG2.
Wskazówka bazy (niewiążąca): „Większość osób buduje muscle-upa na bazie pewnych
podciągnięć i dipów." To adnotacja, nie warunek — szczeble są zawsze widoczne i
logowalne niezależnie od stanu innych ścieżek.

| # | Szczebel | Ćwiczenie | Kryterium | Źródło kryterium | Sprzęt |
|---|---|---|---|---|---|
| 1 | Podciągnięcia do klatki | `chestToBarPullUpsID` | 3 × 5 | konwencja CaliPark | Pull-up bar |
| 2 | Negatywy muscle-upa | `negativeMuscleUpsID` | 3 × 3 | konwencja CaliPark | Pull-up bar, Rings |
| 3 | Muscle-up z kipem | `kippingMuscleUpsID` | 3 × 3 | konwencja CaliPark | Pull-up bar, Rings |
| 4 | Strict muscle-up | `muscleUpID` | pierwsze czyste | konwencja CaliPark | Pull-up bar, Rings |

---

## Drabiny statyczne (kryterium bazowe: 3 × 20 s, OG2 (tabela))

### L-sit — `lSit`

Ruch główny: **L-sit** (`lSitID`, sek). Źródła: OG2, GMB. Kolejność według GMB.

| # | Szczebel | Ćwiczenie | Kryterium | Źródło szczebla / kryterium | Sprzęt |
|---|---|---|---|---|---|
| 1 | L-sit z podporem stóp | `footSupportedLSitID` | 3 × 20 s | GMB krok 1, Antranik / OG2 (tabela) | Parallel bars, Push-up handles |
| 2 | L-sit z podporem jednej stopy | `oneFootSupportedLSitID` | 3 × 20 s na stronę | GMB krok 2, Antranik / OG2 (tabela) | Parallel bars, Push-up handles |
| 3 | Tuck L-sit | `tuckLSitID` | 3 × 20 s | OG2 L1, GMB krok 3 / OG2 (tabela) | Parallel bars, Push-up handles |
| 4 | L-sit na jednej nodze | `oneLegLSitID` | 3 × 20 s na stronę | OG2 L2, GMB krok 5 / OG2 (tabela) | Parallel bars, Push-up handles |
| 5 | Pełny L-sit | `lSitID` | 3 × 20 s | OG2 L3 / OG2 (tabela) | Parallel bars, Push-up handles |

- L-sit na jednej nodze (jedna noga prosta, druga podkurczona) jest według OG2
  i GMB trudniejszy niż tuck, więc stoi za nim.

### Front lever — `frontLever`

Ruch główny: **Front lever** (`frontLeverID`, sek). Źródło: OG2.
Wskazówka bazy: „Zwykle buduje się na bazie mocnych podciągnięć i wiosłowania."

| # | Szczebel | Ćwiczenie | Kryterium | Źródło kryterium | Sprzęt | Uwaga |
|---|---|---|---|---|---|---|
| 1 | Tuck front lever | `tuckFrontLeverID` | 3 × 20 s | OG2 (tabela) | Pull-up bar, Rings | wskazówka: „RR przed tuckiem: skin the cat 5 × 2 i zwis z wygięciem 3 × 8.” |
| 2 | Advanced tuck front lever | `advancedTuckFrontLeverID` | 3 × 20 s | OG2 (tabela) | Pull-up bar, Rings | |
| 3 | Front lever w rozkroku | `straddleFrontLeverID` | 3 × 20 s | OG2 (tabela) | Pull-up bar, Rings | |
| 4 | Half-lay front lever | `halfLayFrontLeverID` | 3 × 20 s | OG2 (tabela) | Pull-up bar, Rings | |
| 5 | Pełny front lever | `frontLeverID` | pierwsze 5 s | konwencja CaliPark | Pull-up bar, Rings | |

### Back lever — `backLever`

Ruch główny: **Back lever** (`backLeverID`, sek). Źródło: OG2. Szczeble
wejściowe to mobilność (german hang w sek, skin the cat w powtórzeniach).

| # | Szczebel | Ćwiczenie | Kryterium | Źródło kryterium | Sprzęt |
|---|---|---|---|---|---|
| 1 | German hang | `germanHangID` (sek) | 3 × 30 s | RR | Pull-up bar, Rings |
| 2 | Skin the cat | `skinTheCatID` (powt.) | 3 × 5 | konwencja CaliPark | Pull-up bar, Rings |
| 3 | Tuck back lever | `tuckBackLeverID` | 3 × 20 s | OG2 (tabela) | Pull-up bar, Rings |
| 4 | Advanced tuck back lever | `advancedTuckBackLeverID` | 3 × 20 s | OG2 (tabela) | Pull-up bar, Rings |
| 5 | Back lever w rozkroku | `straddleBackLeverID` | 3 × 20 s | OG2 (tabela) | Pull-up bar, Rings |
| 6 | Half-lay back lever | `halfLayBackLeverID` | 3 × 20 s | OG2 (tabela) | Pull-up bar, Rings |
| 7 | Pełny back lever | `backLeverID` | pierwsze 5 s | konwencja CaliPark | Pull-up bar, Rings |

### Planche — `planche`

Ruch główny: **Planche** (`plancheID`, sek). Źródło: OG2.
Wskazówka bazy: „Zwykle buduje się na bazie pompek pseudo-planche i mocnych barków."

| # | Szczebel | Ćwiczenie | Kryterium | Źródło szczebla / kryterium | Sprzęt |
|---|---|---|---|---|---|
| 1 | Stanie żabki | `frogStandID` | 3 × 30 s | OG2 L3 / RR | — (na podłodze) |
| 2 | Żabka na prostych rękach | `straightArmFrogStandID` | 3 × 20 s | OG2 L4 / OG2 (tabela) | — |
| 3 | Tuck planche | `tuckPlancheID` | 3 × 20 s | OG2 L5 / OG2 (tabela) | Push-up handles, Parallel bars |
| 4 | Advanced tuck planche | `advancedTuckPlancheID` | 3 × 20 s | OG2 L6 / OG2 (tabela) | Push-up handles, Parallel bars |
| 5 | Planche w rozkroku | `straddlePlancheID` | 3 × 20 s | OG2 L8 / OG2 (tabela) | Push-up handles, Parallel bars |
| 6 | Half-lay planche | `halfLayPlancheID` | 3 × 20 s | OG2 L9 / OG2 (tabela) | Push-up handles, Parallel bars |
| 7 | Pełna planche | `plancheID` | pierwsze 5 s | OG2 L11 / konwencja CaliPark | Push-up handles, Parallel bars |

- Half-lay zamiast planche na jednej nodze (oba to OG2 L9), tak jak we front i
  back leverze.

### Flaga — `humanFlag`

Ruch główny: **Flaga** (`humanFlagID`, sek). Źródło: OG2.

| # | Szczebel | Ćwiczenie | Kryterium | Źródło szczebla / kryterium | Sprzęt |
|---|---|---|---|---|---|
| 1 | Podpór na pionowym drążku | `verticalFlagSupportID` | 3 × 20 s | konwencja CaliPark (ćwiczenie wejściowe, brak w źródłach) | fitness_pole, wall_bars |
| 2 | Tuck flaga | `tuckFlagID` | 3 × 20 s | OG2 L5 / OG2 (tabela) | fitness_pole, wall_bars |
| 3 | Advanced tuck flaga | `advancedTuckFlagID` | 3 × 20 s | OG2 L6 / OG2 (tabela) | fitness_pole, wall_bars |
| 4 | Flaga w rozkroku | `straddleFlagID` | 3 × 20 s | OG2 L7 / OG2 (tabela) | fitness_pole, wall_bars |
| 5 | Pełna flaga | `humanFlagID` | pierwsze 5 s | OG2 L8 / konwencja CaliPark | fitness_pole, wall_bars |

- Flagę robi się na pionowym drążku albo na drabinkach gimnastycznych, nie na
  zwykłym drążku. W modelu Parku „możliwość flaga” obejmuje też
  `climbing_pole`; ten klucz dojdzie razem z resztą kluczy OSM.

### Stanie na rękach — `handstand`

Ruch główny: **Pompki w staniu na rękach** (`wallHandstandPushUpsID`). Źródło:
OG2. Zakres v1 kończy się na pompkach przy ścianie — wolne stanie i wolne pompki
to osobny plan.

| # | Szczebel | Ćwiczenie | Kryterium | Źródło szczebla / kryterium | Sprzęt |
|---|---|---|---|---|---|
| 1 | Podpór przy ścianie | `wallPlankID` (sek) | 3 × 30 s | konwencja CaliPark (ćwiczenie wejściowe) / RR | — |
| 2 | Stanie na rękach przy ścianie | `wallHandstandHoldID` (sek) | 3 × 30 s | OG2 L1–L3 (kolumna handstand) / RR | — |
| 3 | Pompki pike | `pikePushUpsID` | 3 × 8 | OG2 L1 (kolumna pompek w staniu), Cali Move poziom 2 / RR | — |
| 4 | Pompki pike z nogami na podwyższeniu | `elevatedPikePushUpsID` | 3 × 8 | OG2 L2 / RR | — (ławka) |
| 5 | Negatywy pompek w staniu przy ścianie | `wallHandstandPushUpNegativesID` | 3 × 5, zjazd 5–10 s | OG2 L3 / konwencja CaliPark | — |
| 6 | Pompki w staniu przy ścianie | `wallHandstandPushUpsID` | 3 × 5 | OG2 L4 / konwencja CaliPark | — |

---

## Deklaracja startu (placement) — `PlacementCalibration`

Pytanie „Ile … robisz w jednej serii?" mówi **tylko o ruchu, o który pyta**.
Trudniejsze warianty (diamentowe, L-pull-upy, wykroki, dipy na kółkach) to
osobne ćwiczenia — żadna odpowiedź ich nie zalicza. Zdobywa się je logami albo
(dla skilli, których nie da się policzyć powtórzeniami) checkboxem.

| Odpowiedź | Aktualny szczebel | Co zaliczone |
|---|---|---|
| 0 | regresja budująca ruch | szczeble poniżej regresji |
| 1–5, 6–11 | sam ruch | regresje poniżej ruchu |
| 12+ | następny wariant głównej linii (do zdobycia logami) | ruch z pytania (≈ max 12 w serii to realne 3 × 8) |

Odpowiedzi wskazują szczebel po ID ćwiczenia, nie po numerze, więc wstawianie
szczebli ich nie przesuwa.

| Ścieżka | Regresja przy „0" | Ruch z pytania | Przy „12+" aktualny |
|---|---|---|---|
| Podciąganie | Negatywy | Pełne podciągnięcia | L-pull-ups |
| Pompki | Pompki z kolan | Pełne pompki | Pompki diamentowe |
| Dipy | Negatywy dipów | Dipy na poręczach | Podpór na kółkach |
| Nogi | Przysiad z asystą | Pełny przysiad | Wykroki |

Przy dipach „12+” wskazuje podpór na kółkach, bo RR stawia go jako warunek
przed dipami na kółkach.

Checkboxy skilli (muscle-up, pełny L-sit, pistolet) ustawiają zaznaczony skill
jako aktualny szczebel. Deklaracja nigdy nie daje XP ani odznak.

---

## Zasady integralności (egzekwowane testami — `ProgressionCatalogTests`, `LadderRevisionTests`)

1. Każdy `exerciseID` w każdym szczeblu wskazuje istniejące ćwiczenie w
   `ExerciseCatalog`.
2. W obrębie jednej ścieżki żadne ćwiczenie nie powtarza się.
3. Miara zgadza się z kryterium: szczeble z kryterium `.setsOfHold` (sekundy)
   wskazują ćwiczenia z `measurement == .seconds`; szczeble z `.setsOfReps` —
   ćwiczenia z `measurement == .reps`.
4. Każdy wariant progresji (`variantOf != nil`) wskazuje **ruch główny** z
   pierwotnej 19-tki (hierarchia płaska, jeden poziom).
5. Pierwotne 19 UUID pozostaje niezmienione — logi przeżywają. Nowe ćwiczenia
   dostają kolejne stałe UUID (rewizja 2026-11: `…000000000066`–`…000000000076`).
6. Lista biblioteki (`ExerciseCatalog.mainMovements`) po rozszerzeniu katalogu =
   dokładnie 19 ruchów głównych.
7. Kolejność drabin jest zamrożona w teście (`LadderOrderSnapshotTests`).
   Każda zmiana kolejności to świadoma zmiana tego dokumentu, kodu i testu
   naraz. `LadderOrderV1` (kolejność sprzed zapisu po ID) nigdy się nie zmienia.
8. Żadna drabina nie kończy się torem równoległym.

## Decyzje warte odnotowania

- **Guma = `Resistance bands`.** Plan mówił „guma oporowa", ale konwencja
  `Park.equipments` jest angielska, a string `Resistance bands` już istnieje w
  puli — używamy go zamiast dodawać nowy klucz.
- **Rewizja 2026-11 (ticket 015).** Nic nie wypadło: 11 nowych szczebli, jeden
  przeniesiony (L-sit na jednej nodze), pełny L-sit 3 × 20 s zamiast 3 × 15 s,
  etykiety źródeł, sprzęt flagi. Placementy i celebracje są zapisane po ID
  ćwiczenia, więc wskazują te same ćwiczenia co przed rewizją. Szczeble wstawione
  poniżej najwyższego zaliczonego liczą się jako zaliczone, więc obecni
  użytkownicy dostali jednorazowy skok XP (np. 3 × 8 podciągnięć: 5 → 6
  zaliczonych szczebli, +100 XP; pompki w staniu 3 × 5: 3 → 6, +300 XP), a
  wstawiony szczebel (np. zwis z wygięciem) świętuje się raz. Właściciel to
  zaakceptował.
- **Persystencja: świadomie zero.** Katalog i ścieżki to statyczny kod, postęp
  liczymy z logów (SK3). Bramka `core-data-expert` przeszła bez bazy — pusty
  `PersistenceController` nietknięty.
- **Skille wejściowe mieszają miary w obrębie ścieżki.** Np. back lever zaczyna
  się od german hang (sek) i skin the cat (powt.), zanim wejdzie w holdy tuck.
  Dlatego kryterium jest atrybutem szczebla, nie ścieżki.
- **Markery opanowania.** Pełne dźwignie/flaga używają „pierwsze 5 s", strict
  muscle-up „pierwsze czyste" — realny próg „masz to", nie cel docelowy 3 × 20 s.

[rr]: https://www.reddit.com/r/bodyweightfitness/wiki/kb/recommended_routine/
[rrpull]: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/pullup/
[rrrow]: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/row/
[rrpush]: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/pushup/
[rrdip]: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/dip/
[rrsquat]: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/squat/
[ogsheet]: https://docs.google.com/spreadsheets/d/19l4tVfdTJLheLMwZBYqcw1oeEBPRh8mxngqrCz2YnVg/
[ogtable]: https://stevenlow.org/wp-content/uploads/2016/12/isometrictable.jpg
[ogpril]: https://stevenlow.org/prilepin-tables-for-bodyweight-strength-isometric-and-eccentric-exercises/
[gmb]: https://web.archive.org/web/20260718150020/https://gmb.io/l-sit/
[sbw]: http://www.startbodyweight.com/p/start-bodyweight-basic-routine.html
[sbwpull]: http://www.startbodyweight.com/p/pull-up-progression.html
[cmpull]: https://blog.calimove.com/2023/05/11/8-weeks-pull-up-challenge/
