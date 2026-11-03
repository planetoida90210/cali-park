---
title: Formularz zgłoszenia parku
type: prototype
mode: HITL
status: closed
assignee: planetoida90210
blocked_by: [012]
---

# Formularz zgłoszenia parku

## Pytanie

Jak wygląda Zgłoszenie Parku, żeby było łatwe, a jednocześnie pozwalało dodać dużo informacji i zdjęć? Do ustalenia:
- kroki formularza,
- minimum wymaganych pól,
- dodawanie zdjęć,
- wykrywanie duplikatów („ten Park już jest obok”),
- jak użytkownik widzi status swojego Zgłoszenia.

Prototyp klikalny w SwiftUI.

## Kontekst z researchu (2026-11-03)

Research OSM rekomenduje dla nowych Parków: Konto, zdjęcie zrobione na miejscu w apce, sprawdzenie duplikatów i moderację. GPS i EXIF ze zdjęć usuwamy przed wysłaniem.

## Prototyp (2026-11-04)

Klikalny przepływ w SwiftUI na mapie A „Wyciszona”, ze zmyślonymi danymi. Opis, zrzuty, uruchomienie i pytania: [prototypes/park-submission/README.md](../prototypes/park-submission/README.md). Kod jest tylko w buildzie Debug (`cali-park/Prototypes/ParkSubmission/`, argument `-PrototypeParkSubmission`). Ticket zostaje otwarty do wyboru właściciela.

- **Przepływ:** „Dodaj Park” na mapie, pinezka przy sprzęcie, ostrzeżenie „Ten Park już jest obok” (50 m), sprzęt, zdjęcie z aparatu, nazwa, szczegóły, podsumowanie, „Moje zgłoszenia”.
- **Wymagane tylko:** pinezka, drążek albo poręcze plus zdjęcie, źródło (ustawiane samo). Reszta opcjonalna, bez wolnego opisu.
- **Dwa układy formularza:** A · Kroki (jedno pytanie na ekran) i B · Jeden arkusz (wszystko na jednym ekranie).
- **Rekomendacja workera:** A · Kroki, z listą wymaganych rzeczy z B.

## Rozstrzygnięcie (2026-11-04)

**Układ B · Jeden arkusz.** Właściciel: „b chyba lepsze”.

- Zdjęcia z aparatu **i z galerii** („z telefonu, w sensie z galerii”). Jeśli zdjęcie z galerii ma lokalizację, telefon sprawdza, czy zrobiono je do ok. 200 m od pinezki, a Moderator dostaje tylko flagę; zdjęcie bez lokalizacji dostaje flagę „brak lokalizacji”. GPS i EXIF usuwamy przed wysłaniem.
- Same poręcze (też do dipów) robią Park: „można tam zrobić jakościowy trening i będą ciekawe miejsca”.
- Reszta jak w rekomendacji: o Konto pytamy przy „Wyślij”, limit 5 Zgłoszeń dziennie, duplikaty w promieniu 50 m wobec Parków opublikowanych i czekających, bez godzin otwarcia, zgoda ODbL jednym zdaniem w podsumowaniu plus regulamin, status w „Moje zgłoszenia” w Profilu z kropką na ikonie (push później).
