---
title: Plan fundamentu: kolejność P0, Swift 6, CI
type: grilling
mode: HITL
status: closed
assignee: planetoida90210
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

## Propozycja (2026-11-04)

[proposals/018-foundation-plan.md](../proposals/018-foundation-plan.md). Kolejność techniczna jest już ustalona przez koordynatora (właściciel oddał wybory techniczne): F0 CI na GitHub Actions, F1 apka bez mocków, F2 jeden dziennik (`TrainingJournal`, `ProgressService`, `RewardCenter`), F3 Swift 6, F4 dane w Application Support z eksportem i importem, F5 String Catalog i dostępność. Do właściciela: zakładka Parków w TestFlighcie, nazwa „Parki” i eksport/import. Kroki F1 zależą od ticketów 024–026.

## Rozstrzygnięcie (2026-11-04)

**Plan F0–F5 z [propozycji](../proposals/018-foundation-plan.md)**, z odpowiedziami właściciela:

- **P1, zakładka Parków w TestFlighcie: „nie chowasz niczego”.** Zakładka zostaje i pokazuje prawdziwą mapę (wariant A) z Parkami z OSM wbudowanymi w apkę, tylko do odczytu, z kartą Parku (023). Opinie, zdjęcia i Zgłoszenia dochodzą ze Społecznością, bo wymagają Konta i backendu.
- **P2: nazwa zakładki zostaje „Siłownie”.** Właściciel: „jak jest teraz, jest git”. W kodzie i dokumentach dalej mówimy „Park”.
- **P3: eksport i import treningów do pliku wchodzą do 1.0**, w Profilu.
- Właściciel: „bez skipowania na później”. Nic z F0–F5 nie przechodzi na po 1.0.
