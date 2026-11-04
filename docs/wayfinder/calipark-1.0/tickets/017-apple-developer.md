---
title: Zakup Apple Developer Program
type: task
mode: HITL
status: open
assignee: 
blocked_by: []
---

# Zakup Apple Developer Program

## Pytanie

Właściciel zakłada płatne konto Apple Developer Program. Bez niego nie da się testować Sign in with Apple, CloudKit (sync i ewentualny backend), WeatherKit ani TestFlight.

Lista dla właściciela (szczegóły i koszt zweryfikuje „Wymagania App Store i RODO dla 1.0”):
1. Zdecyduj: osoba fizyczna (w sklepie widać imię i nazwisko jako sprzedawcę) czy firma (wymaga numeru D-U-N-S).
2. Zapisz się na developer.apple.com/programs i opłać roczną składkę.
3. Sprawdź, czy bundle ID `com.michalbryk.cali-park` i team zostają, czy zmieniamy.

Rozstrzygnięcie zapisuje: typ konta, Team ID, decyzję o bundle ID.

## Kontekst z researchu (2026-11-03)

Kontenera iCloud nie da się usunąć i należy do zespołu, który go utworzył. Identyfikatory Sign in with Apple są przypięte do zespołu. Typ konta, team i bundle ID trzeba więc ustalić przed utworzeniem kontenera i przed pierwszym logowaniem testerów. Osoba fizyczna: w sklepie widać imię i nazwisko, D-U-N-S niepotrzebny, 99 USD/rok.

## Notatka (2026-11-04)

Właściciel kupi konto później, teraz nie ma budżetu. Do tego czasu robimy wszystko, co nie wymaga płatnego konta: trening, fundament, drabiny, programy, przypomnienia lokalne. Bundle ID i team ustalamy przy zakupie, zanim powstanie kontener iCloud.

Przy zmianie bundle ID trzeba też zmienić identyfikator zadania w tle `com.michalbryk.cali-park.reminders-refresh` (`cali-park/Info.plist`, `AppRefreshScheduler.taskIdentifier`).

Aktualizacja (2026-11-04): identyfikator zadania w tle wynika teraz z bundle ID (`$(PRODUCT_BUNDLE_IDENTIFIER).reminders-refresh`), więc zmienia się sam. Kroki na dzień zakupu: [docs/release/checklist.md](../../../release/checklist.md).
