# Gotowe programy treningowe — dokument-prawda

Ten dokument jest **jedynym źródłem prawdy** dla gotowych programów. Kod
(`ProgramCatalog` w `cali-park/Features/Programs/Services/ProgramCatalog.swift`)
jest jego odbiciem 1:1. Zmiana programu to zmiana tu i tam naraz, a zmiana
treści programu podbija jego `version`.

Decyzja: [ticket 016](wayfinder/calipark-1.0/tickets/016-programs-v1.md),
[propozycja ze źródłami](wayfinder/calipark-1.0/proposals/016-programs.md).
Drabiny: [PROGRESSIONS.md](PROGRESSIONS.md).

## Zasady

- Program wskazuje **drabinę**, nie ćwiczenie. Plan z programu trenuje
  aktualny szczebel głównej linii (silnik pomija tory równoległe). Kiedy
  użytkownik awansuje, sesja startowana z planu sama przechodzi na nowy
  szczebel (`ProgramPrescriber.resolved`).
- Program tworzy **zwykły plan** do edycji, z zapisanym `programID` i
  `programVersion`. Harmonogram startowy można zmienić w edytorze.
- **Dawka serii (RR):** 3 serie. Powtórzenia od ok. 60 % celu szczebla do celu
  (3 × 8 → 3 × 5–8, 3 × 5 → 3 × 3–5, 3 × 3 → 3 × 2–3). Holdy od 10 s do celu
  szczebla (3 × 30 s → 3 × 10–30 s, 3 × 20 s → 3 × 10–20 s, 1 × 60 s →
  3 × 10–60 s). Ćwiczenie spoza drabin: 3 × 5–8 albo 3 × 10–30 s.
- **Podpowiedź na sesję:** powtórzenia = najlepsza seria z ostatniej sesji
  tego ćwiczenia + 1, w zakresie; bez historii dolna granica zakresu. Holdy =
  najlepszy hold z ostatniej sesji, w zakresie; bez historii dolna granica.
- Wszystkie opisy są nasze, po polsku. Nigdy nie piszemy, że program jest
  oficjalny. Programy oparte na RR są darmowe.

## Programy

| ID (`ProgramID`) | Nazwa | Wersja | Dni startowe | Czas |
|---|---|---|---|---|
| `minimum` | Minimum | 1 | pn, śr, pt | ok. 15–25 min |
| `fundamentals` | Fundamenty | 1 | pn, śr, pt | ok. 45–60 min |
| `firstPullUp` | Pierwsze podciągnięcie | 1 | pn, śr, pt | ok. 30–40 min |
| `skills` | Skille | 1 | wt, czw | ok. 15–20 min |

### Minimum — `minimum`

Podpis: „Na podstawie Minimalist Routine z wiki r/bodyweightfitness. CaliPark
nie jest z nią powiązany.”

Jeden obwód (grupa 1), 2–6 rund, każda seria 1–2 powtórzenia przed upadkiem
(`repsInReserve: 2`), bez stałej liczby serii i powtórzeń.

| # | Drabina / ćwiczenie | Dawka |
|---|---|---|
| 1 | `legs` | obwód 2–6 rund, 1–2 w zapasie |
| 2 | `pushUp` | jw. |
| 3 | `row` | jw. |
| 4 | Deska z dotknięciem barku (`plankShoulderTapsID`, poza drabinami) | jw., na stronę |

### Fundamenty — `fundamentals`

Podpis: „Inspirowane Recommended Routine społeczności r/bodyweightfitness.
Program nie jest oficjalny ani zatwierdzony przez jej autorów.” Wersja
„inspirowane RR” na obecnych drabinach; zawias biodrowy i pełny core RR
przyjdą w 1.1.

| Para | Drabiny | Dawka | Przerwa |
|---|---|---|---|
| 1 | `pullUp` ↔ `legs` | dawka serii RR | 90 s |
| 2 | `dip` ↔ `core` | dawka serii RR | 90 s |
| 3 | `row` ↔ `pushUp` | dawka serii RR | 90 s |

Rozgrzewka 5–10 min i zamiana dipów na drabinę stania na rękach są tylko w
opisie. Kto nie ma pełnego podciągnięcia (aktualny szczebel poniżej
`pullUpsID`), widzi podpowiedź „Pierwsze podciągnięcie”.

### Pierwsze podciągnięcie — `firstPullUp`

Podpis: „Program CaliPark oparty na zasadach z Recommended Routine
(r/bodyweightfitness), StartBodyweight i Cali Move.”

| # | Drabina | Dawka | Przerwa |
|---|---|---|---|
| 1 | `pullUp` (na świeżo) | dawka serii RR | — |
| 2 | `row` | dawka serii RR | — |
| 3 | `pushUp` ↔ `legs` (para 1) | dawka serii RR | 90 s |

Tor z gumą jest opcją drabiny, program go nie wybiera. Wyjście: przy
zaliczonych pełnych podciągnięciach (3 × 8) `ProgramPrescriber.isReadyToGraduate`
mówi, że czas na Fundamenty (na razie bez ekranu, który to pokazuje).

### Skille — `skills`

Podpis: „Bloki stania na rękach i L-situ na podstawie Skill Day z wiki
r/bodyweightfitness. CaliPark nie jest z nią powiązany.”

| # | Drabina | Dawka |
|---|---|---|
| A | `handstand`, tylko szczeble trzymane (`holdRungsOnly`) | do 10 min praktyki |
| B | `lSit` | holdy 10–30 s, łącznie do 3 min |

Gdy aktualny szczebel stania na rękach to już pompki (pike i wyżej), blok A
zostaje na najwyższym szczeblu trzymanym poniżej, czyli staniu przy ścianie.
Blok C (statyki z tabelą OG2) jest w 1.1.

## Podpowiedź w onboardingu

Po teście „Co już potrafisz?”: odpowiedź „0” przy podciąganiu (deklaracja
poniżej pełnych podciągnięć) → **Pierwsze podciągnięcie**, w każdym innym
przypadku (także bez odpowiedzi) → **Fundamenty**. Minimum i Skille można
wybrać ręcznie, można też wybrać „Bez programu”.

## Pola planu (wszystkie opcjonalne)

`WorkoutPlan`: `programID`, `programVersion`. `PlannedExercise`: `pathID`,
`holdRungsOnly`, `targetRepsMin` (z `targetReps` jako górą), `targetSeconds`,
`targetSecondsMin`, `restSeconds`, `group`, `rounds`, `repsInReserve`,
`timeBoxMinutes`, `totalSeconds`. Stare pliki planów (goły format i koperta
`schemaVersion: 1`) wczytują się bez zmian, a koperta zostaje w wersji 1, bo
nowe klucze tylko dochodzą. Nieznana drabina albo zepsuty zakres rund gubi
tylko to jedno pole.

## Ćwiczenia spoza drabin

| ID | Nazwa | Wariant | Miara |
|---|---|---|---|
| `plankShoulderTapsID` (`…000000000077`) | Deska z dotknięciem barku | `plankID` | powtórzenia, na stronę |
