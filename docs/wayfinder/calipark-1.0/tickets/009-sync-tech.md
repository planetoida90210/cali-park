---
title: Technologia syncu treningów
type: grilling
mode: HITL
status: open
assignee: 
blocked_by: [003]
---

# Technologia syncu treningów

## Pytanie

Którą technologią iCloud synchronizujemy dane treningowe (np. CKSyncEngine albo SwiftData z CloudKit)? Właściciel zostawia wybór techniczny Claude'owi. Warunki: musi przejść App Review i być możliwie proste w utrzymaniu. Claude rekomenduje na podstawie „Sync treningów przez iCloud: technologia i migracja”, a właściciel potwierdza.

## Kontekst z researchu (2026-11-03)

Research rekomenduje CKSyncEngine na prywatnej bazie iCloud, z plikami JSON jako źródłem prawdy. Do potwierdzenia jest jeszcze, czy pierwszy test syncu robimy na TestFlight (schemat zamrożony) czy na buildach Ad Hoc (schemat da się zmieniać).
