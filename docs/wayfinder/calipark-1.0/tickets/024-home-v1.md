---
title: Home w 1.0
type: grilling
mode: HITL
status: closed
assignee: planetoida90210
blocked_by: []
---

# Home w 1.0

## Pytanie

Co jest na ekranie Start w TestFlighcie z samym treningiem i w 1.0?

## Stan dziś (2026-11-04)

- Hero: plan na dziś, zrobione dziś, dzień odpoczynku, pierwszy start, podpowiedź progresji, pierścień tygodnia.
- Moduły do przestawiania i ukrywania: „Ostatni trening”, „Następny trening”, „Pogoda i siłownia” (mock), „Seria dni”, „Osiągnięcia”. Leaderboard i feed są w kodzie, ale niedostępne (v1.1).
- Cel tygodniowy jest wpisany na sztywno, a powitanie zawsze mówi „Michał” (audyt E-2, G-2).
- Przestawianie modułów przeciąganiem nie ma alternatywy dla VoiceOver (E-12).

## Propozycja koordynatora

- **Stały układ zamiast modułów do przestawiania:** hero, następny trening, seria dni i cel tygodniowy, postęp na ścieżkach, ostatni trening. Mniej kodu, brak problemu z dostępnością, a w 1.0 i tak nie ma czego dokładać.
- **Cel tygodniowy:** liczba dni treningowych w tygodniu, domyślnie z wybranego programu (016), do zmiany w Profilu.
- **Bez imienia** w powitaniu, bo nie ma Konta. Pseudonim pojawi się razem ze Społecznością.
- **Pogoda i najbliższy Park** wracają ze Społecznością i po zakupie konta (WeatherKit wymaga płatnego konta).

## Rozstrzygnięcie (2026-11-04)

**Moduły zostają do przestawiania.** Właściciel: „każdy może dowolnie zarządzać swoim dashboardem, o to w tym chodzi”.

- Przestawianie dostaje alternatywę dla VoiceOver (akcje „Przesuń wyżej / niżej”, E-12).
- Znika „Michał” i każdy mock. Moduł „Pogoda i siłownia” pokazuje najbliższy Park z danych OSM; pogoda z WeatherKit dochodzi po zakupie konta (017).
- Cel tygodniowy: osobny ticket [027](027-weekly-goal.md), bo ma być „elastyczniejszy i dobrze logicznie przekminiony”.

## Dopisek (2026-11-04)

Moduł Parków zostaje „Najbliższy Park”; Home dalej konfigurowalny (Q27, właściciel: „home jest konfigurowalne, to się nie zmienia”).
