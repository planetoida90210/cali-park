---
title: Cel tygodniowy
type: grilling
mode: HITL
status: open
assignee: 
blocked_by: []
---

# Cel tygodniowy

## Pytanie

Jak działa cel tygodniowy, żeby był elastyczny i logiczny? Właściciel (2026-11-04): „elastyczniejszy musi być i dobrze logicznie przekminiony”.

## Stan dziś

Cel jest wpisany na sztywno w mocku (`MockData.weeklyGoal = 75`, czyli 75 podciągnięć tygodniowo), a pierścień w hero liczy tylko podciągnięcia. Nie da się go zmienić.

## Propozycja koordynatora (2026-11-04)

**Tydzień** to poniedziałek–niedziela (polski kalendarz).

**Rodzaje celu.** Każdy ustawia od 1 do 3 celów naraz. Jeden jest główny i to on wypełnia pierścień w hero, pozostałe pokazuje moduł na Home:
1. **Dni treningowe:** ile dni w tygodniu z przynajmniej jednym zapisanym treningiem (np. 3). To domyślny cel.
2. **Zaplanowane treningi:** ile treningów z planów zrobić w tygodniu. Wariant „wszystkie zaplanowane” sam liczy, ile planów wypada w danym tygodniu.
3. **Objętość ćwiczenia:** suma powtórzeń albo sekund wybranego ćwiczenia (np. 75 podciągnięć, 3 minuty L-situ). To dzisiejszy pomysł z mocka, tylko do wyboru.

**Zasady:**
- **Wartość domyślna z programu.** Minimum i Fundamenty: 3 dni. Pierwsze podciągnięcie: zgodnie z częstotliwością programu. Bez programu: 3 dni.
- **Pierwszy tydzień jest proporcjonalny.** Kto zaczyna w czwartek z celem 3 dni, ma w tym tygodniu cel 2, żeby nie startować od porażki.
- **Zmiana celu w trakcie tygodnia** działa od razu na bieżący tydzień. Zamknięte tygodnie się nie zmieniają, bo każdy tydzień zapamiętuje cel, który obowiązywał.
- **Tydzień przerwy** (choroba, wyjazd): oznaczasz go w Profilu albo na Home. Nie liczy się do celu i nie przerywa serii.
- **Seria tygodni:** liczba tygodni z rzędu z wykonanym celem głównym. Hero pokazuje serię tygodni, bo w kalistenice dni odpoczynku są częścią treningu. Moduł „Seria dni” zostaje dla chętnych.
- **Wykonany cel** daje krótką celebrację, ale bez XP. XP zostaje za szczeble, więc nie da się go nabić.
- **Gdzie się ustawia:** w onboardingu (krok po programie), w Profilu i długim przytrzymaniem pierścienia w hero.

**Dane:** nowy mały store (`WeeklyGoalStoring`, `File…` na `JSONFileStore`) z historią wersji celu i oznaczonymi tygodniami przerwy. Postęp liczy czysta funkcja z `calendar:` i `asOf:`.
