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

## Prototyp (2026-11-04)

Klikalna karta Parku w SwiftUI na mapie A „Wyciszona”, ze zmyślonymi danymi. Opis, zrzuty, uruchomienie i pytania: [prototypes/park-card/README.md](../prototypes/park-card/README.md). Kod jest tylko w buildzie Debug (`cali-park/Prototypes/ParkCard/`, argument `-PrototypeParkCard`). Ticket zostaje otwarty do wyboru właściciela.

- **Kompaktowa karta:** nazwa, okolica, odległość, etykieta weryfikacji, ocena, ikony sprzętu, „Nawiguj” i „Szczegóły”.
- **Pełna karta:** ten sam dolny arkusz rozwinięty do góry, jak w Apple Maps. Sekcje: zdjęcia, sprzęt, skąd te dane, pogoda (przykładowa), opinie, szczegóły, stopka z „Zgłoś poprawkę” i atrybucją ODbL. „Zgłoś treść” jest przy opiniach i zdjęciach.
- **Stany:** Park zweryfikowany z pełnymi danymi, Park ze Społeczności, Park z OSM bez zdjęć, sprzętu i opinii, Park z poprawką w toku.
- **Dwie kolejności:** A · Zdjęcia najpierw i B · Sprzęt najpierw.
- **Rekomendacja workera:** B, z paskiem zdjęć na górze, gdy Park ma zdjęcia. Pełna karta jako arkusz, nie nowy ekran.
