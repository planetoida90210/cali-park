# Ścieżki progresji kalisteniki — dokument-prawda

Ten dokument jest **jedynym źródłem prawdy** dla treści ścieżek progresji. Kod
(`ProgressionCatalog` + warianty w `ExerciseCatalog`) jest jego wiernym
odbiciem 1:1 — jeśli coś zmienia się tutaj, zmienia się i tam (i odwrotnie).
Kolejne sprinty (SK2–SK6) opierają się na tym dokumencie, nie na własnych
domysłach.

Plan źródłowy: [.cursor/plans/skill_tree_kalisteniki_4d366e3c.plan.md](../.cursor/plans/skill_tree_kalisteniki_4d366e3c.plan.md)
Tracker: [docs/SPRINTS-SKILLS.md](SPRINTS-SKILLS.md)

## Źródła

Drabiny nie są wymyślone — pochodzą z uznanych źródeł. W razie wątpliwości
wybieramy wersję ze źródła, nie własną.

- **RR** — Recommended Routine, r/bodyweightfitness (wiki:
  `redditbwf.github.io/wiki/recommended_routine.html`; omówienie Antranika:
  `antranik.org/rr/`). Drabiny dynamiczne: podciąganie, wiosłowanie, pompki,
  dipy, przysiad, core. Zasada przejścia: **3 × 8 czysto → następny szczebel**
  (start 3 × 5 na nowym).
- **OG** — Overcoming Gravity, 2nd ed., Steven Low (publiczne charty:
  calisthenics-101.co.uk, „Overcoming Gravity 2 Charts"). Drabiny statyk:
  front lever, back lever, planche, flaga, L-sit. Kryterium izometrii:
  **3 × 20 s → następna wariacja**. Rekomendowane bazy między ćwiczeniami — u
  nas wyłącznie jako **niewiążące wskazówki**, nie warunki.
- **FPU** — poradniki „first pull-up" (dead hang → scapular pulls → negatywy →
  guma). Potwierdzają drabinę zero→jeden i rolę gumy jako **toru równoległego**
  (opcja sprzętowa, nie obowiązek — fundamentem są negatywy).

## Jak czytać kryteria

Każdy szczebel ma **kryterium** — cel, który uznajemy za jego zaliczenie:

- `3 × 8` — trzy serie po 8 czystych powtórzeń (drabiny dynamiczne, RR).
- `3 × 5`, `3 × 3` — niższe cele dla trudniejszych szczebli repowych (negatywy,
  ruchy jednostronne, przejścia muscle-upa).
- `3 × 30 s` — trzy utrzymania po 30 s (łatwiejsze holdy wejściowe: zwis,
  podpór, german hang, żabka, ściana).
- `3 × 20 s` — trzy utrzymania po 20 s (właściwe statyki dźwigni/flagi/L-sit, OG).
- `pierwsze czyste` — marker opanowania skilla: pierwsze czyste powtórzenie
  (muscle-up) lub pierwsze 5 s utrzymania (pełne dźwignie, pełna flaga). To
  celowo niski, realny próg „masz to", nie cel docelowy.

Sprzęt zapisujemy stringami spójnymi z `Park.equipments` (angielskie klucze:
`Pull-up bar`, `Dip bar`, `Parallel bars`, `Rings`, `Push-up handles`,
`Resistance bands`). Guma = `Resistance bands`; tworzy **tor równoległy**, nie
obowiązkowy.

Stany szczebla (liczone w SK3): **zaliczony** (z deklaracji placementu albo z
logów), **aktualny** (tu trenujesz), **przyszły** (widoczny, opisany, bez
kłódek). Drabina jest mapą i miernikiem, nigdy bramką — logować i ustawiać jako
aktualny można każdy szczebel.

---

## Drabiny dynamiczne (kryterium bazowe: 3 × 8, źródło: RR)

### Podciąganie — `pullUp`

Ruch główny: **Podciągnięcia** (`pullUpsID`). Źródło: RR + FPU.

| # | Szczebel | Ćwiczenie | Kryterium | Sprzęt | Uwaga |
|---|---|---|---|---|---|
| 1 | Zwis na drążku | `deadHangID` (sek) | 3 × 30 s | Pull-up bar | siła chwytu |
| 2 | Ściąganie łopatek w zwisie | `scapularPullsID` | 3 × 8 | Pull-up bar | aktywacja pleców |
| 3 | Negatywy podciągnięć | `negativePullUpsID` | 3 × 5 | Pull-up bar | fundament zero→jeden |
| 4 | Podciągnięcia z gumą | `bandPullUpsID` | 3 × 8 | Pull-up bar, Resistance bands | **tor równoległy** (opcja) |
| 5 | Pełne podciągnięcia | `pullUpsID` | 3 × 8 | Pull-up bar | ruch główny |
| 6 | L-pull-ups | `lPullUpsID` | 3 × 5 | Pull-up bar | + napięcie core |
| 7 | Podciągnięcia łucznicze | `archerPullUpsID` | 3 × 5 | Pull-up bar | krok do jednorącz |

### Wiosłowanie — `row`

Ruch główny: **Podciągnięcia australijskie** (`australianPullUpsID`). Źródło: RR.
Wskazówka bazy: „Wiosłowanie i podciąganie budują się razem — to dwie strony
siły pleców."

| # | Szczebel | Ćwiczenie | Kryterium | Sprzęt |
|---|---|---|---|---|
| 1 | Wiosłowanie na podwyższeniu | `inclineRowsID` | 3 × 8 | Pull-up bar, Parallel bars |
| 2 | Podciągnięcia australijskie | `australianPullUpsID` | 3 × 8 | Pull-up bar, Parallel bars |
| 3 | Wiosłowanie szerokie | `wideRowsID` | 3 × 8 | Pull-up bar, Parallel bars |
| 4 | Wiosłowanie łucznicze | `archerRowsID` | 3 × 5 | Pull-up bar, Parallel bars |
| 5 | Wiosłowanie w tuck front lever | `tuckFrontLeverRowsID` | 3 × 8 | Pull-up bar, Rings |

### Pompki — `pushUp`

Ruch główny: **Pompki** (`pushUpsID`). Źródło: RR.

| # | Szczebel | Ćwiczenie | Kryterium | Sprzęt |
|---|---|---|---|---|
| 1 | Pompki od ściany | `wallPushUpsID` | 3 × 8 | — |
| 2 | Pompki na podwyższeniu | `inclinePushUpsID` | 3 × 8 | — |
| 3 | Pompki z kolan | `kneePushUpsID` | 3 × 8 | — |
| 4 | Pełne pompki | `pushUpsID` | 3 × 8 | — |
| 5 | Pompki diamentowe | `diamondPushUpsID` | 3 × 8 | — |
| 6 | Pompki pseudo-planche | `pseudoPlanchePushUpsID` | 3 × 8 | Push-up handles |

### Dipy — `dip`

Ruch główny: **Dipy** (`dipsID`). Źródło: RR. Szczebel wejściowy to hold (sek).

| # | Szczebel | Ćwiczenie | Kryterium | Sprzęt |
|---|---|---|---|---|
| 1 | Podpór na poręczach | `parallelBarSupportID` (sek) | 3 × 30 s | Dip bar, Parallel bars |
| 2 | Negatywy dipów | `negativeDipsID` | 3 × 5 | Dip bar, Parallel bars |
| 3 | Dipy na poręczach | `dipsID` | 3 × 8 | Dip bar, Parallel bars |
| 4 | Dipy na kółkach | `ringDipsID` | 3 × 8 | Rings |

### Nogi — `legs`

Ruchy główne: **Przysiady** (`squatsID`), **Wykroki** (`lungesID`),
**Pistolety** (`pistolSquatsID`). Źródło: RR.

| # | Szczebel | Ćwiczenie | Kryterium | Sprzęt |
|---|---|---|---|---|
| 1 | Przysiad z asystą | `assistedSquatsID` | 3 × 8 | — |
| 2 | Pełny przysiad | `squatsID` | 3 × 8 | — |
| 3 | Wykroki | `lungesID` | 3 × 8 | — |
| 4 | Wejścia na podwyższenie | `stepUpsID` | 3 × 8 | — |
| 5 | Pistolet z asystą | `assistedPistolSquatsID` | 3 × 5 | — |
| 6 | Pistolet | `pistolSquatsID` | 3 × 5 | — |

### Core — `core`

Ruchy główne: **Deska** (`plankID`), **Wznosy nóg w zwisie**
(`hangingLegRaisesID`). Źródło: RR. Szczebel wejściowy to hold (sek).

| # | Szczebel | Ćwiczenie | Kryterium | Sprzęt |
|---|---|---|---|---|
| 1 | Deska | `plankID` (sek) | 3 × 30 s | — |
| 2 | Unoszenie kolan w zwisie | `hangingKneeRaisesID` | 3 × 8 | Pull-up bar |
| 3 | Unoszenie nóg w zwisie | `hangingLegRaisesID` | 3 × 8 | Pull-up bar |
| 4 | Nogi do drążka | `toesToBarID` | 3 × 8 | Pull-up bar |

### Muscle-up — `muscleUp`

Ruch główny: **Muscle-up** (`muscleUpID`). Źródło: RR + OG.
Wskazówka bazy (niewiążąca): „Większość osób buduje muscle-upa na bazie pewnych
podciągnięć i dipów." To adnotacja, nie warunek — szczeble są zawsze widoczne i
logowalne niezależnie od stanu innych ścieżek.

| # | Szczebel | Ćwiczenie | Kryterium | Sprzęt |
|---|---|---|---|---|
| 1 | Podciągnięcia do klatki | `chestToBarPullUpsID` | 3 × 5 | Pull-up bar |
| 2 | Negatywy muscle-upa | `negativeMuscleUpsID` | 3 × 3 | Pull-up bar, Rings |
| 3 | Muscle-up z kipem | `kippingMuscleUpsID` | 3 × 3 | Pull-up bar, Rings |
| 4 | Strict muscle-up | `muscleUpID` | pierwsze czyste | Pull-up bar, Rings |

---

## Drabiny statyczne (kryterium bazowe: 3 × 20 s, źródło: OG)

### L-sit — `lSit`

Ruch główny: **L-sit** (`lSitID`, sek). Źródło: OG.

| # | Szczebel | Ćwiczenie | Kryterium | Sprzęt |
|---|---|---|---|---|
| 1 | L-sit z podporem stóp | `footSupportedLSitID` | 3 × 20 s | Parallel bars, Push-up handles |
| 2 | L-sit na jednej nodze | `oneLegLSitID` | 3 × 20 s | Parallel bars, Push-up handles |
| 3 | Tuck L-sit | `tuckLSitID` | 3 × 20 s | Parallel bars, Push-up handles |
| 4 | Pełny L-sit | `lSitID` | 3 × 15 s | Parallel bars, Push-up handles |

### Front lever — `frontLever`

Ruch główny: **Front lever** (`frontLeverID`, sek). Źródło: OG.
Wskazówka bazy: „Zwykle buduje się na bazie mocnych podciągnięć i wiosłowania."

| # | Szczebel | Ćwiczenie | Kryterium | Sprzęt |
|---|---|---|---|---|
| 1 | Tuck front lever | `tuckFrontLeverID` | 3 × 20 s | Pull-up bar, Rings |
| 2 | Advanced tuck front lever | `advancedTuckFrontLeverID` | 3 × 20 s | Pull-up bar, Rings |
| 3 | Front lever w rozkroku | `straddleFrontLeverID` | 3 × 20 s | Pull-up bar, Rings |
| 4 | Half-lay front lever | `halfLayFrontLeverID` | 3 × 20 s | Pull-up bar, Rings |
| 5 | Pełny front lever | `frontLeverID` | pierwsze 5 s | Pull-up bar, Rings |

### Back lever — `backLever`

Ruch główny: **Back lever** (`backLeverID`, sek). Źródło: OG. Szczeble
wejściowe to mobilność (german hang w sek, skin the cat w powtórzeniach).

| # | Szczebel | Ćwiczenie | Kryterium | Sprzęt |
|---|---|---|---|---|
| 1 | German hang | `germanHangID` (sek) | 3 × 30 s | Pull-up bar, Rings |
| 2 | Skin the cat | `skinTheCatID` (powt.) | 3 × 5 | Pull-up bar, Rings |
| 3 | Tuck back lever | `tuckBackLeverID` | 3 × 20 s | Pull-up bar, Rings |
| 4 | Advanced tuck back lever | `advancedTuckBackLeverID` | 3 × 20 s | Pull-up bar, Rings |
| 5 | Back lever w rozkroku | `straddleBackLeverID` | 3 × 20 s | Pull-up bar, Rings |
| 6 | Half-lay back lever | `halfLayBackLeverID` | 3 × 20 s | Pull-up bar, Rings |
| 7 | Pełny back lever | `backLeverID` | pierwsze 5 s | Pull-up bar, Rings |

### Planche — `planche`

Ruch główny: **Planche** (`plancheID`, sek). Źródło: OG.
Wskazówka bazy: „Zwykle buduje się na bazie pompek pseudo-planche i mocnych barków."

| # | Szczebel | Ćwiczenie | Kryterium | Sprzęt |
|---|---|---|---|---|
| 1 | Stanie żabki | `frogStandID` | 3 × 30 s | Push-up handles |
| 2 | Tuck planche | `tuckPlancheID` | 3 × 20 s | Push-up handles, Parallel bars |
| 3 | Advanced tuck planche | `advancedTuckPlancheID` | 3 × 20 s | Push-up handles, Parallel bars |
| 4 | Planche w rozkroku | `straddlePlancheID` | 3 × 20 s | Push-up handles, Parallel bars |
| 5 | Pełna planche | `plancheID` | pierwsze 5 s | Push-up handles, Parallel bars |

### Flaga — `humanFlag`

Ruch główny: **Flaga** (`humanFlagID`, sek). Źródło: OG.

| # | Szczebel | Ćwiczenie | Kryterium | Sprzęt |
|---|---|---|---|---|
| 1 | Podpór na pionowym drążku | `verticalFlagSupportID` | 3 × 20 s | Pull-up bar |
| 2 | Tuck flaga | `tuckFlagID` | 3 × 20 s | Pull-up bar |
| 3 | Flaga w rozkroku | `straddleFlagID` | 3 × 20 s | Pull-up bar |
| 4 | Pełna flaga | `humanFlagID` | pierwsze 5 s | Pull-up bar |

### Stanie na rękach — `handstand`

Ruch główny: **Pompki w staniu na rękach** (`wallHandstandPushUpsID`). Źródło:
OG. Zakres v1 kończy się na pompkach przy ścianie — wolne stanie i wolne pompki
to osobny plan.

| # | Szczebel | Ćwiczenie | Kryterium | Sprzęt |
|---|---|---|---|---|
| 1 | Podpór przy ścianie | `wallPlankID` (sek) | 3 × 30 s | — |
| 2 | Stanie na rękach przy ścianie | `wallHandstandHoldID` (sek) | 3 × 30 s | — |
| 3 | Pompki w staniu przy ścianie | `wallHandstandPushUpsID` | 3 × 5 | — |

---

## Zasady integralności (egzekwowane testami — `ProgressionCatalogTests`)

1. Każdy `exerciseID` w każdym szczeblu wskazuje istniejące ćwiczenie w
   `ExerciseCatalog`.
2. W obrębie jednej ścieżki żadne ćwiczenie nie powtarza się.
3. Miara zgadza się z kryterium: szczeble z kryterium `.setsOfHold` (sekundy)
   wskazują ćwiczenia z `measurement == .seconds`; szczeble z `.setsOfReps` —
   ćwiczenia z `measurement == .reps`.
4. Każdy wariant progresji (`variantOf != nil`) wskazuje **ruch główny** z
   pierwotnej 19-tki (hierarchia płaska, jeden poziom).
5. Pierwotne 19 UUID pozostaje niezmienione — logi przeżywają.
6. Lista biblioteki (`ExerciseCatalog.mainMovements`) po rozszerzeniu katalogu =
   dokładnie 19 ruchów głównych.

## Decyzje warte odnotowania

- **Guma = `Resistance bands`.** Plan mówił „guma oporowa", ale konwencja
  `Park.equipments` jest angielska, a string `Resistance bands` już istnieje w
  puli — używamy go zamiast dodawać nowy klucz.
- **Persystencja: świadomie zero.** Katalog i ścieżki to statyczny kod, postęp
  liczymy z logów (SK3). Bramka `core-data-expert` przeszła bez bazy — pusty
  `PersistenceController` nietknięty.
- **Skille wejściowe mieszają miary w obrębie ścieżki.** Np. back lever zaczyna
  się od german hang (sek) i skin the cat (powt.), zanim wejdzie w holdy tuck.
  Dlatego kryterium jest atrybutem szczebla, nie ścieżki.
- **Markery opanowania.** Pełne dźwignie/flaga używają „pierwsze 5 s", strict
  muscle-up „pierwsze czyste" — realny próg „masz to", nie cel docelowy 3 × 20 s.
