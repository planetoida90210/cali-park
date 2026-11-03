---
title: Wybór backendu
type: grilling
mode: HITL
status: closed
assignee: planetoida90210
blocked_by: [002, 006]
---

# Wybór backendu

## Pytanie

Na którym backendzie stawiamy Parki i Społeczność w 1.0? Kryteria są w „Zakres CaliPark 1.0”: UE, ok. 100 zł/mies. do ~10k aktywnych użytkowników, bez własnego serwera, szybki i bezpieczny z kontrolą dostępu na poziomie wierszy. Podstawą jest porównanie z „Backend dla Parków i Społeczności: opcje i koszty” i wymagania z „Wymagania App Store i RODO dla 1.0”.

## Kontekst z researchu (2026-11-03)

Ranking z researchu: Supabase Cloud Pro (Frankfurt), potem własne API na Hetznerze, potem PocketBase. Rozstrzygnąć trzeba: czy firma spoza UE z serwerami w UE wystarcza, kto buduje limit zapisów i uzasadnienia usunięć (DSA), oraz politykę limitu wydatków przed ~45k MAU.

## Rozstrzygnięcie (2026-11-03)

**Supabase Cloud, plan Pro, region Frankfurt (`eu-central-1`).** Właściciel zdał się na rekomendację („jeśli uważasz, że Supabase będzie serio pro i 8 GB starczy na foty”).

- **Pojemność:** 8 GB to dysk bazy, czyli dane tekstowe: Parki, opinie, Konta. Zdjęcia leżą w Supabase Storage, gdzie plan ma 100 GB w cenie, a potem ok. 0,02 USD/GB. Przy ok. 340 KB na zdjęcie (dwa rozmiary) to ok. 300 tys. zdjęć.
- **Koszt:** 25 USD/mies. do ok. 45k aktywnych użytkowników. Plan Free (pauza po 7 dniach bezczynności, bez backupów) służy tylko do developmentu. Pro włączamy, gdy prawdziwi testerzy zaczną publikować.
- **Warunki, które wchodzą do specu:**
  - RLS na każdej tabeli i Security Advisor (`supabase db advisors`) w CI.
  - Limity Zgłoszeń, opinii i zdjęć na Konto budujemy sami (trigger albo `db_pre_request`).
  - Zdjęcia czekające na moderację są poza publicznym bucketem do czasu akceptacji. GPS i EXIF usuwamy przed wysyłką.
  - Każde usunięcie treści ma zapisane uzasadnienie (DSA).
  - Usunięcie Konta kasuje opinie i zdjęcia oraz unieważnia token Sign in with Apple. Użytkowników kluczujemy identyfikatorem Apple.
  - Limit wydatków: domyślnie włączony. Przed ok. 45k MAU wyłączamy go i ustawiamy alerty, bo inaczej po wyczerpaniu transferu przestaną się ładować zdjęcia.
  - Umowę powierzenia (DPA) z Supabase podpisujemy przed zapisaniem danych testerów. Kontrahent jest spoza UE (Supabase Pte. Ltd., SCC), dane leżą w UE.
- **Odrzucone:**
  - własne API w Ruście na Hetznerze: tygodnie budowy i serwer do utrzymania, bez realnego zysku bezpieczeństwa,
  - PocketBase: wersja przed 1.0, brak SDK w Swifcie, brak natywnego Sign in with Apple,
  - Firebase: logowanie przetwarzane w USA, brak twardego limitu wydatków,
  - publiczna baza CloudKit: brak walidacji zapisów na serwerze.
- **Wyjście awaryjne:** pod spodem jest zwykły Postgres, więc później da się przejść na self-host albo własne API.

Szczegóły: [research/backend-options.md](../../research/backend-options.md).
