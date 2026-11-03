---
title: CaliPark 1.0
label: wayfinder:map
---

# CaliPark 1.0

## Cel

Zdecydowany spec CaliPark 1.0: zakres, backend, model danych, wygląd kluczowych ekranów i plan wydania pocięty na sprinty, gotowy do wykonania. Docelowo App Store przed kwietniem 2027, a zimą 2026/27 TestFlight z ekipą.

## Notatki

- **Domena:** apka do kalisteniki, czyli trening działający bez Konta plus mapa Parków ze Społecznością. Słownik: [GLOSSARY.md](../../../GLOSSARY.md). Stan kodu i znane bugi: [docs/audit/README.md](../../audit/README.md). Jak działa ten tracker: [README.md](../README.md).
- **Właściciel dopiero zaczyna w Swift/iOS.** Wybory techniczne iOS tłumacz prosto, z jedną rekomendacją. Decyzje produktowe, estetyczne i finansowe należą do właściciela.
- **Skille:**
  - `grilling` i `domain-modeling` przy każdym tickecie HITL,
  - `research` przy researchowych, `prototype` przy prototypach,
  - `swiftui-pro` i `swiftui-design-principles` przy UI,
  - `swift-concurrency-pro` przy backendzie i syncu,
  - `core-data-expert` przy syncu przez CloudKit,
  - `swift-testing-pro` przy planie testów.
- **Stałe preferencje:**
  - dane w UE,
  - koszt backendu do ok. 100 zł/mies. przy ~10k aktywnych użytkowników, bez własnego serwera,
  - bezpieczeństwo z kontrolą dostępu na poziomie wierszy,
  - trening zawsze darmowy i bez Konta,
  - commity prosto na `main`, bez trailerów.
- **Planowanie, ale z równoległym wykonaniem prac „bez żalu”.** Mapa kończy się na specu. Właściciel (2026-11-03) zgodził się, żeby równolegle do niej szły w wątkach-workerach prace potrzebne przy każdej decyzji: Faza 0 fundamentu (P0 z audytu, privacy manifest, iPhone-only), prototypy do ticketów i propozycje do potwierdzenia.
- **Koordynacja.** Jeden wątek-koordynator prowadzi mapę, zleca pracę workerom, merguje na `main` i jako jedyny zadaje właścicielowi pytania. Workerzy nigdy nie pytają właściciela, tylko zgłaszają pytania koordynatorowi. Gdy kontekst koordynatora dojdzie do ok. 200–250k tokenów, przekazuje rolę świeżemu wątkowi przez handoff.

## Decyzje do tej pory

- [Zakres CaliPark 1.0: decyzje z chartingu](tickets/001-zakres-1-0.md):
  - start w Polsce po polsku,
  - Sign in with Apple, publiczny tylko Pseudonim,
  - Społeczność v1 to Parki, opinie i zdjęcia z moderacją, a zgłoszenia są darmowe,
  - treningi przez iCloud,
  - backend w UE do ok. 100 zł/mies.,
  - v1 darmowe, tylko iPhone,
  - prawdziwa pogoda, rewizja programów,
  - najpierw fundament, App Store przed kwietniem 2027.
- [Backend dla Parków i Społeczności: opcje i koszty](tickets/002-backend-research.md):
  - ranking: Supabase Cloud Pro Frankfurt (25 USD/mies. do ok. 45k MAU), potem własne API na Hetznerze (ok. 15–31 €/mies.), potem PocketBase,
  - Rust sam nie daje bezpieczeństwa,
  - limit zapisów i uzasadnienia usunięć (DSA) budujemy sami.
- [Sync treningów przez iCloud: technologia i migracja](tickets/003-sync-research.md):
  - CKSyncEngine na prywatnej bazie iCloud, pliki JSON zostają źródłem prawdy,
  - Faza 0 (naprawa danych) nie wymaga płatnego konta,
  - schemat zamraża pierwszy build TestFlight z syncem.
- [Parki z OpenStreetMap w Polsce i licencja ODbL](tickets/004-osm-research.md):
  - ok. 390 pewnych Parków w Polsce, ok. 107 w 5 miastach,
  - użycie OSM wymaga udostępnienia danych Parków na ODbL,
  - innych źródeł nie wolno importować.
- [Drabiny progresji i gotowe programy ze źródeł](tickets/005-progressions-research.md):
  - większość drabin trzyma się źródeł,
  - do poprawy: handstand, L-sit, planche, flaga, nogi,
  - programy: Minimum od razu, Fundamenty po nowych drabinach, Skille tylko handstand i L-sit,
  - najpierw stabilne ID szczebli.
- [Wymagania App Store i RODO dla 1.0](tickets/006-compliance-research.md):
  - privacy manifest blokuje upload,
  - Społeczność wymaga zgłoszeń, blokowania, reakcji w 24h i kasowania treści z Kontem,
  - Konto 16+ daje apkę 16+,
  - RODO: polityka, umowy powierzenia i usuwanie EXIF,
  - DSA: zgłoszenia także bez Konta i uzasadnienia usunięć.
- [Wybór backendu](tickets/007-backend-choice.md):
  - Supabase Cloud Pro, Frankfurt,
  - 8 GB na bazę i 100 GB na zdjęcia (ok. 300 tys. zdjęć),
  - RLS, własne limity, DSA, DPA,
  - odrzucone: Rust/Hetzner, PocketBase, Firebase, CloudKit public.
- [Technologia syncu treningów](tickets/009-sync-tech.md): CKSyncEngine na prywatnym iCloud, pliki JSON jako źródło prawdy, bez Konta.
- [Warstwa danych treningów: naprawione pliki JSON czy SwiftData](tickets/010-training-persistence.md):
  - utwardzone pliki JSON (Faza 0: bez cichego wipe'u, wersjonowanie, stabilne ID szczebli),
  - SwiftData odrzucone.

## Jeszcze nieokreślone

- **Karta parku:** co dokładnie pokazuje (zdjęcia, sprzęt, opinie, pogoda, status weryfikacji) i w jakiej kolejności. Zależy od modelu Parku i decyzji o weryfikacji.
- **Home w 1.0:** które moduły zostają po wycięciu mocków. Pogoda będzie prawdziwa, a leaderboard i feed są w v1.1. Do tego co z „celem tygodniowym”.
- **Profil i ustawienia w 1.0:** Pseudonim, wylogowanie, usunięcie Konta, eksport danych, powiadomienia.
- **Onboarding:** kiedy prosić o lokalizację, powiadomienia i Konto oraz co z dzisiejszymi pytaniami o cele.
- **Identyfikacja wizualna:** ikona, spójny styl całej apki, czyli to samo „stylowo” co przy mapie.
- **Diagnostyka:** zgłaszanie crashy i analityka zgodne z RODO.
- **Wydanie:** strona z polityką prywatności i regulaminem; opis, screeny (od kwietnia 2027 także iPhone Duo) i kategoria w App Store; zbieranie feedbacku od ekipy z TestFlight.
- **Zasady Społeczności i regulamin:** treść regulaminu (zero tolerancji, licencja na treści, wymogi DSA), powiadamianie autorów o wyniku moderacji, blokowanie użytkowników. Zależy od wyboru backendu i minimalnego wieku Konta.

## Poza zakresem

- Model monetyzacji i ceny. Decyzja zapada po starcie, gdy będzie wiadomo, czy ludziom się podoba; v1 jest darmowe ([Zakres CaliPark 1.0](tickets/001-zakres-1-0.md)).
- Tłumaczenia na angielski i ukraiński. Wchodzą po starcie; w zakresie jest tylko infrastruktura String Catalog ([Zakres CaliPark 1.0](tickets/001-zakres-1-0.md)).
- Wydarzenia, tłok, feed i leaderboard, które przechodzą do v1.1 ([Zakres CaliPark 1.0](tickets/001-zakres-1-0.md)).
- iPad i orientacja pozioma ([Zakres CaliPark 1.0](tickets/001-zakres-1-0.md)).
