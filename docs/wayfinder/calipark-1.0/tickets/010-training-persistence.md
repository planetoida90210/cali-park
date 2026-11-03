---
title: Warstwa danych treningów: naprawione pliki JSON czy SwiftData
type: grilling
mode: HITL
status: closed
assignee: planetoida90210
blocked_by: [009]
---

# Warstwa danych treningów: naprawione pliki JSON czy SwiftData

## Pytanie

Czy dane treningowe zostają w plikach JSON po naprawie z audytu (wspólny `JSONFileStore`, wersjonowanie, bez cichego wipe'u), czy przechodzą na SwiftData albo inny magazyn wymuszony przez wybraną technologię syncu? Od tego zależy pierwszy sprint fundamentu. Audyt: P0 #1, P1 „dane długoterminowo”.

## Kontekst z researchu (2026-11-03)

Research proponuje Fazę 0 bez płatnego konta: naprawa wipe'u, wersjonowane pliki, stabilne ID szczebli, Application Support, eksport i import. Pliki JSON zostają źródłem prawdy pod CKSyncEngine.

## Rozstrzygnięcie (2026-11-03)

**Dane treningowe zostają w plikach JSON, utwardzonych w Fazie 0.** Właściciel zostawił wybór techniczny Claude'owi.

- **Faza 0, bez płatnego konta:**
  1. Jeden wspólny magazyn plików dla 4 store'ów. Nieczytelny albo uszkodzony plik nigdy nie jest nadpisywany pustym stanem: zostaje odłożony na bok, a błąd jest logowany.
  2. Wersjonowana koperta formatu, z odczytem obecnego formatu, żeby nikt nie stracił danych.
  3. Testy na prawdziwym formacie z dysku.
  4. Stabilne ID szczebli zamiast indeksów, z migracją zapisanych danych. To warunek przed „Rewizja drabin progresji”.
- **Później:**
  - przeniesienie plików do Application Support (porządek, bo backup iCloud i tak je przenosi),
  - eksport i import, czyli decyzja produktowa w Profilu (mgła na mapie).
- **Odrzucone:** SwiftData, czyli przepisanie store'ów bez zysku dla syncu przez CKSyncEngine.

Audyt: P0 #1 i P1 „dane długoterminowo” w [docs/audit/README.md](../../../audit/README.md).
