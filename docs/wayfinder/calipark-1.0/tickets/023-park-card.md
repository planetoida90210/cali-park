---
title: Karta parku
type: prototype
mode: HITL
status: closed
assignee: planetoida90210
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

## Rozstrzygnięcie (2026-11-04)

**Kolejność A: najpierw zdjęcia.** Właściciel: „najpierw zdjęcia, reszta git”. Pusty Park bez zdjęć pokazuje w tym miejscu przerywaną ramkę z „Dodaj zdjęcie”.

- Pełna karta jako arkusz (jak w Mapach Apple), mapa zostaje pod spodem.
- „Zweryfikowany” na limonkowo, „Ze Społeczności” i „Z OSM” na szaro.
- Zgłoszoną poprawkę widzi tylko jej autor, dopóki Moderator jej nie zatwierdzi.
- Opinie wchodzą od razu (filtr słów, zgłaszanie, blokowanie), zdjęcia dopiero po akceptacji Moderatora.
- Średnia ocena od 3 opinii.
- Pogoda schowana w całości do WeatherKit, bez danych przykładowych i innego dostawcy.
- Park z OSM bez znanego sprzętu: „Street workout · …”. „Nawiguj” tylko do Map Apple w v1. „Zgłoś treść” także przy zdjęciach ekipy; teksty zgłoszeń razem z regulaminem.
