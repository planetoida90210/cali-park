---
title: Model Parku i sprzętu
type: grilling
mode: HITL
status: open
assignee: 
blocked_by: [004]
---

# Model Parku i sprzętu

## Pytanie

Jakie informacje opisują Park? Do ustalenia:
- typy sprzętu (drążek, poręcze, drabinki, kółka…), liczba i wysokości,
- nawierzchnia, oświetlenie, cień, woda, WC, godziny dostępu,
- co jest wymagane, a co opcjonalne,
- jak powstaje nazwa Parku, żeby użytkownicy nie wpisywali byle czego (np. podpowiedź z lokalizacji, poprawka Moderatora).

Taksonomię sprzętu warto zgrać z tagami OSM z „Parki z OpenStreetMap w Polsce i licencja ODbL”.

## Kontekst z researchu (2026-11-03)

OSM daje sprzęt tylko dla ok. 8% miejsc i nazwę dla ok. 6%, więc model musi dobrze znosić braki. Wyników geokodowania i POI z MapKit nie wolno zapisywać w bazie Parków, więc podpowiedź nazwy nie może pochodzić z zapisanego geokodowania Apple. Klucz sprzętu „Drabinki” jest dwuznaczny: flaga potrzebuje pionowego słupa.

## Propozycja do potwierdzenia (2026-11-03)

Propozycja: [proposals/012-park-model.md](../proposals/012-park-model.md). Ticket zostaje otwarty do decyzji właściciela.

- **Trzy warstwy danych:** fakty o Parku (udostępniane jako otwarty plik na ODbL), treści Społeczności (opinie, oceny, zdjęcia) i prywatne dane moderacji.
- **Wymagane są tylko:** położenie, dowód, że to Park, źródło i status. Reszta jest opcjonalna.
- **Sprzęt:** klucze 1:1 z wartościami OSM `fitness_station`. Flaga dostaje `fitness_pole`, a dwuznaczne „Drabinki” dzielą się na dwa klucze. Siłownie z samymi maszynami odpadają po jawnej liście wartości.
- **Nazwa:** nazwa z OSM, potem nazwa zatwierdzona przez Moderatora, potem nazwa generowana z danych OSM (np. „Street workout · Park Skaryszewski”). Nic z MapKit nie trafia do bazy.
- **Moderacja:** stany `candidate/draft/pending/published/rejected/removed` i zapis decyzji z polami z art. 17 DSA. Weryfikacja (`osm/community/verified`) to osobna oś, wiąże się z ticketem 014.
- Tabela błędów obecnych modeli w `cali-park/Features/Parks/Models/`.
