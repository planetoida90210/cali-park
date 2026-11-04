# App Review: przegląd wytycznych dla 1.0 z samym treningiem

Stan `main` z 2026-11-04: trening bez Konta, mapa Parków z OSM tylko do odczytu, MetricKit na telefonie, lokalne przypomnienia. Bez Społeczności, syncu i płatności. Wytyczne: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) (ostatnia zmiana 2026-10-16). Kroki w App Store Connect: [checklist.md](checklist.md). Szerszy research: [appstore-compliance.md](../wayfinder/research/appstore-compliance.md).

✅ spełnione · ⏳ czeka na blokery z [README.md](README.md) · ❓ otwarte pytanie do właściciela

| Wytyczna | Ryzyko | Jak apka to spełnia | Stan |
|---|---|---|---|
| 1.4.1 Zdrowie (fizyczna krzywda) | Apka daje rekomendacje treningowe. | Nie mierzy niczego o zdrowiu, nie obiecuje efektów. „O apce” ma sekcję „Zdrowie”: to nie porada medyczna, przy urazie lub chorobie lekarz albo fizjoterapeuta, przy bólu przerwij (2026-11-04). | ✅ |
| 1.5 Informacje o deweloperze | Adres pomocy musi prowadzić do kontaktu. | „Pomoc i opinie” ma „Napisz do nas”, ale adres to placeholder `kontakt@calipark.example` (Q36). Support URL `https://<domena>/pomoc` (Q35). | ⏳ |
| 2.1 Kompletność | Placeholdery, martwe linki, atrapy. | Atrapy usunięte (audyt E-2, F-2, G-2, G-5). Prototyp Zgłoszeń, dublery i seedy UI testów są tylko w Debug: archiwum Release nie zawiera ich kodu ani napisów. Zostaje adres e-mail (wyżej). | ⏳ |
| 2.3.1, 2.3.3 Zrzuty i opis zgodne z apką | Zrzuty z danych pokazowych; liczby w opisie. | Zrzuty robi prawdziwa apka (`scripts/store-screenshots.sh`, seed `storeTour`). Opis zgadza się z kodem: 13 ścieżek, 4 programy, 233 Parki (= `parks-osm-pl.json`). Po zmianie funkcji poprawić opis i zrzuty. | ✅ |
| 2.3.6 Kategoria wiekowa | Nieszczere odpowiedzi. | Odpowiedzi w [checklist.md](checklist.md). Wyliczone będzie 9+ (Health or Wellness Topics); nadpisujemy na 16+ od razu (decyzja 2026-11-04, ticket 021). | ✅ |
| 2.3.7 Nazwa i metadane | Nazwy innych marek i apek w metadanych. | Nazwa „CaliPark: kalistenika” (21 znaków), słowa kluczowe bez marek. Opis wymienia z nazwy tylko r/bodyweightfitness i Overcoming Gravity, resztę jako „inne uznane źródła (lista w apce)” (decyzja 2026-11-04): Cali Move i GMB mają własne apki. W „O apce” zostają wszystkie źródła. | ✅ |
| 2.4.1 iPhone na iPadzie | Apka tylko na iPhone'a i tak działa na iPadzie w trybie zgodności; recenzent może jej tam użyć. | Pion, `UIDeviceFamily` = 1. Przed wysłaniem przejść główne ścieżki na symulatorze iPada (niezrobione). Mac i Vision Pro wyłączone w projekcie i do odznaczenia w App Store Connect. | ⏳ |
| 2.5.4 Tryby w tle | `UIBackgroundModes` = `fetch`. | Tylko `BGAppRefreshTask`, który raz na dobę dokłada przypomnienia z planu. To zgodne z przeznaczeniem. Opisane w Review Notes. | ✅ |
| 2.5.19 Ukryte funkcje | Uśpiony kod Społeczności lub Premium. | Brak. Prototyp Zgłoszeń jest w `#if DEBUG`. Społeczność wejdzie w osobnym buildzie przez pełne review, nigdy flagą z serwera (ticket 022). | ✅ |
| 4.2 Minimalna funkcjonalność | „Strona w ramce”, za mało treści. | Natywna apka: drabiny, programy, plany, cel tygodniowy, historia, eksport i import, mapa. | ✅ |
| 4.5.4 Powiadomienia | Powiadomienia wymagane albo marketingowe. | Tylko lokalne przypomnienia o treningu z planu; zgoda dopiero przy pierwszym włączeniu; apka działa bez niej. | ✅ |
| 5.1.1(i) Polityka prywatności | Link w App Store Connect **i w apce**. | Tekst gotowy (`site/app/prywatnosc`), strona nieopublikowana (Q35–Q37). Po publikacji dodać link w „O apce”. | ⏳ |
| 5.1.1(ii) Zgody | Prośba o uprawnienia bez powodu. | Jeden opis uprawnienia: lokalizacja „podczas używania”, pytanie dopiero przy pierwszym otwarciu mapy, mapa działa bez zgody. Pozycja nie jest zapisywana. | ✅ |
| 5.1.1(v) Usuwanie Konta | — | Brak Kont w 1.0. | ✅ |
| 5.1.2 Wykorzystanie danych | Śledzenie, SDK, wysyłka danych. | Brak sieci w kodzie (`URLSession` nie występuje), brak SDK, manifest bez śledzenia, etykieta „Data Not Collected” ([app-privacy.md](app-privacy.md)). Raporty MetricKit wychodzą tylko mailem wysłanym przez użytkownika. | ✅ |
| 5.1.3 Dane o zdrowiu i fitnessie | Treningi to dane fitness. | Bez HealthKit; treningi zostają na telefonie, nie służą reklamie ani nie są nikomu udostępniane. | ✅ |
| 5.2.1, 5.2.2 Treści osób trzecich | Dane OSM, mapy Apple. | Każdy ekran z Parkami pokazuje „© Współtwórcy OpenStreetMap”, „O apce” linkuje licencję. Nic z geokodowania MapKit nie jest zapisywane. ODbL wymaga udostępnienia bazy Parków: plik `data/` jest gotowy, ale publiczny będzie dopiero ze stroną (`/dane`). Po publikacji link w „O apce”. | ⏳ |
| Eksport (szyfrowanie) | Pytanie przy każdym buildzie. | `ITSAppUsesNonExemptEncryption = NO`: apka nie szyfruje sama i nie łączy się z siecią. | ✅ |
| Privacy manifest (warunek uploadu) | Brak powodu dla API z wymaganym powodem (ITMS-91053). | `UserDefaults` z `CA92.1`; plik binarny Release nie odwołuje się do innych takich API (sprawdzenie w [checklist.md](checklist.md)). | ✅ |
| Ikona (warunek uploadu) | Kanał alfa w ikonie (ITMS-90717). | Domyślna ikona 1024 px bez kanału alfa (`scripts/brand/build-icons.mjs`, test w `AppConfigurationTests`). | ✅ |

## Decyzje (2026-11-04)

- **Kategoria wiekowa:** 16+ od razu, także w 1.0 bez Społeczności (ticket 021). Późniejsze podniesienie z 9+ odcięłoby od aktualizacji osoby poniżej 16 lat.
- **Źródła w opisie w App Store:** z nazwy tylko „r/bodyweightfitness i Overcoming Gravity”, reszta jako „i inne uznane źródła (lista w apce)”.

## Otwarte pytanie do właściciela

**Status DSA (trader / non-trader)**, dopiero przed wydaniem w App Store w UE; TestFlight go nie wymaga. Rekomendacja: **non-trader** dla darmowej apki bez reklam i płatności, z ponowną oceną przy Premium; trader pokazuje w App Store adres i telefon. To decyzja prawna: potwierdzić przy konsultacji regulaminu (ticket 021).
