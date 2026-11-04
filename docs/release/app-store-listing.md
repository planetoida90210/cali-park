# App Store: teksty CaliPark 1.0 (szkic)

Szkic do App Store Connect, wersja polska. Stan apki: `main` z 2026-11-04 (trening bez Konta, bez Społeczności). Każde zdanie opisuje to, co apka naprawdę robi; przy zmianie funkcji popraw też ten plik i stronę (`site/app/page.tsx`).

Limity Apple: nazwa i podtytuł do 30 znaków, tekst promocyjny do 170, opis do 4000, słowa kluczowe do 100 (liczymy też bajty, bo polskie litery zajmują po 2, a pewniej zmieścić się w obu).

## Nazwa (≤ 30)

**CaliPark: kalistenika** (21). Decyzja 2026-11-04 (Q39, delegowana koordynatorowi): dopisek łapie wyszukiwanie „kalistenika”; pod ikoną na telefonie zostaje „CaliPark”.

## Podtytuł (≤ 30)

**Trening na drążku z planem** (26 znaków). Bez słowa „kalistenika”, bo jest już w nazwie, a Apple indeksuje nazwę i podtytuł razem.

Inne: „Drabiny progresji i drążki” (26).

## Tekst promocyjny (≤ 170)

> Kalistenika krok po kroku: drabiny progresji ze źródłami, gotowe programy, cel tygodniowy i mapa drążków w Polsce. Bez Konta, bez reklam, dane zostają na telefonie.

(165 znaków. Ten tekst można zmieniać bez nowej wersji apki.)

## Opis (≤ 4000)

```
CaliPark prowadzi Cię w kalistenice od pierwszego zwisu na drążku do muscle-upa. Mówi, co ćwiczyć dziś, kiedy przejść na trudniejszy wariant i gdzie w okolicy jest drążek.

DRABINY PROGRESJI ZE ŹRÓDŁAMI
13 ścieżek: podciąganie, wiosłowanie, pompki, dipy, nogi, core, muscle-up, L-sit, front lever, back lever, planche, flaga i stanie na rękach. Każdy szczebel ma jasne kryterium awansu, np. 3 × 8, i źródło: Recommended Routine z r/bodyweightfitness, Overcoming Gravity, GMB, StartBodyweight albo Cali Move. Krótki test na start ustawia Cię na właściwym szczeblu.

GOTOWE PROGRAMY
Minimum, Fundamenty, Pierwsze podciągnięcie i Skille. Podgląd pokazuje ćwiczenia na Twoim poziomie, a jednym stuknięciem robisz z programu własny plan, który zmienisz, jak chcesz.

PLANY I PRZYPOMNIENIA
Ustal dni treningowe i godzinę. Przypomnienie przychodzi tylko w dni z planu i tylko wtedy, gdy trening nie jest jeszcze zrobiony. Serie zapisujesz kilkoma stuknięciami.

CEL TYGODNIOWY
Dni treningowe, treningi z planu albo objętość ćwiczenia. Pierścień pokazuje postęp tygodnia, a seria tygodni rośnie z każdym zaliczonym. Wyjeżdżasz? Pauza do 90 dni nie zrywa serii.

POZIOMY I XP
Każde powtórzenie i każda sekunda utrzymania pozycji dają XP, a awanse na drabinach i nowe poziomy apka świętuje razem z Tobą.

MAPA PARKÓW
233 miejsca w Polsce z drążkiem albo poręczami, z danych OpenStreetMap. Odległość od Ciebie, sprzęt, oświetlenie i nawierzchnia, jeśli są w danych, nawigacja w Mapach Apple i ulubione Parki.

BEZ KONTA, DANE U CIEBIE
Nie zakładasz konta. Treningi, plany i postępy zostają na Twoim telefonie, a eksport do jednego pliku przeniesie je na nowy telefon. Lokalizacja służy tylko do mapy i nigdy nie jest zapisywana. Bez reklam, analityki i śledzenia.

Dane o Parkach: © Współtwórcy OpenStreetMap, licencja ODbL.
```

(ok. 1700 znaków)

## Słowa kluczowe (≤ 100)

```
calisthenics,street workout,drążek,podciąganie,pompki,poręcze,dipy,progresja,muscle up,siłownia
```

95 znaków, 100 bajtów. Bez słów z nazwy i podtytułu („kalistenika”, „plan”, „mapa”), bo Apple i tak je indeksuje. Bez spacji po przecinkach.

## Zrzuty ekranu (iPhone 6,9")

Sześć zrzutów 1320 × 2868 (zestaw 6,9" pokrywa wszystkie rozmiary iPhone'a) robi `scripts/store-screenshots.sh` na seedzie `storeTour`: pięć tygodni „Fundamentów” trzy razy w tygodniu, plan na dziś jeszcze niezrobiony, seria 5 tygodni, podciągnięcia na 3 × 6. Surowe zrzuty trafiają do `docs/release/screenshots/raw/`, wersje z nagłówkiem do `docs/release/screenshots/framed/`. Opis i ograniczenia: `docs/release/screenshots/README.md`.

Nagłówki (do 30 znaków; gwiazdki oznaczają słowa w kolorze akcentu, `<br>` łamie wiersz). Skrypt kadrujący czyta je z tej tabeli, więc zmiana nagłówka to zmiana tutaj i ponowne `xcrun swift scripts/frame-store-screenshots.swift`.

| Plik | Nagłówek | Ekran |
|---|---|---|
| `01-home` | Wiesz, co<br>ćwiczyć *dziś* | Start: plan na dziś, „Rozpocznij”, pierścień celu tygodniowego |
| `02-ladder` | Od zwisu<br>do *podciągnięć* | Ścieżka „Podciąganie”: zaliczone szczeble, kryterium 3 × 8, najlepsze 3 × 6 |
| `03-programs` | *Gotowe* programy<br>na start | „Gotowe programy”: Minimum, Fundamenty, Pierwsze podciągnięcie, Skille |
| `04-workout` | Pary, rundy<br>i *przerwy* | Trening „Fundamenty”: Para 1, Runda 2/3, przerwa 90 s |
| `05-profile` | Trzymaj *serię*<br>tygodni | Profil: seria 5 tygodni z celem, seria dni, poziom, cel 2 / 3 dni |
| `06-parks` | Drążek w Twojej<br>*okolicy* | Mapa Parków (Warszawa) z kartą najbliższego Parku z OSM |

## Pozostałe pola

| Pole | Propozycja |
|---|---|
| Kategoria główna | Zdrowie i fitness |
| Kategoria dodatkowa | Sport (opcjonalnie) |
| Adres pomocy (Support URL) | `https://<domena>/pomoc` |
| Adres marketingowy | `https://<domena>/` |
| Polityka prywatności | `https://<domena>/prywatnosc` |
| Copyright | `2026 [IMIĘ I NAZWISKO]` |
| Cena | Darmowa |
| Kategoria wiekowa | do wyliczenia w kwestionariuszu; 1.0 nie ma treści użytkowników ani czatu, więc spodziewane 4+ |

## TestFlight

**Opis wersji beta (Beta App Description):**

> CaliPark to apka do kalisteniki: drabiny progresji, gotowe programy, cel tygodniowy i mapa drążków z OpenStreetMap. Działa bez Konta, wszystkie dane zostają na telefonie.

**Co testować (What to Test):**

> Trenuj jak zwykle przez tydzień lub dwa. Sprawdź zwłaszcza: test poziomu na start, plan z gotowego programu, przypomnienia w dni treningowe, cel tygodniowy i mapę Parków w Twojej okolicy. Błąd albo pomysł? Zrób zrzut ekranu i wybierz „Udostępnij do wersji beta”.

**Adres e-mail do opinii:** `[E-MAIL]`
