---
title: Backend dla Parków i Społeczności: opcje i koszty
type: research
mode: AFK
status: closed
assignee: planetoida90210
blocked_by: []
---

# Backend dla Parków i Społeczności: opcje i koszty

## Pytanie

Jakie są realne opcje backendu dla Parków i Społeczności przy decyzjach z „Zakres CaliPark 1.0”? Porównanie obejmuje:
- Sign in with Apple,
- zapytania geo „najbliższe Parki”,
- zdjęcia i koszt transferu,
- moderację,
- usuwanie Konta,
- UE/RODO,
- SDK w Swifcie,
- model bezpieczeństwa (RLS lub odpowiednik),
- obciążenie utrzymaniem,
- koszt przy 100 / 1k / 10k / 50k aktywnych użytkowników.

W porównaniu są Supabase (chmura i self-host), Firebase, publiczna baza CloudKit, PocketBase i własne API (np. Rust) z Postgres/PostGIS. Ticket odpowiada też uczciwie, czy Rust robi backend „bezpieczniejszym”.

Wynik: [research/backend-options.md](../../research/backend-options.md) (zweryfikowany).

## Rozstrzygnięcie (2026-11-03)

Szczegóły i tabela kosztów są w [research/backend-options.md](../../research/backend-options.md). Fakty sprawdził niezależny weryfikator.

- **Ranking:** Supabase Cloud Pro (Frankfurt), potem własne API na Hetznerze (Postgres/PostGIS + Hetzner Object Storage), potem PocketBase. Firebase odpada, bo logowanie przetwarza tylko w USA i nie ma twardego limitu wydatków. Publiczna baza CloudKit odpada, bo na serwerze nie da się walidować zapisów ani ich limitować.
- **Supabase Cloud Pro:** stałe 25 USD/mies. do ok. 45k aktywnych użytkowników. Limit wydatków niczego nie dolicza, tylko blokuje: po wyczerpaniu transferu zdjęcia przestają się ładować do końca miesiąca. Około 45k MAU trzeba go wyłączyć i ustawić alerty. Środowisko testowe kosztuje ok. 10 USD/mies. więcej.
- **Własne API na Hetznerze:** ok. 15–31 €/mies. na każdym poziomie, a wszystkie firmy są z UE. Koszt to kilka tygodni budowy i stałe utrzymanie serwera.
- **Self-host Supabase** nic nie oszczędza: ok. 24 €/mies. i 11 kontenerów do utrzymania.
- **Rust nie robi backendu bezpieczniejszym** w sensie, który tu się liczy. Ryzyka to autoryzacja, walidacja i nadużycia, czyli błędy logiki, przed którymi język nie chroni.
- **Przy każdym backendzie trzeba zbudować samemu:** limit zapisów na użytkownika (Supabase go nie ma), uzasadnienia usunięć wymagane przez DSA, kasowanie opinii i zdjęć przy usuwaniu Konta. Użytkowników kluczujemy identyfikatorem Apple, który jest przypięty do zespołu deweloperskiego.
- **Otwarte dla właściciela:** czy firma spoza UE z serwerami w UE (Supabase) jest do przyjęcia, czy wymagamy firmy z UE.
