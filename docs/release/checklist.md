# Dzień zakupu konta: od Apple Developer do TestFlightu

Lista krok po kroku na dzień, w którym właściciel kupi Apple Developer Program (ticket 017). Dotyczy 1.0 z samym treningiem (ticket 022): bez Konta, Społeczności i syncu. Wytyczne App Review dla tej wersji: [app-review.md](app-review.md).

## Co jest już sprawdzone (2026-11-04)

`xcodebuild archive` (Release, `generic/platform=iOS`, `CODE_SIGNING_ALLOWED=NO`) przechodzi bez ostrzeżeń. W archiwum:

- `Info.plist`: `CFBundleDisplayName` „CaliPark”, wersja 1.0 (1), tylko iPhone (`UIDeviceFamily` = 1), tylko pion, `arm64`, iOS 18.4+, `ITSAppUsesNonExemptEncryption` = NO, jeden opis uprawnień (lokalizacja „podczas używania”), tło `fetch` i identyfikator zadania w tle `<bundle ID>.reminders-refresh`.
- `PrivacyInfo.xcprivacy`: bez śledzenia, bez zbieranych danych, `UserDefaults` z powodem `CA92.1`. Plik binarny nie odwołuje się do innych API z wymaganym powodem (`stat`, daty plików, `systemUptime`, wolne miejsce) ani do sieci (`URLSession`).
- Ikona: Liquid Glass (jasna, ciemna, barwiona) i 1024 px dla iOS 18; domyślna bez kanału alfa (inaczej upload odpada z ITMS-90717).
- W Release nie ma kodu z `PreviewSupport/` i `Prototypes/` (dublerów, seedów UI testów, `-uitest-reset`, `-SimulateMetricKitPayloads`) ani `print`.

Testy pilnują tego w `AppConfigurationTests`. Po każdej zmianie `Info.plist`, manifestu albo ikony sprawdź archiwum jeszcze raz (komenda na końcu).

## 1. Identyfikatory i podpisywanie

1. [developer.apple.com/account](https://developer.apple.com/account) → **Membership details**: zapisz **Team ID** (10 znaków).
2. Ustal **bundle ID** (pytanie z ticketu 017; dziś `com.michalbryk.cali-park`). Po pierwszym uploadzie nie da się go zmienić dla tej apki.
3. **Certificates, Identifiers & Profiles → Identifiers → +** → *App IDs* → *App* → Description „CaliPark”, *Explicit* bundle ID z punktu 2. **Capabilities: nic nie zaznaczaj.** iCloud i Sign in with Apple dopiero przy syncu i Społeczności, bo kontenera iCloud nie da się usunąć (ticket 009).
4. W Xcode: projekt → target **cali-park** → **Signing & Capabilities**: *Automatically manage signing* włączone, **Team** = Twój zespół, **Bundle Identifier** = nowy. Zrób to samo w targetach **cali-parkTests** i **cali-parkUITests** (`<bundle ID>Tests`, `<bundle ID>UITests`). `grep -n "DEVELOPMENT_TEAM\|PRODUCT_BUNDLE_IDENTIFIER" cali-park.xcodeproj/project.pbxproj` pokaże, czy zmieniło się wszędzie (6 konfiguracji).
5. Identyfikator zadania w tle zmienia się sam: `Info.plist` ma `$(PRODUCT_BUNDLE_IDENTIFIER).reminders-refresh`, a `AppRefreshScheduler.taskIdentifier` czyta bundle ID. Zostaje poprawić stary bundle ID w `docs/wayfinder/calipark-1.0/prototypes/park-submission/README.md`.
6. Build i testy (CLAUDE.md), commit na `main`.

## 2. Rekord apki w App Store Connect

[appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps → + → New App**:

| Pole | Wartość |
|---|---|
| Platforms | iOS |
| Name | CaliPark: kalistenika (Q39) |
| Primary Language | Polish |
| Bundle ID | z kroku 1 |
| SKU | `calipark-ios` (widzi tylko właściciel) |
| User Access | Full Access |

Potem w lewym menu:

**App Information**
- *Subtitle*: „Trening na drążku z planem”. Opis, tekst promocyjny i słowa kluczowe: z [app-store-listing.md](app-store-listing.md) (źródła w opisie tylko „r/bodyweightfitness i Overcoming Gravity” plus „inne uznane źródła”, wytyczna 2.3.7).
- *Category*: Primary **Health & Fitness**, Secondary **Sports** (opcjonalnie).
- *Content Rights*: **Yes, it contains third-party content and I have the necessary rights** (dane Parków z OSM na licencji ODbL).
- *Age Rating* → *Edit*: odpowiedzi z tabeli niżej.
- *Regulated Medical Device*: **No** (wymagane w UE, UK i USA przy kategorii Health & Fitness).
- *Digital Services Act*: dopiero przed App Store, TestFlight go nie wymaga (pytanie do właściciela w [app-review.md](app-review.md)).

**Age Rating** (kwestionariusz Apple; ticket 021: apka 16+)

| Pytanie | 1.0 z samym treningiem | 1.0 ze Społecznością |
|---|---|---|
| Health or Wellness Topics | **Yes** (plany, progresje) → 9+ | Yes |
| Medical or Treatment Information | No | No |
| User-Generated Content | No | **Yes** (opinie, zdjęcia, Zgłoszenia) |
| Messaging and Chat | No | **Yes** (publiczne opinie) |
| Social Media | No | No (bez polubień i feedu; feed v1.1 → Yes) |
| Shared Location | No | No (zdjęcia bez EXIF/GPS) |
| Unrestricted Web Access | No (linki do źródeł otwierają Safari) | No |
| Advertising, Contests, Gambling, Loot boxes | No | No |
| Dating and Relationships | No | No |
| Przemoc, seks, wulgaryzmy, alkohol, horror itd. | None | None |
| **Override** (*Age Rating Override*) | **16+** (decyzja 2026-11-04: od razu, żeby późniejsze podniesienie nie odcięło nikogo od aktualizacji) | **16+**, obowiązkowo (regulamin: Konto od 16 lat) |

**App Privacy**
- *Privacy Policy URL*: `https://<domena>/prywatnosc` (czeka na domenę, Q35).
- *Data Collection* → **No, we do not collect data from this app** → *Publish*. Uzasadnienie: [app-privacy.md](app-privacy.md).

**Pricing and Availability**
- *Price*: Free.
- *Availability*: tylko **Poland** (start w Polsce, ticket 001; poza tym amerykańskie prawa o weryfikacji wieku nas nie dotyczą).
- *iPhone and iPad Apps on Apple Silicon Mac*: odznacz. *Apple Vision Pro*: odznacz.

**Eksport (szyfrowanie)**: nic do klikania. `ITSAppUsesNonExemptEncryption = NO` w `Info.plist` odpowiada na to pytanie przy każdym buildzie.

## 3. Pierwsze archiwum i upload

1. Podbij numer kompilacji (sekcja „Wersje” niżej) i zrób commit.
2. Xcode → cel uruchomienia **Any iOS Device (arm64)** → **Product → Archive**.
3. Organizer → archiwum → **Distribute App** → **App Store Connect** → **Upload**. Zostaw *Upload symbols* włączone. *Manage Version and Build Number* **odznacz**, żeby numer w App Store Connect zgadzał się z commitem. Podpisywanie: automatyczne.
4. Po 10–30 minutach przychodzi mail „has completed processing”. Mail z „ITMS-…” to błąd albo ostrzeżenie: zapisz go w issue i popraw przed testerami.

## 4. TestFlight

**Grupa wewnętrzna** (bez recenzji Apple, tylko osoby z zespołu App Store Connect):
1. **TestFlight → Internal Testing → +** → nazwa „Właściciel” → dodaj siebie → włącz *Enable automatic distribution*.
2. Zainstaluj apkę **TestFlight** na iPhonie i przejdź trzy ścieżki: onboarding → Start, szybki trening → historia, plan z programu → Start. Do tego mapa Parków (zgoda na lokalizację) i przypomnienie w dniu z planu.

**Informacje o teście** (**TestFlight → Test Information**, wymagane przed grupą zewnętrzną):
- *Beta App Description* i *What to Test*: teksty z [app-store-listing.md](app-store-listing.md), sekcja TestFlight.
- *Feedback Email*: adres kontaktowy (Q36). *Marketing URL*: `https://<domena>/`. *Privacy Policy URL*: `https://<domena>/prywatnosc`.
- *Beta App Review Information*: imię, nazwisko, telefon i e-mail właściciela; **Sign-in required: odznaczone**.
- *Review Notes* (po angielsku, recenzenci czytają po angielsku):

  > CaliPark is a calisthenics training app in Polish. There is no login: every feature works without an account, and all data stays on the device (no server, no analytics). Suggested path: finish the short onboarding (level questions, a program, a weekly goal), tap "Rozpocznij" on Start to log a workout, then open "Ścieżki" for the progression ladders. The "Siłownie" tab shows outdoor bars from OpenStreetMap (bundled data); it asks for location only there, and works without it. Reminders are local notifications, requested when the user turns one on in a plan. Crash and performance reports (MetricKit) stay on the device and are sent only if the user mails them from Profil → "Pomoc i opinie".

**Grupa zewnętrzna** (Q40: tylko z zaproszeń mailowych):
1. **TestFlight → External Testing → +** → nazwa „Ekipa”.
2. **Builds → +** → wybierz build → uzupełnij *What to Test* → **Submit for Review**. Pierwszy build przechodzi Beta App Review (zwykle do 1–2 dni), kolejne zwykle już nie.
3. **Testers → +** → *Add New Testers* → e-maile ekipy. **Nie** włączaj *Public Link* (`testFlightURL` na stronie zostaje `null`).
4. Build wygasa po 90 dniach; testerzy dostają nowy, gdy wyślesz następny.

## 5. Co sprawdza recenzent

Beta App Review to ta sama lista wytycznych co App Store, tylko krótsza. Recenzent zwykle:
- uruchamia apkę na świeżym iPhonie (czasem na iPadzie w trybie zgodności): bez crasha, bez pustych ekranów i atrap;
- przechodzi onboarding i główne ścieżki bez logowania;
- odmawia zgody na lokalizację i na powiadomienia: apka ma dalej działać;
- porównuje opis, zrzuty i podtytuł z tym, co widzi (233 Parki, programy, cel tygodniowy);
- sprawdza linki: polityka prywatności, adres pomocy, e-mail do opinii muszą działać (dziś `kontakt@calipark.example` to placeholder, Q36);
- porównuje etykietę „Data Not Collected” z uprawnieniami i manifestem.

## Wersje i numery kompilacji

- Wszystkie targety mają `MARKETING_VERSION = 1.0` i `CURRENT_PROJECT_VERSION = 1` (sprawdzone 2026-11-04).
- **Wersja** (`MARKETING_VERSION`, „1.0”) to to, co widzi użytkownik; zmienia się przy wydaniu w App Store (1.0 → 1.0.1 → 1.1).
- **Kompilacja** (`CURRENT_PROJECT_VERSION`) to liczba całkowita, która rośnie o 1 przy **każdym** uploadzie i nigdy się nie zeruje, także przy nowej wersji (1.0 (1), 1.0 (2), … 1.1 (7)). App Store Connect odrzuca powtórzony numer.
- Pierwszy upload ma kompilację 1, jest już ustawiona. Przed każdym kolejnym (N = poprzedni + 1):

  ```sh
  sed -i '' 's/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = N;/' cali-park.xcodeproj/project.pbxproj
  git commit -am "Bump build to N"
  ```

  albo w Xcode: target → *General* → *Build*, we wszystkich trzech targetach. „O apce” pokazuje wersję i kompilację, więc w zgłoszeniu od testera widać, której dotyczy.

## Sprawdzenie archiwum bez konta

```sh
xcodebuild -project cali-park.xcodeproj -scheme cali-park -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$TMPDIR/CaliPark.xcarchive" \
  CODE_SIGNING_ALLOWED=NO archive
plutil -p "$TMPDIR/CaliPark.xcarchive/Products/Applications/cali-park.app/Info.plist"
xcrun nm -u "$TMPDIR/CaliPark.xcarchive/Products/Applications/cali-park.app/cali-park" \
  | grep -E "_stat|getattrlist|mach_absolute_time|systemUptime|statfs|volumeAvailable|URLSession"
```

Ostatnia komenda nie powinna nic wypisać. Jeśli coś wypisze, dopisz powód do `PrivacyInfo.xcprivacy` ([lista Apple](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)) albo zaktualizuj [app-privacy.md](app-privacy.md) i politykę.
