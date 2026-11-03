# Prototyp: karta Parku

Ticket: [Karta parku](../../tickets/023-park-card.md). Klikalna karta Parku w SwiftUI, na mapie A „Wyciszona” ([ticket 011](../../tickets/011-map-look.md)). Pola Parku są z modelu z [ticketu 012](../../proposals/012-park-model.md), a weryfikacja i poprawki z [ticketu 014](../../tickets/014-verified-parks.md).

Kod jest jednorazowy. Leży w `cali-park/Prototypes/ParkCard/` i kompiluje się tylko w buildzie Debug. Nic nie jest wysyłane ani zapisywane, wszystko żyje w pamięci. Parki, opinie, Pseudonimy, zdjęcia (rysowane) i pogoda są zmyślone. Pozycja „Tu jesteś” jest na sztywno przy Pałacu Kultury.

Na mapie są cztery Parki, po jednym na każdy stan:

| Park | Stan | Po co |
| --- | --- | --- |
| Street Workout Skaryszak | Zweryfikowany, pełne dane, 5 zdjęć, 6 opinii | Jak karta wygląda, gdy wszystko jest |
| Street workout · Pole Mokotowskie | Ze Społeczności, nazwa generowana, 2 zdjęcia, 2 opinie | Park ze Zgłoszenia |
| Street workout · ul. Kasprzaka | Z OSM, bez zdjęć, bez sprzętu, bez opinii i szczegółów | Jak karta wygląda, gdy danych brak. Tak będzie wyglądać większość Parków spoza 5 miast |
| Poręcze przy Skarpie | Zweryfikowany, z Twoją poprawką w kolejce | Co widzi autor poprawki, zanim Moderator zdecyduje |

## 1. Kompaktowa karta na mapie

| Przełącznik | Mapa | Zweryfikowany | Ze Społeczności | Z OSM | Z poprawką |
| --- | --- | --- | --- | --- | --- |
| ![Przełącznik](00-przelacznik.png) | ![Mapa](01-mapa.png) | ![Bogaty](02-kompakt-bogaty.png) | ![Ze Społeczności](03-kompakt-spolecznosc.png) | ![OSM](04-kompakt-osm.png) | ![Poprawka](05-kompakt-poprawka.png) |

- **Pinezki:** wariant A. Zweryfikowany Park ma małą pieczątkę, a Park z OSM bez sprzętu ma przygaszoną pinezkę ze znakiem zapytania. Zaufanie widać, zanim ktoś stuknie.
- **Karta:** nazwa, okolica, odległość i czas pieszo. Pod tym etykieta weryfikacji, ocena z liczbą opinii i ikony sprzętu (do 4, potem „+2”). Na dole „Nawiguj” (Apple Maps, trasa piesza) i „Szczegóły”.
- **Gdy brak danych:** „Brak opinii” i „Sprzęt nieznany” zamiast pustych miejsc. Karta ma zawsze tę samą wysokość.
- **Z poprawką:** obok etykiety pomarańczowe „Twoja poprawka czeka”.

## 2. Pełna karta: arkusz, nie nowy ekran

Kompaktowa karta to dolny arkusz na niskiej wysokości. Przeciągnięcie w górę albo „Szczegóły” rozwija go do pełnej karty. Tak działa karta miejsca w Apple Maps. Wybrałem arkusz zamiast nowego ekranu, bo:

- to jeden ruch palcem, a karta i mapa są tą samą rzeczą,
- przy niskiej wysokości mapa dalej działa. Można stuknąć inną pinezkę i karta od razu pokazuje nowy Park, bez „Wstecz”,
- na iOS 26 arkusz dostaje szkło (Liquid Glass) za darmo i wygląda jak reszta systemu.

Minus: poprawki, zgłoszenia i opinie otwierają się jako arkusz na arkuszu. W prototypie działa to dobrze. Nowy ekran byłby lepszy tylko do linków do Parku (udostępnianie), a to można dodać osobno.

## 3. Dwie kolejności pełnej karty

Spór jest realny: zdjęcia najlepiej „sprzedają” Park, ale większość Parków z OSM nie ma zdjęć ani sprzętu. Wtedy kolejność ze zdjęciami na górze zaczyna się od dwóch pustych ramek.

### A · Zdjęcia najpierw

Kolejność z briefu: zdjęcia, sprzęt, skąd te dane, pogoda, opinie, szczegóły, stopka.

| Góra | Sprzęt | Skąd te dane, pogoda | Opinie | Szczegóły i stopka |
| --- | --- | --- | --- | --- |
| ![A góra](A1-bogaty-gora.png) | ![A sprzęt](A2-bogaty-sprzet.png) | ![A weryfikacja](A3-bogaty-weryfikacja-pogoda.png) | ![A opinie](A4-bogaty-opinie.png) | ![A stopka](A5-bogaty-szczegoly-stopka.png) |

### B · Sprzęt najpierw

Najpierw „czy mogę tu dziś potrenować”: sprzęt, pogoda, szczegóły. Potem Społeczność: opinie, zdjęcia, skąd te dane, stopka.

| Góra | Pogoda i szczegóły | Opinie | Zdjęcia, skąd te dane, stopka |
| --- | --- | --- | --- |
| ![B góra](B1-bogaty-gora.png) | ![B pogoda](B2-bogaty-pogoda-szczegoly.png) | ![B opinie](B3-bogaty-opinie.png) | ![B zdjęcia](B4-bogaty-zdjecia-weryfikacja.png) |

## 4. Park bez danych (tylko OSM)

| Góra (A) | Opinie i szczegóły (A) | Stopka (A) | Góra (B) |
| --- | --- | --- | --- |
| ![OSM A](O1-osm-gora-A.png) | ![OSM dalej](O2-osm-dalej-A.png) | ![OSM stopka](O3-osm-stopka-A.png) | ![OSM B](O4-osm-gora-B.png) |

- Każda pusta sekcja ma przerywaną ramkę: co wiemy, dlaczego nie wiemy więcej i jeden przycisk. „Dodaj zdjęcie”, „Uzupełnij sprzęt” (otwiera poprawkę z wybranym sprzętem), „Napisz pierwszą opinię”.
- Brak sprzętu to „Sprzęt nieznany”, a nie „brak sprzętu”. OSM mówi tylko, że to miejsce do kalisteniki (`sport=calisthenics`, 012).
- W szczegółach puste pola mają „Brak danych”, a godziny nigdy nie udają „24 h” (012). Dostęp domyślnie „Dla wszystkich”.
- Pogoda działa zawsze, bo wystarczy położenie. Przy Parku z OSM to często jedyna pełna sekcja.
- W stopce jest atrybucja „© współtwórcy OpenStreetMap, licencja ODbL” z linkiem do openstreetmap.org/copyright.

## 5. Park ze Społeczności

| Góra | Skąd te dane |
| --- | --- |
| ![Ze Społeczności](C1-spolecznosc-gora.png) | ![Skąd te dane](C2-spolecznosc-weryfikacja.png) |

Nazwa generowana z 012 („Street workout · Pole Mokotowskie”), bo autor nie podał nazwy z tabliczki. Sprzęt bez liczby (kółka) pokazuje samą nazwę. Atrybucja w stopce mówi „Społeczność CaliPark, licencja ODbL”, bo nie ma tu danych z OSM.

## 6. Park z poprawką w toku

| Góra | Sprzęt |
| --- | --- |
| ![Poprawka](P1-poprawka-gora.png) | ![Sprzęt z poprawką](P2-poprawka-sprzet.png) |

- Pod nagłówkiem jest ramka „Twoja poprawka czeka na Moderatora” z treścią poprawki, datą, Pseudonimem i „Wycofaj poprawkę”.
- Do decyzji karta pokazuje dane sprzed poprawki. Drążek ma tylko znacznik „Zgłoszona zmiana”.
- „Zgłoś poprawkę” w stopce jest wyłączone, dopóki jedna poprawka czeka.
- Ten stan widzi tylko autor poprawki (pytanie 4).

## 7. Akcje

| Co się nie zgadza? | Sprzęt się zmienił | Parku już nie ma | Zgłoś opinię |
| --- | --- | --- | --- |
| ![Poprawka](M1-poprawka-co.png) | ![Poprawka sprzęt](M2-poprawka-sprzet.png) | ![Parku nie ma](M3-poprawka-parku-nie-ma.png) | ![Zgłoś opinię](M4-zglos-opinie.png) |

| Zdjęcie | Zgłoś zdjęcie | Napisz opinię | Dodaj zdjęcie |
| --- | --- | --- | --- |
| ![Zdjęcie](M5-zdjecie.png) | ![Zgłoś zdjęcie](M8-zglos-zdjecie.png) | ![Napisz opinię](M6-napisz-opinie.png) | ![Dodaj zdjęcie](M7-dodaj-zdjecie.png) |

- **Zgłoś poprawkę** (ticket 014): sześć powodów. Sprzęt to te same chipy co w Zgłoszeniu (klucze OSM z 012). „Parku już nie ma” mówi, że Moderator to sprawdzi, zanim zdejmie Park. Pozostałe powody mają krótkie pole tekstowe, które widzi tylko Moderator (to nie jest opis Parku). Wszędzie można dodać zdjęcie z miejsca. Po „Wyślij do moderacji” karta przechodzi w stan z punktu 6.
- **Zgłoś treść** (DSA art. 16, App Store 1.2): przy każdej opinii jest menu „•••”, a w podglądzie zdjęcia przycisk „Zgłoś zdjęcie”. Powody: niezgodne z prawem, obraźliwe, spam, czyjaś twarz lub dane, nie z tego Parku, coś innego. Przy treści niezgodnej z prawem wyjaśnienie jest wymagane (art. 16). E-mail jest opcjonalny, a Konto niepotrzebne (ticket 008). Przełącznik „Ukryj treści od …” to blokowanie autora, którego wymaga Apple 1.2.
- **Napisz opinię:** gwiazdki wymagane, tekst opcjonalny, Pseudonim widoczny. Bez polubień i komentarzy (propozycja 021). Nowa opinia jest od razu na górze listy z etykietą „Ty”.
- **Dodaj zdjęcie:** atrapa aparatu jak w Zgłoszeniu. Zdjęcie pokazuje się z etykietą „Czeka na moderację”.
- **Podgląd zdjęcia:** przewijanie zdjęć, autor i data. Zdjęcia ekipy mają „Zdjęcie ekipy CaliPark”.
- **Nawiguj:** otwiera Apple Maps z trasą pieszą do Parku.

## Jak uruchomić

W Xcode: **Product → Scheme → Edit Scheme… → Run → Arguments**, dodaj argument `-PrototypeParkCard` i uruchom apkę. Zamiast zwykłej apki pokaże się mapa z czterema Parkami. Stuknij pinezkę. Biała pigułka u góry wybiera Park i przełącza kolejność A ↔ B. Przy rozwiniętej karcie ta sama pigułka jest na dole arkusza. Pigułka nie jest częścią projektu.

Z terminala, na włączonym symulatorze z zainstalowanym buildem Debug:

```sh
xcrun simctl launch booted com.michalbryk.cali-park -PrototypeParkCard
```

Dodatkowe argumenty, użyte do zrzutów:

- `-ParkCardPark rich|community|osm|pending` otwiera kartę wybranego Parku,
- `-ParkCardOrder photos|equipment` wybiera kolejność A albo B,
- `-ParkCardDetent full` otwiera od razu pełną kartę,
- `-ParkCardScroll photos|equipment|verification|weather|reviews|facts|footer` przewija pełną kartę do sekcji,
- `-ParkCardModal correction|correction-equipment|correction-gone|report-photo|report-review|review|add-photo|photo` otwiera arkusz akcji,
- `-ParkCardClean` chowa pigułkę.

## Rekomendacja

**Kolejność B · Sprzęt najpierw, z jedną rzeczą z A: gdy Park ma zdjęcia, pasek zdjęć stoi na samej górze pełnej karty.** Gdy zdjęć nie ma, ich pusta ramka spada niżej, na miejsce z B.

Dlaczego:

- Pierwsze pytanie w parku to „czy jest wysoki drążek i czy zaraz nie będzie padać”. B odpowiada na nie od razu.
- Większość Parków na starcie będzie z OSM, bez zdjęć i sprzętu. W A taka karta zaczyna się od dwóch pustych ramek. W B zaczyna się od „Sprzęt nieznany, uzupełnij” i od razu pełnej pogody.
- Ticket 014 mówi, że zdjęcia ekipy są okładką Zweryfikowanych Parków. Zdjęcie na górze to więc decyzja już podjęta, ale tylko tam, gdzie ono jest.

Pełna karta jako **arkusz** (punkt 2), nie nowy ekran.

## Pytania do właściciela

1. **Kolejność pełnej karty: A, B czy B z okładką z A?** Rekomendacja: **B z paskiem zdjęć na górze, gdy zdjęcia są** (wyżej).
2. **Pełna karta: arkusz na mapie czy nowy ekran?** Rekomendacja: **arkusz**, jak w Apple Maps. Link do Parku (udostępnianie) dodać osobno.
3. **Czy „Ze Społeczności” ma być widoczną etykietą?** W 012 poziom `community` jest „bez odznaki”, a brief prosi o trzy etykiety. Prototyp pokazuje ją jako cichą, szarą etykietę, a na kolor (limonkowy) zasługuje tylko „Zweryfikowany”. Rekomendacja: **szara etykieta dla „Ze Społeczności” i „Z OSM”**, żeby przy każdym Parku było widać, skąd są dane.
4. **Kto widzi poprawkę w toku?** Rekomendacja: **tylko jej autor**. Inni widzą Park bez zmian do decyzji Moderatora. Inaczej jedna osoba mogłaby „zgasić” każdy Park zgłoszeniem „Parku już nie ma”.
5. **Opinie i zdjęcia: od razu czy po moderacji?** Rekomendacja: **opinie od razu** (filtr słów, „Zgłoś” i blokowanie autora wystarczą według Apple 1.2), **zdjęcia dopiero po akceptacji Moderatora**, bo na zdjęciu może być twarz albo coś nielegalnego.
6. **Średnia ocen od ilu opinii?** Prototyp pokazuje średnią już z 1–2 opinii („4,0 · 2 opinie”). Rekomendacja: **średnia od 3 opinii**. Poniżej tylko lista i liczba opinii.
7. **Pogoda przed WeatherKit.** WeatherKit wymaga płatnego konta Apple Developer (ticket 017) oraz znaku „ Pogoda” z linkiem do źródeł danych przy każdym wyświetleniu. Rekomendacja: **bez konta sekcji pogody nie ma wcale**. Nie pokazujemy danych przykładowych ani innego dostawcy.
8. **Zgłoś treść: brzmienie i blokowanie.** Prototyp ma powody, wymagane wyjaśnienie przy treści nielegalnej, opcjonalny e-mail i „Ukryj treści od autora”. Rekomendacja: **taki zestaw, a dokładne brzmienie ustalić razem z regulaminem** (to samo co pytanie 7 w prototypie Zgłoszenia). Przycisk „Zgłoś” dać też na zdjęciach ekipy, choć prototyp go tam pomija.
9. **Nazwa Parku z OSM bez sprzętu.** Reguła z 012 §4 bierze przedrostek ze sprzętu, a tu sprzętu nie ma. Prototyp pisze „Street workout · ul. Kasprzaka”. Rekomendacja: **„Street workout”, gdy sprzęt jest nieznany**.
10. **Nawiguj: tylko Apple Maps?** Rekomendacja: **tak w v1**. Wybór Google Maps, gdy jest zainstalowane, można dodać później.

## Uwagi do wdrożenia

- Prototyp korzysta z typów prototypów mapy (`MapLookFormat`, `MapLookUserDot`, `mapLookGlass`) i Zgłoszenia (`SubmissionEquipment`, `BarHeight`, `SamplePhotoView`, `SelectableChip`, `FlowLayout`). Usunięcie tamtych folderów zepsuje ten.
- Wysokość kompaktowej karty jest na sztywno (176 pt). Przy dużej czcionce (Dynamic Type) karta się przytnie. Prawdziwa wersja musi mierzyć nagłówek.
- Ocena, liczba opinii i zdjęcia są w prototypie polami Parku tylko dla wygody. Według 012 liczy je warstwa Społeczności.
- Ikony sprzętu to tymczasowe SF Symbols, jak w poprzednich prototypach.
- „Nadaje się do flagi” liczy prototyp według 012 §3: pionowy drążek, słup do wspinania albo drabinka gimnastyczna.
- „Do 150 m: woda pitna, toaleta” to pola liczone z OSM z 012 (`nearbyWater`, `nearbyToilets`).
- „Nawiguj” otwiera adres `maps://` z trasą pieszą. Nie używa `MKPlacemark`, który iOS 26 oznacza jako przestarzały.
