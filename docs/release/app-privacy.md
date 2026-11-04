# App Store: odpowiedzi „App Privacy” dla CaliPark 1.0 (szkic)

Odpowiedzi do App Store Connect → App Privacy dla wersji z samym treningiem (bez Konta, Społeczności i syncu). Sprawdzone w kodzie na `521b254` (2026-11-04). Polityka prywatności: `site/app/prywatnosc/page.tsx`.

## Odpowiedź

**„Do you or your third-party partners collect data from this app?” → No (Data Not Collected).**

Etykieta w App Store pokaże wtedy „Data Not Collected” („Dane nie są zbierane”).

## Uzasadnienie

Apple definiuje zbieranie tak: „*Collect* refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time” ([App privacy details](https://developer.apple.com/app-store/app-privacy-details/)).

| Dane | Co robi apka | Zbierane w rozumieniu Apple? |
|---|---|---|
| Treningi, plany, test poziomu, postęp, cel tygodniowy, ulubione | Pliki JSON w `Application Support/CaliPark/` i `UserDefaults` na telefonie. W kodzie nie ma `URLSession` ani żadnego SDK. | **Nie**: nie opuszczają telefonu. |
| Lokalizacja (Precise/Coarse Location) | `CLLocationManager`, „podczas używania”, dokładność 100 m, tylko do mapy i odległości; nigdy nie zapisywana (`LocationProvider.swift`). | **Nie**: nie opuszcza telefonu. |
| Mapa (MapKit) i „Nawiguj” (Mapy Apple) | Kafelki mapy pobiera system od Apple; „Nawiguj” otwiera `maps.apple.com` ze współrzędnymi Parku, nie użytkownika. | **Nie**: „You are not responsible for disclosing data collected by Apple.” |
| Przypomnienia | Lokalne `UNNotificationRequest` + `BGAppRefreshTask`; brak pushy i serwera. | **Nie** |
| Eksport/import | Plik JSON tworzony na telefonie; użytkownik sam wybiera, gdzie go wysłać (`ShareLink`). Do nas nie trafia. | **Nie** |
| Raporty awarii Apple (Organizer, TestFlight) | Apple zbiera je za zgodą użytkownika („Udostępniaj deweloperom”) i przekazuje nam. | **Nie** do deklaracji: zbiera Apple, nie apka. |
| E-mail „Napisz do nas” | Link `mailto:`; wiadomość wysyła aplikacja Poczta użytkownika. | **Nie** (patrz niżej). |
| Ekran „Diagnostyka” (MetricKit, W-diagnostics) | Raporty trzymane na telefonie; trafiają do nas tylko, gdy użytkownik sam wyśle je e-mailem. | **Nie** (patrz niżej). |

### E-mail i raporty wysyłane przez użytkownika

Apka nie wysyła ich sama: otwiera pocztę użytkownika, a on decyduje, czy i co wysłać. Nawet gdyby uznać to za zbieranie, spełnia to wszystkie warunki „Optional disclosure” Apple:

- dane nie służą do śledzenia ani reklamy,
- zdarza się to rzadko, nie jest główną funkcją apki i jest dobrowolne,
- użytkownik sam je podaje w formularzu, widzi, co wysyła, a jego adres (nadawca) widnieje w wiadomości, i za każdym razem sam decyduje o wysłaniu.

Apple podaje wprost przykład: „data collected in optional feedback forms or customer service requests that are unrelated to the primary purpose of the app” może nie wymagać deklaracji.

**Wariant ostrożny** (jeśli właściciel woli): zadeklarować *Contact Info → Email Address* oraz *Diagnostics → Crash Data, Performance Data*, każde jako „App Functionality”, „Linked to the user: Yes” (bo przychodzą z adresu e-mail), „Used for tracking: No”. Etykieta przestaje wtedy pokazywać „Data Not Collected”, więc rekomendacja to wariant główny.

## Zgodność z privacy manifest

`cali-park/PrivacyInfo.xcprivacy`: `NSPrivacyTracking = false`, brak domen śledzących, pusta lista `NSPrivacyCollectedDataTypes`, `UserDefaults` z powodem `CA92.1`. To zgadza się z „Data Not Collected”. Jeśli W-diagnostics doda API z wymaganym powodem (np. znaczniki czasu plików), uzupełnia tylko `NSPrivacyAccessedAPITypes`, nie listę zbieranych danych.

## Kiedy to przestaje być prawdą

Odpowiedzi trzeba zmienić **przed** wysłaniem buildu, który:

- ma Konto (Sign in with Apple): *Contact Info*, *Identifiers → User ID*,
- ma Społeczność: *User Content* (opinie, zdjęcia), być może *Location* przy zgłoszeniach Parków,
- synchronizuje treningi przez iCloud (CloudKit w prywatnej bazie użytkownika: do sprawdzenia, ticket 009 i research „Whether CloudKit private-database sync counts as collected”),
- dodaje jakikolwiek SDK analityki lub raportów awarii.

Wtedy aktualizujemy też `PrivacyInfo.xcprivacy` i politykę prywatności (lista zmian w komentarzu na górze `site/app/prywatnosc/page.tsx`).
