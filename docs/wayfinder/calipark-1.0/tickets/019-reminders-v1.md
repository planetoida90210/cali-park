---
title: Przypomnienia o treningu w 1.0
type: grilling
mode: HITL
status: closed
assignee: planetoida90210
blocked_by: []
---

# Przypomnienia o treningu w 1.0

## Pytanie

Czy lokalne przypomnienia o zaplanowanym treningu wchodzą do 1.0? Warstwa planowania przypomnień istnieje, ale nie ma UI (Sprint 2 w `docs/SPRINTS-profil-powiadomienia.md`), a audyt wskazał jej braki (B-7, B-6).

## Rozstrzygnięcie (2026-11-04)

**Tak, lokalne przypomnienia wchodzą do 1.0.** Właściciel potwierdził rekomendację.

- Przełącznik i godzina w planie. O zgodę na powiadomienia pytamy dopiero przy pierwszym włączeniu.
- Bez serwera. Edytor planu już nie gubi `reminderTime` (B-6, naprawione `5012b44`); zostaje B-7 i orkiestracja w `WorkoutPlanService`.

## Doprecyzowanie (2026-11-04)

Wdrożone w `bfb3796`. Właściciel: „bez skipowania na później”, więc przypomnienie **nie dzwoni w dzień, w którym plan jest już zrobiony**. Technicznie: zamiast powtarzanych triggerów iOS planujemy przypomnienia na konkretne daty (limit 64, najbliższe pierwsze) i dokładamy je przy starcie, powrocie do apki i w tle (`BGAppRefreshTask`). Domyślna godzina 18:00 i „Dziś · Zrobione / Następny: …” zostają.
