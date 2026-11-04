---
title: "Propozycja: model Parku i sprzętu"
ticket: tickets/012-park-model.md
date: 2026-11-03
status: do potwierdzenia przez właściciela
---

# Propozycja: model Parku i sprzętu

Opiera się na researchu [osm-parks-poland.md](../../research/osm-parks-poland.md) (dalej „OSM”) i [appstore-compliance.md](../../research/appstore-compliance.md) (dalej „Compliance”). Wartości OSM sprawdzone 2026-11-03 na wiki [Key:fitness_station](https://wiki.openstreetmap.org/wiki/Key:fitness_station) i [Key:surface](https://wiki.openstreetmap.org/wiki/Key:surface). **[szacunek]** oznacza moją ocenę.

## W skrócie

- **Trzy warstwy danych, osobno od początku:**
  - **Fakty Parku** (ODbL, publiczny plik do pobrania),
  - **Społeczność** (opinie, oceny, zdjęcia; nasze),
  - **dane prywatne** (autor Zgłoszenia, log moderacji).
  
  Dziś `Park` miesza wszystkie trzy.
- **Wymagane są tylko:** położenie, dowód, że to Park (drążek, poręcze albo „kalistenika” z OSM), źródło i status. Cała reszta jest opcjonalna, bo OSM ma sprzęt dla 8% miejsc i nazwę dla 6%.
- **Sprzęt opisujemy 1:1 wartościami OSM `fitness_station`.** Polskie nazwy są tylko w UI. Do flagi służy `fitness_pole` (słup do flagi). „Drabinki” rozbijamy na dwa klucze.
- **Nazwa:** nazwa z OSM, a gdy jej brak, nazwa generowana z danych OSM (np. „Street workout · Park Skaryszewski”). Użytkownik może zaproponować nazwę, a Moderator ją zatwierdza. Nic z MapKit nie trafia do bazy.
- **Dwie osobne osie:**
  - status moderacji: `draft → pending → published → removed`, plus `rejected` i `candidate`, z kodem i uzasadnieniem usunięcia dla DSA,
  - poziom weryfikacji: `osm` / `community` / `verified`.

## 1. Warstwy danych

| Warstwa | Co zawiera | Licencja / dostęp | Dlaczego osobno |
|---|---|---|---|
| **Fakty Parku** | położenie, nazwa, sprzęt, nawierzchnia, oświetlenie, dostęp, status, źródło | ODbL, publiczny dump bez danych osobowych | Mieszamy OSM ze Zgłoszeniami, więc share-alike (OSM §4.3–4.4) |
| **Społeczność** | opinie, oceny, zdjęcia, okładka | Nasza (Collective Database, OSM §4.3). Licencja od autorów w regulaminie | Nie może trafić do dumpu ODbL |
| **Prywatne** | autor Zgłoszenia (ID Konta), zgłoszenia DSA, decyzje Moderatora, uzasadnienia | Tylko backend, RLS | RODO; DSA art. 16–17 |
| **Lokalne** | ulubione, dystans | Telefon | Nie są faktem o Parku |

## 2. Pola Parku

### Wymagane (żeby Park był `published`)

| Pole | Typ | Skąd | Dlaczego wymagane |
|---|---|---|---|
| `id` | UUID | backend | Identyfikatory OSM się zmieniają (punkt staje się obszarem); OSM §3 |
| `location` | punkt WGS84 (lat, lon) | OSM (środek obszaru) albo pinezka użytkownika | Bez tego nie ma mapy |
| `status` | enum (§5) | moderacja | Co widać publicznie |
| `source` | `osm` / `user` / `team` | import albo Zgłoszenie | Atrybucja ODbL („Źródło: OpenStreetMap”) i zasady odświeżania |
| `osmRefs` | lista `n123` / `w456` / `r789` | import | Dopasowanie przy cotygodniowym imporcie. Wymagane, gdy `source = osm` |
| `parkEvidence` | co najmniej jeden sprzęt z rdzenia (§3). ~~**albo** `sport=calisthenics` z OSM~~: odrzucone dopiskiem właściciela w [tickecie 012](../tickets/012-park-model.md) | sprzęt | Definicja Parku z GLOSSARY. Miejsca z samym `sport=calisthenics`, bez listy sprzętu (86 Parków klasy A w OSM §2), nie są Parkami |
| `verification` | `osm` / `community` / `verified` (§5) | moderacja | Zaufanie i odznaka na karcie |
| `locality` | gmina/miasto + dzielnica/osiedle | **liczy backend z granic administracyjnych OSM** | Lista, wyszukiwarka i nazwa zastępcza. Nie z geokodowania Apple (§4) |
| `createdAt`, `updatedAt` | data | backend | Świeżość danych, różnice w dumpie |

### Opcjonalne

| Pole | Wartości | Tag OSM | Dlaczego opcjonalne |
|---|---|---|---|
| `name` | tekst 3–40 znaków | `name` | Ma je tylko ok. 6% miejsc (119 z 334 Parków A). Zastępczą nazwę podaje §4 |
| `nameSource` | `osm` / `user` / `moderator` | — | Atrybucja i zasada nadpisywania przy imporcie |
| `equipment` | lista `{type, count?, heights?}` (§3) | `fitness_station` | 92% miejsc w OSM nie ma sprzętu. Lista Parku nigdy nie jest pusta: zawsze ma sprzęt z rdzenia (dopisek w tickecie 012) |
| `hasMachines` | bool | wartości maszyn (§3) | Informacja „obok siłownia z maszynami” przy Parkach mieszanych (48 w OSM) |
| `surface` | `rubber`, `tartan`, `artificial_turf`, `sand`, `woodchips`, `grass`, `ground`, `gravel`, `paving_stones`, `concrete`, `asphalt` | `surface` | Rzadkie w OSM (315 miejsc); użytkownik może poprawić |
| `lit` | tak / nie / nieznane | `lit` | Rzadkie (276); przydatne zimą |
| `covered` | tak / nie / nieznane | `covered` | Rzadkie; ważne w deszczu |
| `access` | `public` / `customers` / `private` | `access` | Domyślnie `public`. `private` nie publikujemy (to nie Park według GLOSSARY); 115 miejsc w OSM |
| `openingHours` | składnia OSM `opening_hours` | `opening_hours` | 413 miejsc; domyślnie „brak danych”, a nie „24 h” |
| `nearbyWater`, `nearbyToilets` | bool | **liczone** z `amenity=drinking_water` / `amenity=toilets` w promieniu 150 m **[szacunek]** | Nikt tego nie musi wpisywać; zgodne z ODbL |
| `fieldSources` | źródło dla `name`, `location`, `equipment` | — | Import OSM nadpisuje tylko pola ze źródłem `osm`. Konflikty trafiają do kolejki Moderatora (OSM §Rekomendacja 2) |
| `lastConfirmedAt` | data | Zgłoszenie, zdjęcie, wizyta ekipy | Pokazuje „potwierdzone w maju 2026”; dane OSM bywają stare (15,6% miejsc nie ruszane od 2020) |

### Celowo **poza** Faktami Parku

- **Ocena i liczba opinii.** Liczy je warstwa Społeczności, nie zapisujemy ich w Parku.
- **Zdjęcia i okładka.** Warstwa Społeczności, wskazuje na `parkId`.
- **Wolny opis (`description`).** W v1 nie: koszt moderacji, a opis trafiłby do dumpu ODbL. Opisy pełnią rolę opinii.
- **Cień, parking, wiatr.** OSM nie ma na nie tagów, są subiektywne i mało ważne. Cień mógłby kiedyś być tagiem w opinii.
- **Tłok, wydarzenia.** v1.1.

## 3. Taksonomia sprzętu

Klucz w kodzie i w bazie = wartość OSM `fitness_station`. Polskie nazwy są w String Catalog. **Rdzeń** = sprzęt, który sam robi z miejsca Park.

| Klucz (= OSM) | UI (pl) | Rdzeń? | Uwagi |
|---|---|---|---|
| `horizontal_bar` | Drążek | **tak** | `count`, `heights` ⊂ {niski, średni, wysoki} **[szacunek: bez centymetrów]** |
| `parallel_bars` | Poręcze | **tak** | `count` |
| `dip_bench` | Poręcze do dipów | **tak** | W OSM to „uproszczone poręcze do dipów”. Rdzeń, jak w klasie A z researchu |
| `rings` | Kółka | pytanie 1 | Dziś klasa C |
| `horizontal_ladder` | Drabinka pozioma („małpi gaj”) | pytanie 1 | Dziś klasa C. Nie „Drabinki” |
| `wall_bars` | Drabinka gimnastyczna (szwedzka) | nie | Dziś klasa C. Nie „Drabinki”. Nadaje się do flagi na drabince |
| `fitness_pole` | Słup do flagi | nie | Wiki OSM: „smooth pole for human flags”. **Tego brakuje do flagi** |
| `climbing_pole` | Słup do wspinania | nie | Pionowy słup; też da się na nim robić flagę |
| `captains_chair` | Poręcze z oparciem (unoszenie nóg) | nie | Klasa C |
| `push-up` | Niskie drążki do pompek | nie | |
| `sit-up` | Ławka do brzuszków | nie | |
| `stretch_bars` / `stretching` | Drążki do rozciągania | nie | Na imporcie dwie wartości OSM dają jeden klucz |
| `box` | Skrzynia do skoków | nie | |
| `balance_beam` | Równoważnia | nie | |
| `battling_ropes`, `tire`, `punching_bag` | Inne | nie | Import tak, filtr w UI nie |

**Możliwość „flaga”** (do filtra i do szczebli flagi w `docs/PROGRESSIONS.md`) = `fitness_pole` ∨ `climbing_pole` ∨ `wall_bars`. **[szacunek]** Pionowe słupki konstrukcji drążków też się czasem nadają, ale nie da się tego wiedzieć z danych.

### Siłownie z samymi maszynami: jak je wykluczamy

- **Maszyny** (nie są sprzętem Parku): `air_walker`, `elliptical_trainer`, `rower`, `chest_press`, `bench_press`, `shoulder_press`, `leg_press`, `leg_extension`, `pull_down`, `ski_swing`, `ab_twist`, `stepper`, `exercise_bike`, `hand_bike`, `steering_wheel`, `rider`, `fly`, `horizontal_fly`, `arm_extension`, `squat`, `back_massager`, `leg_stretching`. Wartości spoza tej listy i spoza tabeli wyżej (np. `bent_over_row`, `tbar_row`, `preacher_curl`, `treadmill`) też traktujemy jak maszyny.
- **Reguła importu:**
  - Park = **rdzeń** ∨ `sport ∋ calisthenics` (klasa A),
  - sama nazwa „street workout / kalistenika / drążki” = klasa B, czyli przegląd przed publikacją,
  - same maszyny albo „inne” (klasy D i E) = **nigdy** nie jest Parkiem,
  - brak danych (klasa F) i klasa C = ukryty `candidate`.
- **Maszyny przy Parku nie są listowane jako sprzęt.** Ustawiamy tylko `hasMachines = true`.
- **Wolne wartości po polsku z OSM** (`drabinki`, `siłownia_zewnętrzna`, „brzuszki, podciągania…”): parser dzieli je po `;` i `,`. Mapuje tylko jednoznaczne słowa („drążek” → `horizontal_bar`, „poręcze” → `parallel_bars`). „Drabinki” jest dwuznaczne, więc trafia do przeglądu, a nie do sprzętu.
- **Zgłoszenie od użytkownika** musi zawierać co najmniej jeden sprzęt z rdzenia. Inaczej formularz nie pozwoli go wysłać, bo to nie jest Park.

## 4. Nazwa Parku bez śmieci

Zasada (Compliance §2.8): **niczego z MapKit (`MKLocalSearch`, `CLGeocoder`, reverse geocoding) nie zapisujemy w bazie Parków.** Nawet jako podpowiedzi do zaakceptowania, bo zaakceptowana podpowiedź to nadal Map Data od Apple **[interpretacja]**. Nazwy z OSM wolno nam trzymać (ODbL).

Kolejność wyboru nazwy wyświetlanej:

1. **`name` z OSM**, jeśli jest.
2. **`name` od użytkownika**, zatwierdzone przez Moderatora (§ niżej).
3. **Nazwa generowana przez backend przy imporcie i przy Zgłoszeniu**, tylko z danych OSM:
   - Park leży w nazwanym `leisure=park` / `landuse=recreation_ground` → „Street workout · Park Skaryszewski”,
   - inaczej, gdy w promieniu 30 m **[szacunek]** jest nazwana szkoła (`amenity=school`) albo boisko → „Street workout · przy SP 12”,
   - inaczej najbliższa nazwana ulica do 50 m → „Street workout · ul. Kasprzaka”,
   - inaczej dzielnica albo osiedle z `locality` → „Street workout · Mokotów”.
   
   Przedrostek bierzemy ze sprzętu: „Street workout”, gdy są drążek i poręcze, a „Drążki” albo „Poręcze”, gdy jest tylko jedno z nich.

Nazwa wpisana w Zgłoszeniu:
- **Pole opcjonalne** z podpowiedzią „Tylko oficjalna nazwa, np. z tabliczki”. Domyślnie formularz pokazuje nazwę generowaną z pkt 3.
- **Walidacja na telefonie i na serwerze:**
  - 3–40 znaków,
  - bez emoji, linków, numerów telefonu i CAPS LOCKA,
  - filtr słów z moderacji Społeczności.
- **Moderator może poprawić nazwę albo ją usunąć.** Wtedy wraca nazwa generowana, a `nameSource = moderator`.
- **Poprawka nazwy istniejącego Parku idzie przez tę samą kolejkę** (ticket 014).

## 5. Status moderacji i weryfikacja

### Status (`status`): czy i komu Park jest widoczny

```
candidate ──(Moderator: „to Park”)──────────────────┐
                                                    ▼
draft ──(wyślij)──► pending ──(akceptuj)──► published ──(usuń)──► removed
                      │                         ▲                    │
                      └──(odrzuć)──► rejected   └──(przywróć, np. po odwołaniu)┘
```

| Status | Kto widzi | Uwagi |
|---|---|---|
| `candidate` | nikt (tylko backend) | Ukryte miejsca OSM z klas C i F. Służą do wykrywania duplikatów („Czy to ten park?”) i do potwierdzeń w v1.1 |
| `draft` | autor, **tylko na telefonie** | Szkic Zgłoszenia nie trafia na serwer, więc do wysłania nie przetwarzamy danych osobowych |
| `pending` | autor + Moderatorzy | Czeka na decyzję. Limit Zgłoszeń dziennie na Konto |
| `published` | wszyscy | Wchodzi do dumpu ODbL |
| `rejected` | autor + Moderatorzy | Zgłoszenie nie przeszło. **Wysyłamy uzasadnienie (DSA art. 17)**: to ograniczenie treści od użytkownika **[interpretacja]** |
| `removed` | Moderatorzy (autor dostaje uzasadnienie) | Zdjęty po publikacji. Rekordu nie kasujemy, bo potrzebujemy historii i przekierowania opinii |

Rekord decyzji (tabela prywatna `moderation_decisions`, dla `rejected` i `removed`):

| Pole | Po co |
|---|---|
| `reasonCode` | `not_a_park` (same maszyny, brak drążka), `duplicate` (+ `mergedInto: UUID`), `does_not_exist` (zlikwidowany), `wrong_location`, `private_access`, `spam`, `terms_violation`, `illegal_content`, `authority_order` |
| `ground` | `contract` (paragraf regulaminu) albo `law` (przepis). Wymagane przez DSA art. 17 ust. 3 lit. d–e |
| `explanation` | Tekst dla autora: fakty i okoliczności (art. 17 ust. 3 lit. b) |
| `triggeredByNotice` | ID zgłoszenia DSA (art. 16), jeśli decyzja z niego wynika |
| `automated` | Czy decyzję podjął filtr (art. 17 ust. 3 lit. c) |
| `decidedBy`, `decidedAt` | Kto i kiedy; odpowiedź w 24 h (Apple 1.2) |
| `redress` | Stały tekst: odwołanie mailem, sąd (art. 17 ust. 3 lit. f) |

Uwagi:
- Parki z `source = osm` nie mają autora. `does_not_exist` czy `duplicate` dla nich nie wymaga uzasadnienia DSA. Zapisujemy tylko powód.
- Gdy OSM usunie obiekt, **nie kasujemy Parku automatycznie**. Park trafia do kolejki z `reasonCode` do potwierdzenia (OSM §Rekomendacja 2).
- `duplicate`: opinie i zdjęcia przenosimy do `mergedInto`, a stary `id` przekierowuje.

### Weryfikacja (`verification`): jak bardzo ufamy danym

| Poziom | Znaczenie | UI |
|---|---|---|
| `osm` | Z OSM, nikt od nas nie sprawdził (klasa A spoza 5 miast) | „Z OpenStreetMap” + atrybucja |
| `community` | Zaakceptowane Zgłoszenie ze zdjęciem z miejsca albo przegląd Moderatora (5 miast przed TestFlightem) | bez odznaki |
| `verified` | Ekipa była na miejscu (+ `verifiedAt`) | odznaka „Zweryfikowany”. Szczegóły w tickecie 014 |

Status i weryfikacja to **osobne osie**. Park może być `published` + `osm` albo `published` + `verified`.

## 6. Co jest nie tak w obecnym `cali-park/Features/Parks/Models/`

| Plik | Problem | Co zamiast |
|---|---|---|
| `Park.swift` | `name` i `city` wymagane, `city` po angielsku („Warsaw”). Nie ma skąd ich wziąć bez geokodowania Apple | `name` opcjonalne + nazwa wyświetlana z §4; `locality` z backendu |
| `Park.swift` | `rating`, `images`, `isFavorite`, `distance` w modelu Parku i w `Codable` | Ocena i zdjęcia → warstwa Społeczności; ulubione → `FavoritesStoring` (to też źródło audytu C-14); dystans liczony w widoku |
| `Park.swift` | Brak `status`, `source`, `osmRefs`, `verification`, dat, `access`, `lit`, `surface` | §2 |
| `Park.swift` | `==` porównuje tylko część pól (bez sprzętu, tagów, położenia), więc SwiftUI nie odświeży widoku po zmianie sprzętu | Zwykłe syntezowane `Equatable` |
| `Park.swift` | `description` jako wolny tekst | Poza v1 (§2) |
| `EquipmentItem.swift` | Klucze to angielskie stringi („Pull-up bar”) bez mapowania na OSM. W liście są rzeczy, których w Parku nie ma (`Kettlebell`, `Medicine ball`, `Resistance bands`, `Sledge hammer`, `Battle ropes`, `Tires`, `Climbing rope`) | `enum EquipmentType: String` = wartości OSM z §3 |
| `EquipmentItem.swift` | „Monkey bars” → „Drabinki”: dwuznaczne (`horizontal_ladder` czy `wall_bars`). Brak słupa do flagi | Dwa klucze i `fitness_pole` |
| `EquipmentItem.swift` | `let id = UUID()`: nowe ID przy każdym `items(from:)`, więc SwiftUI przy każdym odświeżeniu widzi nowe elementy | `id` = klucz sprzętu |
| `EquipmentItem.swift` | Brak liczby i wysokości drążków | `count`, `heights` |
| `ParkTag.swift` | Jednoliterowe kody. `light` ma etykietę „24 h” (oświetlenie to nie godziny otwarcia), a `roof` ma etykietę „most”. `public` blokuje Swift 6 (audyt D-1) | Osobne pola `lit`, `covered`, `surface`, `openingHours`. `shade`, `parking`, `wind` usuwamy |
| `ParkTag.swift` | `ground = rubber` jako bool | `surface` jako enum OSM |
| `CommunityPhoto.swift` | `likes`, `isLikedByMe` (Apple to liczy jako „Social Media” → 13+, zob. propozycja 021), `visibility: .friendsOnly` (w v1 nie ma znajomych), `uploaderName` zamiast ID Konta | v1: bez polubień i znajomych; `authorAccountId` + Pseudonim z Konta |
| `User.swift` | `name`, `bio`, `avatarURL`: GLOSSARY mówi, że jedyną publiczną tożsamością jest Pseudonim | `Account { id, nickname }` |
| `ParkEvent.swift` | Wydarzenia są w v1.1 | Poza v1 |
| `Exercise.equipment` / `docs/PROGRESSIONS.md` | Te same angielskie stringi co `Park.equipments`. Flaga w PROGRESSIONS ma „Pull-up bar”, a potrzebny jest pionowy słup | Przy wdrożeniu przemapować na klucze OSM w `ExerciseCatalog` i w PROGRESSIONS.md 1:1 (zasada z CLAUDE.md); flaga → `fitness_pole` ∨ `climbing_pole` ∨ `wall_bars` |

## 7. Szkic typów (do wdrożenia później, nie teraz)

```swift
enum ParkStatus: String, Codable, Sendable { case candidate, draft, pending, published, rejected, removed }
enum ParkVerification: String, Codable, Sendable { case osm, community, verified }
enum ParkSource: String, Codable, Sendable { case osm, user, team }
enum EquipmentType: String, Codable, Sendable, CaseIterable { case horizontalBar = "horizontal_bar", parallelBars = "parallel_bars", dipBench = "dip_bench", rings, horizontalLadder = "horizontal_ladder", wallBars = "wall_bars", fitnessPole = "fitness_pole", climbingPole = "climbing_pole" /* … */ }

struct ParkEquipment: Codable, Hashable, Sendable { var type: EquipmentType; var count: Int?; var heights: Set<BarHeight>? }

struct Park: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var latitude: Double, longitude: Double
    var status: ParkStatus
    var verification: ParkVerification
    var source: ParkSource
    var osmRefs: [String]
    var name: String?            // proper name only
    var generatedName: String    // computed by the backend from OSM (§4)
    var locality: Locality       // { city, district? } from OSM boundaries
    var equipment: [ParkEquipment]
    var isCalisthenicsTagged: Bool
    var hasMachines: Bool
    var surface: Surface?; var lit: Bool?; var covered: Bool?
    var access: ParkAccess; var openingHours: String?
    var nearbyWater: Bool; var nearbyToilets: Bool
    var lastConfirmedAt: Date?; var createdAt: Date; var updatedAt: Date
    var displayName: String { name ?? generatedName }
}
```

## Pytania do właściciela

1. **Czy kółka (`rings`) i drabinka pozioma (`horizontal_ladder`) bez drążka wystarczą, żeby miejsce było Parkiem?** Rekomendacja: **tak dla obu**, bo da się na nich podciągać. **Nie** dla samej drabinki gimnastycznej i poręczy z oparciem. To zmienia GLOSSARY i dodaje część z 62 miejsc klasy C.
2. **Czy wycinamy z modelu wolny opis Parku oraz tagi cień, parking i wiatr?** Rekomendacja: **tak**. Opis trafiłby do otwartego dumpu i wymaga moderacji, a tagi są subiektywne i OSM ich nie ma.
3. **Czy nazwy generowane („Street workout · Park Skaryszewski”) są OK jako domyślne, a użytkownik może tylko zaproponować oficjalną nazwę z tabliczki?** Rekomendacja: **tak**. Bez tego dostaniemy nazwy typu „Mój park 💪”.
4. **Liczba i wysokość drążków: zbieramy w v1?** Rekomendacja: **tak, ale opcjonalnie i bez centymetrów**: liczba plus niski/średni/wysoki. Wysoki drążek to pytanie nr 1 osób, które robią muscle-upy **[szacunek]**.
5. **Ukryte kandydaty z OSM (6,9 tys. miejsc bez sprzętu): zostają w bazie tylko do wykrywania duplikatów?** Rekomendacja: **tak** w v1, a warstwa „Czy są tu drążki?” w v1.1. To samo pytanie jest w tickecie 020; decyzję podjąć raz.
