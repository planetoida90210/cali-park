# Propozycja: rewizja drabin progresji

Ticket: [015 Rewizja drabin progresji](../tickets/015-ladders-revision.md). Podstawa: [research ze źródłami](../../research/progressions-programs.md), sprawdzony 2026-11-03. Stan obecny: [docs/PROGRESSIONS.md](../../../PROGRESSIONS.md).

Status: **propozycja do akceptacji**. `PROGRESSIONS.md` i kod nie są zmienione. Po akceptacji oba zmieniamy razem, w jednym commicie, i dopiero po Fazie 0 (stabilne ID szczebli, patrz [Wpływ na dane](#wpływ-na-dane)).

## W skrócie

- **Nic nie znika.** Wszystkie zmiany to nowe szczeble, jedno przesunięcie (L-sit na jednej nodze) i poprawione etykiety. Zapisane logi zostają ważne.
- **Podciąganie:** dochodzi RR-owy zwis z wygięciem (arch hang). Guma zostaje torem równoległym, ale ze źródłem Cali Move zamiast RR. Negatywy dostają tempo zjazdu, a podciągnięcia łucznicze kryterium „na rękę”.
- **Handstand:** między staniem przy ścianie a pompkami w staniu dochodzą pompki pike, pompki pike z nogami na podwyższeniu i negatywy (OG2 L1–L3). To największa luka.
- **L-sit:** kolejność wg GMB: z podporem stóp → z podporem jednej stopy (nowy) → tuck → na jednej nodze (przeniesiony) → pełny. Pełny L-sit dostaje 3 × 20 s zamiast 3 × 15 s.
- **Planche:** dochodzi żabka na prostych rękach (OG2 L4) i half-lay planche (OG2 L9).
- **Flaga:** dochodzi advanced tuck (OG2 L6). Sprzęt to pionowy drążek, nie zwykły drążek.
- **Nogi:** dochodzi przysiad wykroczny i przysiad bułgarski (RR). Wejścia na podwyższenie stają się torem równoległym obok pistoletów. Wykroki zostają, bo potrzebuje ich program „Minimum”.
- **Dipy:** przed dipami na kółkach dochodzi podpór na kółkach (warunek z RR).
- **Kryteria:** każde dostaje etykietę źródła: RR, OG2 albo „konwencja CaliPark”. Ruchy jednostronne liczymy „na stronę”.
- **Nowe ćwiczenia w katalogu:** 11, wszystkie jako warianty istniejących ruchów głównych. Lista głównych 19 ruchów się nie zmienia.

## Skróty źródeł

| Skrót | Źródło |
|---|---|
| RR | Recommended Routine, wiki r/bodyweightfitness ([RR][rr], strony ćwiczeń: [pull-up][rrpull], [dip][rrdip], [squat][rrsquat], [push-up][rrpush], [row][rrrow]) |
| OG2 L*n* | Overcoming Gravity 2nd ed., poziom z chartu Stevena Lowa ([arkusz][ogsheet]) |
| OG2 (tabela) | tabela izometrii OG2 ([obraz][ogtable], [artykuł][ogpril]) |
| GMB | 6 kroków L-sit ([snapshot][gmb]) |
| SBW | StartBodyweight ([routine][sbw], [pull-up][sbwpull]) |
| Cali Move | [8-week pull-up challenge][cmpull] (tylko fakty o gumie i negatywach, nie struktura programu) |
| **konwencja CaliPark** | nasza reguła, bez źródła. Pokazujemy ją uczciwie jako naszą. |

## Zasady przekrojowe

### 1. Etykieta źródła przy każdym kryterium

| Kryterium | Gdzie | Etykieta | Uzasadnienie |
|---|---|---|---|
| 3 × 8 → następny szczebel, start 3 × 5 | szczeble dynamiczne | **RR** | dosłownie zasada RR; SBW tak samo |
| 3 × 30 s | holdy wejściowe | **RR** | zasada holdów RR: „30 s we wszystkich 3 seriach” |
| 3 × 20 s | statyki dźwigni, planche, flagi, L-sit | **OG2 (tabela)**, pochodna | ostatni wiersz tabeli izometrii OG2 (max ≈ 30 s). Publiczne materiały OG nie podają tego jako reguły awansu, więc piszemy „wyprowadzone z tabeli OG2”. |
| 3 × 5, 3 × 3 | negatywy, ruchy jednostronne, muscle-up | **konwencja CaliPark** | RR stosuje 3 × 5–8 wszędzie; nasze niższe cele są celowe |
| pierwsze 5 s / pierwsze czyste | pełne dźwignie, planche, flaga, strict muscle-up | **konwencja CaliPark** | marker opanowania, żadne źródło go nie definiuje |
| 1 × 60 s | podpór na kółkach (nowy) | **RR** | warunek RR przed dipami na kółkach |

Propozycja techniczna: pole `criterionSource` w `ProgressionStep` (enum `rr`, `og2`, `og2Table`, `gmb`, `caliPark`). Arkusz szczebla (`StepDetailSheetView`) pokazuje „Skąd to kryterium?”, a sekcja „Źródła” w `PROGRESSIONS.md` dostaje te same etykiety.

### 2. Ruchy jednostronne: kryterium „na stronę”

Dotyczy: podciągnięć łuczniczych, wiosłowania łuczniczego, wykroków, przysiadu wykrocznego, przysiadu bułgarskiego, wejść na podwyższenie, obu pistoletów, L-situ z podporem jednej stopy i L-situ na jednej nodze. Źródła: SBW liczy łucznicze „na rękę” (do 6), FAQ RR liczy deep step-upy jako „5–8 lewą, 5–8 prawą”.

Rekomendacja na 1.0 to **wersja tylko w tekście**. Flaga `isUnilateral` przy ćwiczeniu sprawia, że SetPad i kryterium pokazują „na stronę” albo „na nogę”. Użytkownik wpisuje wynik słabszej strony. Silnik i format logów się nie zmieniają. Osobne logowanie lewej i prawej strony to zmiana schematu logów, więc zostawiamy ją na później.

### 3. Negatywy: tempo zjazdu

RR każe dojść do zjazdu 10 s, SBW stosuje 5 s. Kryterium zostaje w powtórzeniach (3 × 5, konwencja CaliPark), ale opis i podpowiedź w SetPadzie mówią „zjazd 5–10 s”. `AdvancementCriterion` nie umie wyrazić tempa, a pole na tempo nie jest potrzebne w 1.0.

## Drabiny

Kolumna „Zmiana” odnosi się do obecnej numeracji w `PROGRESSIONS.md`. Szczebel oznaczony „równoległy” ma `isParallelTrack = true`, więc jest opcją, a nie obowiązkiem.

### Podciąganie (`pullUp`)

Przed: zwis → ściąganie łopatek → negatywy → guma (równoległy) → podciągnięcia → L-pull-ups → łucznicze.

| # | Szczebel | Kryterium | Źródło szczebla / kryterium | Zmiana |
|---|---|---|---|---|
| 1 | Zwis na drążku | 3 × 30 s | konwencja CaliPark (przygotowanie chwytu) / RR | bez zmian, etykieta „konwencja” |
| 2 | Ściąganie łopatek w zwisie | 3 × 8, pauza 3–5 s na górze | RR / RR | dochodzi pauza w opisie |
| 3 | **Zwis z wygięciem (arch hang)** | 3 × 8 | RR / RR | **nowy** |
| 4 | Negatywy podciągnięć | 3 × 5, zjazd 5–10 s | RR, OG2 L2 / konwencja CaliPark + tempo RR i SBW | było #3, dochodzi tempo |
| 5 | Podciągnięcia z gumą (równoległy) | 3 × 8 | Cali Move (guma pozwalająca na ok. 4–8 powtórzeń) / RR | było #4. Źródło się zmienia: RR nie ma szczebla z gumą. |
| 6 | Pełne podciągnięcia | 3 × 8 | RR, OG2 L3 / RR | było #5 |
| 7 | L-pull-ups | 3 × 5 | RR (gałąź), OG2 L4 / konwencja CaliPark | było #6 |
| 8 | Podciągnięcia łucznicze | 3 × 5 na rękę | RR (gałąź), OG2 L7 / SBW (≤ 6 na rękę) | było #7, kryterium „na rękę” |

- RR traktuje L-pull-ups i łucznicze jako dwie alternatywne gałęzie po 3 × 8 podciągnięć. Zostawiamy jedną linię w kolejności poziomów OG2 (L4 → L7), bo drabina i tak nie blokuje żadnego szczebla.
- Skoki do podciągnięć (OG2 L1) pomijamy, bo negatywy pełnią tę rolę.
- Sekcję „Źródła” poprawiamy: znika „FPU” bez nazwy, a w jego miejsce wchodzą RR, OG2, SBW i Cali Move. Żadne z nich nie ma zwisu jako szczebla.

### Dipy (`dip`)

| # | Szczebel | Kryterium | Źródło | Zmiana |
|---|---|---|---|---|
| 1 | Podpór na poręczach | 3 × 30 s | RR, OG2 L1 / zasada holdów RR (strona dipów RR chce 3 × 60 s) | bez zmian |
| 2 | Negatywy dipów | 3 × 5, zjazd 5–10 s | RR, OG2 L2 / konwencja CaliPark + tempo RR | dochodzi tempo |
| 3 | Dipy na poręczach | 3 × 8 | RR, OG2 L3 / RR | bez zmian |
| 4 | **Podpór na kółkach** | 1 × 60 s, docelowo z kółkami obróconymi na zewnątrz | RR (warunek: 60 s podporu RTO), OG2 L1–L2 / RR | **nowy** |
| 5 | Dipy na kółkach | 3 × 8 | RR, OG2 L4 / RR | było #4 |

### Nogi (`legs`)

Przed: przysiad z asystą → przysiad → wykroki → wejścia na podwyższenie → pistolet z asystą → pistolet.

| # | Szczebel | Kryterium | Źródło | Zmiana |
|---|---|---|---|---|
| 1 | Przysiad z asystą | 3 × 8 | RR / RR | bez zmian |
| 2 | Pełny przysiad | 3 × 8 | RR / RR | bez zmian |
| 3 | Wykroki | 3 × 8 na nogę | OG2 (dodatkowa kolumna arkusza) L1 / RR | „na nogę”; zostaje dla programu Minimum |
| 4 | **Przysiad wykroczny (split squat)** | 3 × 8 na nogę | RR, OG2 (arkusz) L2 / RR | **nowy** |
| 5 | **Przysiad bułgarski** | 3 × 8 na nogę | RR / RR | **nowy** |
| 6 | Wejścia na podwyższenie (równoległy) | 3 × 8 na nogę | RR (gałąź obok pistoletów) / RR | było #4, teraz tor równoległy |
| 7 | Pistolet z asystą | 3 × 5 na nogę | RR (partial pistol) / konwencja CaliPark | było #5, „na nogę” |
| 8 | Pistolet | 3 × 5 na nogę | RR, OG2 L4 / konwencja CaliPark | było #6, „na nogę” |

- RR wyraźnie odróżnia przysiad wykroczny od wykroków. Wykroki stoją przed nim tak jak w dodatkowej kolumnie arkusza OG2. Ta kolumna jest oznaczona „not in the book”, więc etykieta to „OG2 (arkusz)”.
- Placement „Nogi” przy 12+ nadal wskazuje Wykroki, bo stoją zaraz za przysiadem.
- Shrimp squat (RR) i deep step-up zostawiamy na później.

### L-sit (`lSit`)

Przed: z podporem stóp → na jednej nodze → tuck → pełny (3 × 15 s).

| # | Szczebel | Kryterium | Źródło | Zmiana |
|---|---|---|---|---|
| 1 | L-sit z podporem stóp | 3 × 20 s | GMB krok 1, Antranik / OG2 (tabela) | bez zmian |
| 2 | **L-sit z podporem jednej stopy** | 3 × 20 s na stronę | GMB krok 2, Antranik / OG2 (tabela) | **nowy** |
| 3 | Tuck L-sit | 3 × 20 s | OG2 L1, GMB krok 3 / OG2 (tabela) | było #3 |
| 4 | L-sit na jednej nodze | 3 × 20 s na stronę | OG2 L2, GMB krok 5 (≥ 5 s na stronę) / OG2 (tabela) | **przeniesiony z #2**, „na stronę” |
| 5 | Pełny L-sit | 3 × 20 s | OG2 L3 / OG2 (tabela) | było 3 × 15 s |

- Dzisiejszy opis szczebla #2 w `ExerciseCatalog` („jedna noga uniesiona, druga podkurczona”) to wg OG2 i GMB trudniejszy szczebel niż tuck. GMB popiera oba ruchy naraz: nowy szczebel przed tuckiem i przeniesienie starego za tuck.
- Pełny L-sit ma 3 × 20 s, czyli tyle, ile reszta drabiny. 3 × 15 s nie miało źródła i łamało bazę drabiny. RR Skill Day przechodzi dalej przy 30 s, więc 20 s nie jest za dużym celem.

### Planche (`planche`)

| # | Szczebel | Kryterium | Źródło | Zmiana |
|---|---|---|---|---|
| 1 | Stanie żabki | 3 × 30 s | OG2 L3 / RR | bez zmian |
| 2 | **Żabka na prostych rękach** | 3 × 20 s | OG2 L4 / OG2 (tabela) | **nowy** |
| 3 | Tuck planche | 3 × 20 s | OG2 L5 / OG2 (tabela) | było #2 |
| 4 | Advanced tuck planche | 3 × 20 s | OG2 L6 / OG2 (tabela) | było #3 |
| 5 | Planche w rozkroku | 3 × 20 s | OG2 L8 / OG2 (tabela) | było #4 |
| 6 | **Half-lay planche** | 3 × 20 s | OG2 L9 / OG2 (tabela) | **nowy** |
| 7 | Pełna planche | pierwsze 5 s | OG2 L11 / konwencja CaliPark | było #5 |

Wybieramy half-lay zamiast planche na jednej nodze (oba to OG2 L9), żeby było tak samo jak we front i back leverze.

### Flaga (`humanFlag`)

| # | Szczebel | Kryterium | Źródło | Zmiana |
|---|---|---|---|---|
| 1 | Podpór na pionowym drążku | 3 × 20 s | konwencja CaliPark (ćwiczenie wejściowe, brak w źródłach) | bez zmian, etykieta „konwencja” |
| 2 | Tuck flaga | 3 × 20 s | OG2 L5 / OG2 (tabela) | bez zmian |
| 3 | **Advanced tuck flaga** | 3 × 20 s | OG2 L6 / OG2 (tabela) | **nowy** |
| 4 | Flaga w rozkroku | 3 × 20 s | OG2 L7 / OG2 (tabela) | było #3 |
| 5 | Pełna flaga | pierwsze 5 s | OG2 L8 / konwencja CaliPark | było #4 |

**Sprzęt:** wszystkie szczeble mają dziś `Pull-up bar`, a instrukcje mówią „chwyć pionowy drążek”. W puli nie ma klucza na pionowy słupek. Klucz `Monkey bars` ma polską etykietę „Drabinki”, a to po polsku zwykle znaczy drabinki gimnastyczne (wall bars). Propozycja:

- nowy klucz `Vertical pole` („Pionowy drążek”),
- nowy klucz `Wall bars` („Drabinki gimnastyczne”),
- `Monkey bars` dostaje etykietę „Drabinka pozioma”,
- flaga dostaje `["Vertical pole", "Wall bars"]`.

Klucze sprzętu dzieli też formularz zgłoszenia Parku, więc decyzję podejmujemy razem z [modelem Parku](../tickets/012-park-model.md). Przy okazji trzeba zapisać, że `ProgressionStep.equipment` znaczy „którykolwiek z”. Dziś wiosłowanie ma `["Pull-up bar", "Parallel bars"]` i tak to już działa, ale nigdzie tego nie napisano.

### Stanie na rękach (`handstand`)

Przed: podpór przy ścianie → stanie przy ścianie → pompki w staniu przy ścianie.

| # | Szczebel | Kryterium | Źródło | Zmiana |
|---|---|---|---|---|
| 1 | Podpór przy ścianie | 3 × 30 s | konwencja CaliPark (ćwiczenie wejściowe) / RR | bez zmian, etykieta „konwencja” |
| 2 | Stanie na rękach przy ścianie | 3 × 30 s | OG2 L1–L3 (kolumna handstand) / RR | bez zmian |
| 3 | **Pompki pike** | 3 × 8 | OG2 L1 (kolumna pompek w staniu), Cali Move poziom 2 / RR | **nowy** |
| 4 | **Pompki pike z nogami na podwyższeniu** | 3 × 8 | OG2 L2 / RR | **nowy** |
| 5 | **Negatywy pompek w staniu przy ścianie** | 3 × 5, zjazd 5–10 s | OG2 L3 / konwencja CaliPark | **nowy** |
| 6 | Pompki w staniu przy ścianie | 3 × 5 | OG2 L4 / konwencja CaliPark | było #3 |

- Stanie przy ścianie zostaje na #2, a nowe szczeble wchodzą dopiero za nim. Dzięki temu szczebel trzymany i szczebel z pompkami nie zamieniają się miejscami.
- RR na stronach pompek i dipów podaje pompki w staniu jako ścieżkę alternatywną. To pozwala używać pompek pike w programie Fundamenty zamiast dipów (patrz [propozycja 016](016-programs.md)).

### Drobne poprawki bez nowych szczebli

| Drabina | Zmiana | Źródło |
|---|---|---|
| `pushUp` | Pompki pseudo-planche: sprzęt `Push-up handles` → brak. Dziś to tylko etykieta, ale przyszły filtr sprzętu Parku ukryłby ten szczebel. | RR: „Nothing! Or rings” |
| `planche` | Stanie żabki: sprzęt `Push-up handles` → brak (robi się na podłodze). | obserwacja CaliPark, nie ze źródła |
| `row` | Niewiążąca wskazówka przy wiosłowaniu w tuck front lever: „RR najpierw chce 20–30 s tuck front lever”. | RR row |
| `frontLever` | Wskazówka: skin the cat 5 × 2 i arch hang 3 × 8 przed tuckiem. | RR row |
| `backLever`, `muscleUp`, `core` | bez zmian; zgodne z OG2 i RR | research §2 |

## Nowe ćwiczenia w `ExerciseCatalog`

Wszystkie to warianty (`variantOf`) istniejących ruchów głównych, więc zasady integralności 4 i 6 zostają spełnione (lista biblioteki to nadal 19 ruchów). Kolejne stałe UUID: `E0000000-0000-4000-8000-000000000066` i dalej.

| ID (propozycja) | Nazwa PL | Nazwa EN | Miara | Sprzęt | `variantOf` | Na stronę |
|---|---|---|---|---|---|---|
| `archHangID` | Zwis z wygięciem | Arch hang | powt. | Pull-up bar | `pullUpsID` | nie |
| `ringSupportHoldID` | Podpór na kółkach | Ring support hold | sek | Rings | `ringDipsID` | nie |
| `splitSquatID` | Przysiad wykroczny | Split squat | powt. | — | `lungesID` | tak |
| `bulgarianSplitSquatID` | Przysiad bułgarski | Bulgarian split squat | powt. | — (ławka; brak klucza w puli, tak jak przy wejściach na podwyższenie) | `lungesID` | tak |
| `oneFootSupportedLSitID` | L-sit z podporem jednej stopy | One-foot-supported L-sit | sek | Parallel bars, Push-up handles | `lSitID` | tak |
| `straightArmFrogStandID` | Żabka na prostych rękach | Straight-arm frog stand | sek | — | `plancheID` | nie |
| `halfLayPlancheID` | Half-lay planche | Half-lay planche | sek | Push-up handles, Parallel bars | `plancheID` | nie |
| `advancedTuckFlagID` | Advanced tuck flaga | Advanced tuck flag | sek | Vertical pole, Wall bars | `humanFlagID` | nie |
| `pikePushUpsID` | Pompki pike | Pike push-up | powt. | — | `wallHandstandPushUpsID` | nie |
| `elevatedPikePushUpsID` | Pompki pike z nogami na podwyższeniu | Elevated pike push-up | powt. | — (ławka) | `wallHandstandPushUpsID` | nie |
| `wallHandstandPushUpNegativesID` | Negatywy pompek w staniu przy ścianie | Wall handstand push-up negative | powt. | — | `wallHandstandPushUpsID` | nie |

**Zmiany w istniejących ćwiczeniach:**

- flaga `isUnilateral` przy: `archerPullUpsID`, `archerRowsID`, `lungesID`, `stepUpsID`, `assistedPistolSquatsID`, `pistolSquatsID`, `oneLegLSitID`;
- tempo zjazdu w opisach `negativePullUpsID` i `negativeDipsID`, pauza w opisie `scapularPullsID`;
- sprzęt: `pseudoPlanchePushUpsID`, `frogStandID` oraz cztery ćwiczenia flagi.

Opisy i instrukcje piszemy sami, po polsku. Nie tłumaczymy tekstu ze źródeł.

## Wpływ na dane

1. **Warunek wstępny: stabilne ID szczebli (Faza 0 fundamentu, pkt 4 w [010](../tickets/010-training-persistence.md); audyt [A-6, C-5](../../../audit/findings.md)).** `RungReference` i `SkillPlacement.declaredRungByPath` muszą zapisywać `exerciseID` szczebla zamiast indeksu. Migracja starych plików mapuje indeks na `exerciseID` według **obecnej** kolejności drabin. Jeśli migracja i rewizja wejdą w jednym buildzie, migracja potrzebuje zamrożonej kopii starej tabeli indeks → `exerciseID`, bo nie może czytać już zmienionego `ProgressionCatalog`.
2. **`PlacementCalibration` ma zaszyte indeksy** (`zeroRepRung: 2`, `movementRung: 4` przy podciąganiu itd.). Po wstawieniu arch hangu indeksy się przesuwają, więc mapowanie musi przejść na `exerciseID` w tym samym kroku. Skutki dla mapowań:
   - podciąganie: przy „0” nadal negatywy, przy „12+” nadal L-pull-ups;
   - pompki: bez zmian;
   - nogi: przy „12+” nadal wykroki;
   - dipy: przy „12+” aktualnym szczeblem staje się podpór na kółkach zamiast dipów na kółkach. To jest pożądane, bo RR stawia ten warunek przed dipami na kółkach.
3. **Logi** są kluczowane `exerciseID`, więc nic w nich nie zmieniamy.
4. **Szczeble wstawione poniżej zaliczonego liczą się jako zaliczone.** Silnik (`ProgressionEngine.pathState`) uznaje wszystko poniżej najwyższego zaliczonego szczebla za zaliczone. Dlatego:
   - nie powstają „dziury” w drabinie;
   - XP rośnie jednorazowo, bo `experiencePoints` liczy zaliczone szczeble razy bonus. To może dać awans poziomu bez treningu. Rekomendacja: zaakceptować przed TestFlightem, bo dotyczy tylko testerów. Druga opcja to nie liczyć XP za szczeble zaliczone wyłącznie przez wstawienie.
   - Celebracje kluczowane `exerciseID` się nie powtarzają.
5. **Luka w silniku do naprawy razem z rewizją:** `ProgressionEngine` nie czyta `isParallelTrack`. Aktualny szczebel to po prostu pierwszy niezaliczony, więc już dziś osoba po negatywach widzi gumę jako aktualny szczebel. Po rewizji osoba po przysiadzie bułgarskim zobaczy wejścia na podwyższenie. Propozycja: przy wyborze aktualnego szczebla pomijać szczeble równoległe. Potrzebny test.
6. **Testy:** zamrożona mapa kolejności drabin, czyli test, który pada przy każdej zmianie kolejności (sugestia weryfikatora C-5). Do tego nowe ćwiczenia w `ProgressionCatalogTests`, a `PROGRESSIONS.md` i `ProgressionCatalog` zmieniamy w jednym commicie, 1:1.
7. **Sync:** flaga `isUnilateral` i `criterionSource` żyją w statycznym katalogu, nie w zapisanych danych, więc nie dotykają schematu syncu ([009](../tickets/009-sync-tech.md)). Tylko punkt 1 zmienia format plików i musi wejść przed pierwszym buildem TestFlight z syncem.

## Pytania do właściciela

1. **Czy przyjmujesz rewizję w tym kształcie** (11 nowych szczebli, przeniesiony L-sit na jednej nodze, nic nie znika), wdrażaną zaraz po Fazie 0? *Rekomendacja: tak.*
2. **Statyki: zostaje 3 × 20 s** (opisane jako „wyprowadzone z tabeli OG2”) **czy przechodzimy na RR-owe 3 × 30 s?** *Rekomendacja: zostaje 3 × 20 s. 30 s przy tuck planche czy tuck fladze to dla większości miesiące stania w miejscu.*
3. **Pełny L-sit: 3 × 20 s czy marker „pierwsze 5 s”** jak przy dźwigniach? *Rekomendacja: 3 × 20 s. Pełny L-sit jest osiągalny, a RR i tak przechodzi dalej przy 30 s.*
4. **Ruchy jednostronne: tylko tekst „na stronę”** (wpisujesz wynik słabszej strony) **czy osobne logowanie lewej i prawej?** *Rekomendacja: tylko tekst w 1.0. Osobne strony zmieniają format logów.*
5. **Szczeble bez źródła** (zwis na drążku, podpór przy ścianie, podpór na pionowym drążku) **oraz podciągnięcia z gumą: zostają z etykietą „konwencja CaliPark” / „Cali Move”?** *Rekomendacja: tak, wszystkie zostają. Są sensownymi wejściami, a uczciwa etykieta wystarcza.*
6. **Sprzęt: nowe klucze „Pionowy drążek” i „Drabinki gimnastyczne” oraz zmiana etykiety `Monkey bars` na „Drabinka pozioma”?** *Rekomendacja: tak. Decyzję podejmujemy razem z modelem Parku (012), bo te same klucze trafią do formularza zgłoszenia.*

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
