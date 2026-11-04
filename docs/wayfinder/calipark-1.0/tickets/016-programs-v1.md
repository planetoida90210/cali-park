---
title: Gotowe programy treningowe w 1.0
type: grilling
mode: HITL
status: closed
assignee: planetoida90210
blocked_by: [005]
---

# Gotowe programy treningowe w 1.0

## Pytanie

Które gotowe programy (2–4) wchodzą do 1.0, jak użytkownik je wybiera i jak łączą się z drabinami i planerem? Podstawą jest „Drabiny progresji i gotowe programy ze źródeł”. Programy testuje ekipa na TestFlight.

## Propozycja do potwierdzenia (2026-11-03)

Propozycja ze źródłami: [proposals/016-programs.md](../proposals/016-programs.md). Ticket zostaje otwarty do decyzji właściciela.

- Cztery programy: **Minimum** (Minimalist Routine z r/bodyweightfitness), **Fundamenty** („inspirowane RR” na dzisiejszych drabinach), **Pierwsze podciągnięcie** i **Skille** (handstand i L-sit).
- Rekomendacja na 1.0: Minimum, Fundamenty i Pierwsze podciągnięcie; Skille, jeśli zdążymy, i wycinamy je jako pierwsze.
- Model planu potrzebuje nowych opcjonalnych pól (odwołanie do drabiny, zakres powtórzeń, czas holdu, przerwa, pary i obwody, pochodzenie programu), więc stare pliki dalej się wczytają.

## Rozstrzygnięcie (2026-11-04)

**Wszystkie cztery programy wchodzą do 1.0: Minimum, Fundamenty, Pierwsze podciągnięcie i Skille.** Właściciel: „zdążymy też skille, nie odkładaj niczego”.

- Fundamenty w wersji „inspirowane RR” z uczciwym podpisem; drabina zawiasu biodrowego w 1.1.
- Wybór programu tworzy zwykły plan do edycji, który pamięta `programID` i wersję.
- Test poziomu w onboardingu podpowiada program, ale można wybrać inny.
- Nazwy zostają. Model planu dostaje opcjonalne pola z propozycji (odwołanie do drabiny, zakres powtórzeń, czas holdu, przerwa, pary i obwody, pochodzenie programu).
- Kolejność: najpierw rewizja drabin (015), bo Skille i Fundamenty stoją na nowych szczeblach.

## Wdrożenie (2026-11-04)

Zmergowane jako `3bbf358`. Otwarte pytania z raportu workera rozstrzyga koordynator: dni startowe Pn/Śr/Pt (Skille Wt/Czw), „1–2 powtórzenia w zapasie”; notka „przerwij przy bólu” czeka na tekst regulaminu.
