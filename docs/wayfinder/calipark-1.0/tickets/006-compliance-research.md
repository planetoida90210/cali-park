---
title: Wymagania App Store i RODO dla 1.0
type: research
mode: AFK
status: closed
assignee: planetoida90210
blocked_by: []
---

# Wymagania App Store i RODO dla 1.0

## Pytanie

Co CaliPark 1.0 musi spełnić, żeby przejść App Review i być zgodnym z prawem w Polsce i UE? Obszary:
- treści użytkowników (wytyczna 1.2),
- Sign in with Apple, usuwanie Konta i prywatność (manifest, etykiety, polityka),
- zdjęcia (EXIF/GPS),
- apka tylko na iPhone,
- TestFlight zewnętrzny, konto deweloperskie osoby fizycznej, WeatherKit,
- RODO (umowa powierzenia, prawa osób, wiek 16 lat),
- DSA (zgłoszenia i uzasadnienia moderacji).

Wynik: [research/appstore-compliance.md](../../research/appstore-compliance.md) (zweryfikowany).

## Rozstrzygnięcie (2026-11-03)

Szczegóły i trzy checklisty (TestFlight, App Store, should-have) są w [research/appstore-compliance.md](../../research/appstore-compliance.md). Fakty sprawdził niezależny weryfikator.

- **Bloker uploadu (też TestFlight):** `PrivacyInfo.xcprivacy` z `UserDefaults` (`CA92.1`). Do poprawy są też teksty uprawnień, `TARGETED_DEVICE_FAMILY` (dziś `1,2`, ma być `1`), wyłączenie Maca i Vision Pro oraz usunięcie mocków i uśpionego kodu Społeczności/Premium (wytyczne 2.1, 2.5.19).
- **Społeczność (Apple 1.2):**
  - filtr, zgłaszanie, blokowanie i kontakt,
  - regulamin z zerową tolerancją i reakcja na zgłoszenia w 24h,
  - od 2026-10-16 aktywne zapobieganie intymnym obrazom publikowanym bez zgody,
  - usunięcie Konta kasuje opinie i zdjęcia oraz unieważnia token Sign in with Apple.
- **Kategoria wiekowa:** minimalny wiek Konta powyżej wyliczonej kategorii wymusza tę kategorię dla całej apki. Konto 16+ oznacza więc apkę 16+, razem z treningiem.
- **Apple Developer:** 99 USD/rok. U osoby fizycznej imię i nazwisko widnieje jako sprzedawca i nie potrzeba D-U-N-S. Do listingu w UE trzeba złożyć deklarację DSA (trader albo non-trader); trader pokazuje adres i telefon. Sama dystrybucja przez TestFlight nie wymaga statusu tradera.
- **RODO:** właściciel jest administratorem. Podstawy prawne to umowa i prawnie uzasadniony interes. Potrzebne są:
  - polska polityka prywatności (art. 13),
  - umowy powierzenia (art. 28) z dostawcami przed zapisaniem danych testerów,
  - odpowiedź na wnioski w miesiąc,
  - rejestr czynności,
  - zgłaszanie naruszeń w 72h,
  - usuwanie GPS/EXIF ze zdjęć na telefonie i na serwerze.
- **DSA i prawo polskie:** mikroprzedsiębiorca jest zwolniony z raportów. Formularz zgłoszeń musi być otwarty dla każdego, także bez Konta, a każde usunięcie wymaga uzasadnienia. Do tego punkty kontaktowe i zasady moderacji. Polska ustawa wdrażająca DSA wchodzi 2026-11-06.
- **Daty Apple:** pytania wiekowe o treści społecznościowe obowiązują od 09.2026. Deklaracje „Shared Location” obowiązują od 2026-11-16. Od kwietnia 2027 wymagane jest SDK iOS 27 i screeny z iPhone Duo.
- **Rekomendowana kolejność:** najpierw zewnętrzny TestFlight z samym treningiem, potem Społeczność w buildzie, który przechodzi review. Funkcji nie włączamy flagą z serwera po akceptacji.
