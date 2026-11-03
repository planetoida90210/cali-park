---
title: Rewizja drabin progresji
type: grilling
mode: HITL
status: closed
assignee: planetoida90210
blocked_by: [005]
---

# Rewizja drabin progresji

## Pytanie

Które szczeble i kryteria awansu w `docs/PROGRESSIONS.md` zmieniamy, zwłaszcza na ścieżce podciągania? Podstawą jest „Drabiny progresji i gotowe programy ze źródeł”. Każda zmiana szczebla dotyka zapisanych postępów, bo indeksy szczebli są zapisywane (audyt A-6, C-5), więc rozstrzygnięcie musi mówić, jak migrujemy dane.

## Propozycja do potwierdzenia (2026-11-03)

Propozycja ze źródłami: [proposals/015-ladders.md](../proposals/015-ladders.md). Ticket zostaje otwarty do decyzji właściciela.

- Nic nie wypada: 11 nowych szczebli, jeden przeniesiony, poprawione etykiety i sprzęt. Największe zmiany: handstand (pike i elevated pike push-upy, negatywy HSPU), L-sit w kolejności GMB, planche (frog stand, half-lay), flaga (advanced tuck, pionowy słup), nogi (split squat i przysiad bułgarski z RR).
- Każde kryterium dostaje etykietę źródła: RR, OG2, tabela OG2 albo „konwencja CaliPark”.
- Ruchy jednostronne: „na stronę” tylko w opisie (flaga `isUnilateral`), format logu bez zmian.
- Dane: wymaga stabilnych ID szczebli z Fazy 0b (worker T3). `PlacementCalibration` przechodzi na ID ćwiczeń w tym samym kroku. Nowe szczeble poniżej zaliczonego liczą się jako zaliczone, więc obecni użytkownicy dostaną jednorazowy skok XP.
- Nowe znalezisko: silnik ignoruje `isParallelTrack`, więc guma wychodzi jako aktualny szczebel (audyt A-3).

## Postęp (2026-11-03)

Stabilne ID szczebli są już na `main` (`d4e1011`): placement i rekord celebracji zapisują ID ćwiczenia, a stare pliki migrują przez zamrożoną kolejność `LadderOrderV1`. Wstawianie i przestawianie szczebli z propozycji nie przesunie już zapisanych danych.

## Rozstrzygnięcie (2026-11-04)

**Rewizja z [propozycji](../proposals/015-ladders.md) w całości.** Właściciel: „ok”.

- 11 nowych szczebli, jeden przeniesiony, nic nie wypada.
- Statyki 3×20 s z etykietą „wyprowadzone z tabeli OG2”; pełny L-sit 3×20 s.
- Ruchy jednostronne: „na stronę” tylko w opisie (`isUnilateral`), format logu bez zmian.
- Szczeble bez źródła zostają z etykietą „konwencja CaliPark”. Guma zostaje torem równoległym, a silnik przestaje ją pokazywać jako obowiązkowy krok (A-3).
- Nowe klucze sprzętu jak w modelu Parku (ticket 012).
- Migracja danych: stabilne ID szczebli są już na `main` (`d4e1011`), więc wstawianie szczebli nie przesuwa zapisów. Obecni użytkownicy dostaną jednorazowy skok XP za nowe niższe szczeble.
