---
title: Parki z OpenStreetMap w Polsce i licencja ODbL
type: research
mode: AFK
status: closed
assignee: planetoida90210
blocked_by: []
---

# Parki z OpenStreetMap w Polsce i licencja ODbL

## Pytanie

Czy OpenStreetMap wystarczy do zasilenia bazy Parków w Polsce? Do ustalenia:
- które tagi oznaczają sprzęt do kalisteniki i jak odsiać siłownie z samymi maszynami,
- ile takich miejsc faktycznie jest w Polsce i dużych miastach,
- jaka jest jakość tych danych,
- co dokładnie wymusza licencja ODbL (atrybucja, share-alike przy mieszaniu ze Zgłoszeniami),
- jakie są alternatywne źródła.

Wynik: [research/osm-parks-poland.md](../../research/osm-parks-poland.md) (zweryfikowany).

## Rozstrzygnięcie (2026-11-03)

Szczegóły, zapytania i liczby są w [research/osm-parks-poland.md](../../research/osm-parks-poland.md). Weryfikator przeliczył dane na żywym Overpass.

- **Liczby:** w Polsce jest ok. 9,2 tys. obiektów `leisure=fitness_station`, ale tylko **ok. 385–393 Parki** pewnie spełniają naszą definicję (drążek, poręcze albo `sport=calisthenics`). W 5 dużych miastach to ok. 107: Warszawa 26, Kraków 23, Wrocław 16, Poznań 32, Gdańsk 11. 92% miejsc nie ma tagów sprzętu, a tylko 6% ma nazwę.
- **Siłownie z samymi maszynami** da się odsiać tylko po tagach sprzętu. Nieotagowane miejsca zostają ukrytymi kandydatami, a nie Parkami.
- **Rekomendacja:** cotygodniowy import z ekstraktu Geofabrik przycięty do granic Polski. Parki z 5 miast przeglądamy ręcznie, wyłącznie na miejscu albo na ortofoto z Geoportalu, nigdy na zdjęciach Google. Nowe Parki dodaje się przez Konto, ze zdjęciem z miejsca, sprawdzeniem duplikatów i moderacją.
- **ODbL:** przy mapie musi być atrybucja „© OpenStreetMap”. Jeśli mieszamy OSM ze Zgłoszeniami, dane Parków (położenie, nazwa, sprzęt, status) trzeba udostępnić jako darmowy plik do pobrania na licencji ODbL, bez danych autorów. Opinie, oceny i zdjęcia zostają nasze. Oddawanie danych do OSM jest dozwolone, ale nieobowiązkowe.
- **Alternatywy** (calisthenics-parks.com, CaliBase, Google Places, dane miejskie) nie nadają się do importu przez licencje.
- **Uwaga do modelu Parku:** wyników geokodowania i POI z MapKit (Apple Maps) nie wolno zapisywać w bazie Parków (dodał research App Store).
