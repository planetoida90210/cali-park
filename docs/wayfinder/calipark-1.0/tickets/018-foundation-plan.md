---
title: Plan fundamentu: kolejność P0, Swift 6, CI
type: grilling
mode: HITL
status: open
assignee: 
blocked_by: [010, 022]
---

# Plan fundamentu: kolejność P0, Swift 6, CI

## Pytanie

W jakiej kolejności i w ilu sprintach robimy fundament przed backendem? Elementy:
- naprawy P0 z audytu,
- usunięcie mocków,
- privacy manifest,
- migracja do Swift 6,
- wspólne serwisy (`TrainingJournal`, `ProgressService`),
- CI (GitHub Actions czy Xcode Cloud) i lint.

Źródło: `docs/audit/README.md`.

## Kontekst z researchu (2026-11-03)

Z researchu: privacy manifest, `TARGETED_DEVICE_FAMILY = 1` i usunięcie mocków oraz uśpionego kodu Premium/Społeczności to warunki uploadu i review. Stabilne ID szczebli muszą wejść przed rewizją drabin. Faza 0 syncu nie wymaga płatnego konta.
