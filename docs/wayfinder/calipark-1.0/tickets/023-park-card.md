---
title: Karta parku
type: prototype
mode: HITL
status: open
assignee: 
blocked_by: []
---

# Karta parku

## Pytanie

Co dokładnie pokazuje karta Parku i w jakiej kolejności? Kandydaci:
- zdjęcia,
- sprzęt (klucze z modelu Parku, liczba i wysokość drążków),
- status weryfikacji („Zweryfikowany”, „Ze Społeczności”, „Z OSM”),
- opinie i oceny,
- pogoda (WeatherKit, po zakupie konta),
- nawigacja do Parku i odległość,
- „Zgłoś poprawkę” i „Zgłoś treść” (wymóg DSA i App Store).

Prototyp klikalny w SwiftUI, w stylu wariantu A mapy: kompaktowa karta na dole mapy i pełna karta po rozwinięciu.

## Kontekst (2026-11-04)

Wyjęte z mgły mapy, bo model Parku (012), weryfikacja (014) i wygląd mapy (011) są już rozstrzygnięte. Pola Parku: [proposals/012-park-model.md](../proposals/012-park-model.md). Prototyp mapy: [prototypes/map-look](../prototypes/map-look/README.md). Prototyp zgłoszenia (013) powstaje równolegle, a karta Parku pojawia się w nim przy ostrzeżeniu o duplikacie.
