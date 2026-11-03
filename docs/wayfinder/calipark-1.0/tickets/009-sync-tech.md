---
title: Technologia syncu treningów
type: grilling
mode: HITL
status: closed
assignee: planetoida90210
blocked_by: [003]
---

# Technologia syncu treningów

## Pytanie

Którą technologią iCloud synchronizujemy dane treningowe (np. CKSyncEngine albo SwiftData z CloudKit)? Właściciel zostawia wybór techniczny Claude'owi. Warunki: musi przejść App Review i być możliwie proste w utrzymaniu. Claude rekomenduje na podstawie „Sync treningów przez iCloud: technologia i migracja”, a właściciel potwierdza.

## Kontekst z researchu (2026-11-03)

Research rekomenduje CKSyncEngine na prywatnej bazie iCloud, z plikami JSON jako źródłem prawdy. Do potwierdzenia jest jeszcze, czy pierwszy test syncu robimy na TestFlight (schemat zamrożony) czy na buildach Ad Hoc (schemat da się zmieniać).

## Rozstrzygnięcie (2026-11-03)

**CKSyncEngine na prywatnej bazie iCloud użytkownika. Pliki JSON zostają lokalnym źródłem prawdy.** Właściciel zostawił wybór techniczny Claude'owi z warunkiem, że ma przejść App Review.

- Sync nie wymaga Konta CaliPark i nic nie kosztuje dewelopera. Jeśli iCloud jest wyłączone, apka działa jak dziś.
- Konfiguracja: jedna strefa, rekord na wpis dziennika i na plan, stałe rekordy na placement i postęp, zasady łączenia per typ. Projekt rekordów jest w [research/training-sync.md](../../research/training-sync.md).
- SwiftData i Core Data z CloudKit odrzucone: przepisanie store'ów, „ostatni zapis wygrywa”, duplikaty.
- Gdzie robimy pierwszy test syncu, TestFlight (schemat zamrożony) czy buildy Ad Hoc (schemat zmienny), rozstrzyga „Kolejność wydań: TestFlight z samym treningiem, potem Społeczność”.
- Sync wymaga płatnego konta deweloperskiego: „Zakup Apple Developer Program”.
