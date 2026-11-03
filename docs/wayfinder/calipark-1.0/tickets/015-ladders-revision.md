---
title: Rewizja drabin progresji
type: grilling
mode: HITL
status: open
assignee: 
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
