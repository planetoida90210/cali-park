# Zrzuty do App Store

Sześć zrzutów iPhone'a 6,9" (1320 × 2868, bez kanału alfa), w kolejności z App Store Connect:

| Plik | Ekran |
|---|---|
| `01-home` | Start: plan „Fundamenty” na dziś i pierścień celu tygodniowego |
| `02-ladder` | Ścieżka „Podciąganie” z kryteriami szczebli |
| `03-programs` | „Gotowe programy” |
| `04-workout` | Trening z parami, licznikiem rund i przerwą |
| `05-profile` | Profil: seria tygodni, seria dni, poziom, cel tygodniowy |
| `06-parks` | Mapa Parków (centrum Warszawy) z kartą Parku |

- `raw/`: zrzuty z symulatora w natywnej rozdzielczości, z paskiem statusu 9:41.
- `framed/`: te same zrzuty na tle #121212 z nagłówkiem (SF Rounded, akcent #D1FF00). Nagłówki są w tabeli „Zrzuty ekranu” w [`../app-store-listing.md`](../app-store-listing.md).

## Jak odświeżyć

```sh
scripts/store-screenshots.sh            # zrzuty + kadrowanie (~3 min z budowaniem)
xcrun swift scripts/frame-store-screenshots.swift   # tylko kadrowanie, np. po zmianie nagłówka
```

`store-screenshots.sh` uruchamia symulator „iPhone 17 Pro Max” z iOS 26.5 (inny: `--udid <UDID>` albo `STORE_SHOTS_DEVICE`/`STORE_SHOTS_OS`), ustawia czysty pasek statusu, przechodzi test UI `StoreScreenshotTour` na seedzie `storeTour` i eksportuje załączniki z `.xcresult` do `raw/`. Na koniec zdejmuje nadpisany pasek statusu. `--no-frame` pomija kadrowanie; `STORE_SHOTS_DERIVED_DATA=<katalog>` używa istniejącego DerivedData zamiast budować od zera.

`StoreScreenshotTour` jest pomijany w zwykłych testach UI i w CI: działa tylko z `TEST_RUNNER_CALIPARK_STORE_SHOTS=1`, które ustawia skrypt.

## Ograniczenia

- Seed liczy dni od dzisiaj. Pierścień tygodnia pokazuje 0 / 3 w poniedziałek, 1 / 3 we wtorek i 2 / 3 od środy, więc zrzuty rób od środy do niedzieli.
- Mapa ładuje kafelki z serwerów Apple, więc potrzebny jest internet; test czeka na nie 4 sekundy.
- Przerwa na `04-workout` odlicza czas, więc pokazuje 1:29 albo 1:28.
