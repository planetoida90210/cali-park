---
title: Kolejność wydań: TestFlight z samym treningiem, potem Społeczność
type: grilling
mode: HITL
status: closed
assignee: planetoida90210
blocked_by: [006]
---

# Kolejność wydań: TestFlight z samym treningiem, potem Społeczność

## Pytanie

Czy najpierw wypuszczamy zewnętrzny TestFlight tylko z treningiem (bez Kont i Społeczności), a Społeczność dochodzi w osobnym buildzie przez pełne review? Research odradza włączanie funkcji flagą z serwera po akceptacji. To ustawia kolejność sprintów fundamentu i backendu oraz moment zamrożenia schematu CloudKit.

Kontekst: „Wymagania App Store i RODO dla 1.0”, „Sync treningów przez iCloud: technologia i migracja”.

## Rozstrzygnięcie (2026-11-04)

**Tak: najpierw zewnętrzny TestFlight z samym treningiem, potem Społeczność w osobnym buildzie przez pełne review.** Właściciel: „ta jest git”.

- TestFlight #1: sam trening, bez Kont, Społeczności i syncu. Mocki Parków, Społeczności i Premium nie mogą być widoczne w tym buildzie (wytyczne 2.1, 2.5.19).
- Sync iCloud testujemy najpierw na buildach Ad Hoc na kilku telefonach ekipy (schemat Development da się zmieniać), a do TestFlight trafia, gdy projekt rekordów jest pewny.
- Społeczność dochodzi w buildzie, który przechodzi review ze wszystkimi wymaganiami 1.2. Nigdy nie włączamy funkcji flagą z serwera po akceptacji.
- Wszystko to wymaga płatnego konta deweloperskiego (ticket 017), które właściciel kupi później.
