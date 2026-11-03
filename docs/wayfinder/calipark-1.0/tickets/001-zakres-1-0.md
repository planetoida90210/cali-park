---
title: Zakres CaliPark 1.0: decyzje z chartingu
type: grilling
mode: HITL
status: closed
assignee: planetoida90210
blocked_by: []
---

# Zakres CaliPark 1.0: decyzje z chartingu

## Pytanie

Jaki zakres i kształt ma CaliPark 1.0, z którym wychodzimy do App Store?

## Rozstrzygnięcie (2026-11-03)

Ustalone z właścicielem w dwóch rundach grillowania przy zakładaniu mapy.

- **Cel mapy:** zdecydowany spec 1.0, który potem wykonujemy sprintami.
- **Rynek i języki:** start w Polsce, UI po polsku. Angielski i ukraiński dochodzą po starcie. String Catalog jest od pierwszego dnia.
- **Park:** publiczne miejsce na zewnątrz z co najmniej jednym drążkiem albo poręczami. Siłownie plenerowe z samymi maszynami się nie liczą. Definicja jest w `GLOSSARY.md`.
- **Konta:** wyłącznie Sign in with Apple. Trening jest zawsze darmowy i nie wymaga Konta. Konto jest potrzebne tylko do publikowania w Społeczności.
- **Tożsamość:** publiczny jest tylko Pseudonim. Imię i mail z Apple nigdy nie są publiczne. Bezpieczeństwo danych ma priorytet.
- **Społeczność v1:** mapa, karta parku, sprzęt, opinie z ocenami i zdjęcia (bez komentarzy i lajków), a do tego zgłaszanie treści, blokowanie użytkowników i moderacja.
- **Zgłoszenia parków:** darmowe dla zalogowanych, bo celem jest zbudowanie społeczności. Formularz ma być łatwy, ale pozwalać dodać dużo informacji i zdjęć, a nazwy muszą wychodzić sensowne. Właściciel sam objeżdża dobre miejscówki i robi zdjęcia pro.
- **Moderacja:** właściciel i ekipa. Parki i zdjęcia są widoczne dopiero po akceptacji. Opinie są widoczne od razu, z filtrem wulgaryzmów i automatycznym ukryciem po zgłoszeniach. Forma panelu: ticket „Panel moderacji: w apce, strona www czy oba”.
- **Dane treningowe:** muszą przechodzić na nowy telefon. Idą przez iCloud, bez Konta. Technologia: ticket „Technologia syncu treningów”.
- **Backend:**
  - dane w UE (RODO),
  - koszt do ok. 100 zł/mies. przy ~10k aktywnych użytkowników,
  - bez własnego serwera do utrzymania,
  - musi być szybki i bezpieczny, z kontrolą dostępu na poziomie wierszy (RLS albo odpowiednik).
- **Pieniądze:** v1 jest darmowe, a monetyzację ustalamy po starcie.
- **Platforma:** tylko iPhone, tylko pion. App Store nie wymaga iPada.
- **Mapa:** na start import parków z Polski, zgłoszenia z całego świata. Mapa ma być stylowa.
- **Pogoda:** prawdziwa, z WeatherKit.
- **Treningi:** obecne drabiny (szczególnie ścieżka podciągania) i plany są według właściciela „z głowy”. Do zrobienia rewizja na źródłach i gotowe programy w v1.
- **Kolejność:** najpierw fundament (P0 z audytu, Swift 6, CI), potem backend i Parki.
- **Termin:** App Store przed kwietniem 2027. Zimą TestFlight z ekipą (u właściciela sezon trwa cały rok).
- **Apple Developer Program:** właściciel jeszcze go nie ma i kupi przed TestFlight. Ticket „Zakup Apple Developer Program”.
