---
title: Cel tygodniowy
type: grilling
mode: HITL
status: closed
assignee: planetoida90210
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

## Odpowiedzi właściciela (2026-11-04, częściowe)

Przyjęte: rodzaje celu (1–3 cele, jeden główny), tydzień przerwy bez utraty serii, seria tygodni w hero, celebracja bez XP. Do wyjaśnienia: wartość domyślna, pierwszy tydzień i zmiana celu w trakcie tygodnia.

## Rozstrzygnięcie (2026-11-04)

**Propozycja z poprawkami wzorowanymi na Apple Watch (watchOS 11).** Właściciel: „decyduj, masz spoko referencje z Apple Watcha”.

- Rodzaje celu: dni treningowe (domyślny), zaplanowane treningi (liczba albo „wszystkie zaplanowane”), objętość ćwiczenia; 1–3 cele, jeden główny w hero.
- Wartość domyślna z programu, bez programu 3 dni.
- Odpoczynek jest elastyczny: cel to „X dni w tygodniu”, nie konkretne dni. Kto trenuje w stałe dni, wybiera „wszystkie zaplanowane”.
- **Pierwszy niepełny tydzień jest „rozgrzewkowy”:** wykonany cel liczy się do serii, niewykonany niczego nie psuje. Pełne liczenie od pierwszego poniedziałku (jak „Idealny tydzień”).
- Zmiana celu działa od razu na bieżący tydzień; zamknięte tygodnie liczą się według celu, który wtedy obowiązywał.
- **Pauza** zamiast samego tygodnia przerwy: tydzień, miesiąc albo do 90 dni, bez utraty serii; kończy się sama albo jednym tapnięciem. Tygodnie pauzy nie liczą się do celu.
- Hero pokazuje serię tygodni; moduł „Seria dni” zostaje.
- Wykonany cel: celebracja bez XP.

## Wdrożenie (2026-11-04)

Zmergowane jako `8d07335`. Koordynator (z delegacji właściciela) przyjął: hero bez serii dni, tydzień z dowolnym dniem pauzy jest neutralny, chyba że cel zrobiony; pierścień w hero tylko w stanach „zrobione dziś”, odpoczynek i wolny trening, żeby „Rozpocznij” zostało w centrum.
