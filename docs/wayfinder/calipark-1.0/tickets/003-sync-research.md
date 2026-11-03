---
title: Sync treningów przez iCloud: technologia i migracja
type: research
mode: AFK
status: closed
assignee: planetoida90210
blocked_by: []
---

# Sync treningów przez iCloud: technologia i migracja

## Pytanie

Jak przenieść dane treningowe (dziennik, plany, placement, postęp) przez iCloud bez Konta CaliPark? Do porównania:
- CKSyncEngine,
- SwiftData z CloudKit,
- Core Data z CloudKit,
- iCloud Drive,
- key-value store.

Ticket obejmuje też: co już dziś przenosi backup iCloud, wymagania (iOS 18.4, płatne konto), migrację obecnych plików JSON, konflikty, tryb offline i użytkowników bez iCloud.

Wynik: [research/training-sync.md](../../research/training-sync.md) (zweryfikowany).

## Rozstrzygnięcie (2026-11-03)

Szczegóły, projekt rekordów i plan migracji są w [research/training-sync.md](../../research/training-sync.md). Fakty sprawdził niezależny weryfikator.

- **Już dziś** backup iCloud i Quick Start przenoszą pliki JSON na nowy telefon. Dane giną, gdy ktoś ustawi telefon jako nowy, ma wyłączony albo pełny backup, przeinstaluje apkę albo zalogował coś po ostatnim nocnym backupie.
- **Rekomendacja:** pliki JSON zostają lokalnym źródłem prawdy, a dochodzi warstwa CKSyncEngine na prywatnej bazie iCloud użytkownika: jedna strefa, rekord na wpis dziennika i na plan, stałe rekordy na placement i postęp. Konto nie jest potrzebne, a deweloper nic nie płaci.
- **Odrzucone:**
  - SwiftData i Core Data z CloudKit: przepisanie store'ów, „ostatni zapis wygrywa”, duplikaty.
  - iCloud Drive: konflikty całych plików.
  - Key-value store: 1 MB.
  - Sync przez Konto: łamie zasadę „trening bez Konta”.
- **Twarde ograniczenia:**
  - Każda opcja iCloud wymaga płatnego konta deweloperskiego.
  - Buildy TestFlight używają produkcyjnego schematu CloudKit, do którego można tylko dodawać. Projekt rekordów jest więc ostateczny przy pierwszym buildzie TestFlight z syncem; alternatywą jest test na buildach Ad Hoc.
  - Kontenera iCloud nie da się usunąć i należy do zespołu, który go utworzył, więc team i bundle ID trzeba ustalić wcześniej.
- **Faza 0, bez płatnego konta:** naprawa wipe'u (C-1), wersjonowane pliki, stabilne ID szczebli zamiast indeksów, przeniesienie do Application Support, eksport i import. **Faza 1:** sync.
