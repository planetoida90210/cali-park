import type { Metadata } from "next";
import Link from "next/link";
import { ContactEmail, ProsePage } from "@/components/Prose";
import { site } from "@/content/site";

/*
 * Privacy policy for CaliPark 1.0: training only, no Account, no backend.
 *
 * Every statement was checked against the app code at 521b254 (2026-11-04):
 * - stores: StoreFile cases in cali-park/Core/Storage/StoreDirectory.swift,
 *   all under Application Support/CaliPark/ (JSONFileStore); UserDefaults
 *   keys in DefaultsKey.swift; no URLSession, no third-party SDK, no
 *   analytics, NSPrivacyTracking false and no collected data types in
 *   PrivacyInfo.xcprivacy;
 * - location: LocationProvider.swift (when-in-use, read on device, never
 *   stored), asked on the first Parks map open (ParkMapViewModel);
 * - map: MapKit `Map`; "Nawiguj" opens maps.apple.com with the Park's own
 *   coordinates (ParkFormat.appleMapsURL);
 * - reminders: UNUserNotificationCenter local notifications + a daily
 *   BGAppRefreshTask (NotificationCenterReminderScheduler.swift, Info.plist);
 * - export/import: Features/Backup (ShareLink / fileImporter, one JSON file);
 * - contact: mailto: link in HelpFeedbackView (SupportContact).
 * - "Diagnostyka" (MetricKit kept on the phone, sent only by the user's own
 *   e-mail): built by the W-diagnostics worker, NOT on main at 521b254.
 *   Re-check section "diagnostyka" against that code when it merges; if it
 *   does not ship in 1.0, delete the "Ekran Diagnostyka" subsection.
 *
 * MUST CHANGE BEFORE ANY BUILD WITH ACCOUNTS, COMMUNITY OR iCLOUD SYNC:
 * - "W skrócie", "Dane na telefonie", "Czego nie robimy": the app will then
 *   send data to a server (Account, reviews, photos, reports) or to the
 *   user's iCloud (CKSyncEngine). List every new data type, purpose, legal
 *   basis (art. 6(1)(b) contract for the Account, (f) for moderation/security),
 *   retention and deletion (Account deletion removes reviews and photos and
 *   revokes the Sign in with Apple token).
 * - add the processors (backend host, storage/CDN, e-mail, moderation API),
 *   their country, the art. 28 DPAs and transfer safeguards;
 * - add photos (EXIF/GPS stripped on device and on the server), the minimum
 *   Account age, DSA notices and moderation decisions, and link the
 *   regulamin (terms) once it exists;
 * - App Store "App Privacy" answers stop being "Data Not Collected"
 *   (docs/release/app-privacy.md) and PrivacyInfo.xcprivacy must list the
 *   collected types;
 * - bump the version and date below, and tell users in the app.
 */

export const metadata: Metadata = {
  title: "Polityka prywatności",
  description:
    "Jakie dane przetwarza CaliPark 1.0: trening bez Konta, wszystko na Twoim telefonie, lokalizacja nigdy nie zapisywana, bez analityki i śledzenia.",
  alternates: { canonical: "/prywatnosc" },
};

const POLICY_VERSION = "1.0";
const POLICY_DATE = "4 listopada 2026";

const sections = [
  ["administrator", "Kto odpowiada za Twoje dane"],
  ["na-telefonie", "Dane, które zostają na Twoim telefonie"],
  ["lokalizacja", "Lokalizacja i mapa"],
  ["przypomnienia", "Przypomnienia"],
  ["eksport", "Eksport i import treningów"],
  ["diagnostyka", "Raporty awarii i diagnostyka"],
  ["kontakt", "Kiedy do nas piszesz"],
  ["testflight", "Testy w TestFlight"],
  ["strona", "Ta strona internetowa"],
  ["czego-nie-robimy", "Czego nie robimy"],
  ["prawa", "Twoje prawa"],
  ["usuwanie", "Jak usunąć swoje dane"],
  ["zmiany", "Zmiany tej polityki"],
] as const;

export default function PrivacyPage() {
  return (
    <ProsePage
      title="Polityka prywatności"
      meta={
        <>
          Wersja {POLICY_VERSION} · obowiązuje od {POLICY_DATE} · dotyczy apki CaliPark 1.0 na iPhone’a i tej strony
        </>
      }
      lead="CaliPark 1.0 działa bez Konta i bez serwera. Twoje treningi zostają na Twoim telefonie, a my ich nie widzimy. Poniżej dokładnie opisujemy, co apka zapisuje, gdzie, i w jakich sytuacjach jakiekolwiek dane trafiają do nas."
    >
      <section className="summary" aria-labelledby="w-skrocie">
        <h2 id="w-skrocie">W skrócie</h2>
        <ul className="checklist">
          <li>Nie zakładasz Konta. Nie prosimy o imię, e-mail ani numer telefonu.</li>
          <li>Treningi, plany, postępy i ustawienia zapisują się tylko na Twoim telefonie. Nie wysyłamy ich na żaden serwer.</li>
          <li>Lokalizacji używamy tylko na telefonie, żeby pokazać mapę i odległość do Parków. Nie zapisujemy jej i nigdzie nie wysyłamy.</li>
          <li>Nie ma analityki, reklam, śledzenia ani zewnętrznych bibliotek (SDK).</li>
          <li>Dane dostajemy tylko wtedy, gdy sam nam je wyślesz: piszesz e-mail, wysyłasz raport albo opinię z TestFlight.</li>
        </ul>
      </section>

      <nav className="toc" aria-labelledby="spis-tresci">
        <h2 id="spis-tresci">Spis treści</h2>
        <ol>
          {sections.map(([id, label]) => (
            <li key={id}>
              <a href={`#${id}`}>{label}</a>
            </li>
          ))}
        </ol>
      </nav>

      <h2 id="administrator">1. Kto odpowiada za Twoje dane</h2>
      <p>
        Administratorem danych osobowych jest <mark className="placeholder">{site.controllerName}</mark>, twórca apki
        CaliPark (dalej „my”). W sprawach prywatności pisz na adres <ContactEmail email={site.contactEmail} />.
        Odpowiadamy najpóźniej w ciągu miesiąca.
      </p>
      <p>
        Ta polityka opisuje, jak przetwarzamy dane zgodnie z RODO (rozporządzenie UE 2016/679). Dotyczy apki CaliPark
        w wersji 1.0 oraz tej strony internetowej.
      </p>

      <h2 id="na-telefonie">2. Dane, które zostają na Twoim telefonie</h2>
      <p>
        Apka zapisuje poniższe dane w swoim prywatnym folderze na telefonie. Inne apki nie mają do niego dostępu, a my
        też go nie widzimy: CaliPark nie wysyła tych danych ani do nas, ani nikomu innemu.
      </p>
      <div className="table-wrap">
        <table>
          <caption className="muted" style={{ captionSide: "bottom", padding: "10px 16px", textAlign: "left" }}>
            Wszystkie te dane znikają z telefonu, gdy usuniesz apkę.
          </caption>
          <thead>
            <tr>
              <th scope="col">Co</th>
              <th scope="col">Po co</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Dziennik treningów: ćwiczenia, serie, powtórzenia, czas, ewentualny ciężar i notatka, data</td>
              <td>Historia, statystyki, XP, poziomy i awanse na drabinach progresji</td>
            </tr>
            <tr>
              <td>Plany treningowe: nazwa, ćwiczenia, dni, godzina przypomnienia</td>
              <td>Plan na dziś, przypomnienia</td>
            </tr>
            <tr>
              <td>Wynik testu poziomu i to, które awanse już świętowaliśmy</td>
              <td>Start na właściwym szczeblu, bez powtarzania celebracji</td>
            </tr>
            <tr>
              <td>Cel tygodniowy, jego wcześniejsze wersje i pauzy</td>
              <td>Pierścień celu i seria tygodni</td>
            </tr>
            <tr>
              <td>Ulubione ćwiczenia i ulubione Parki</td>
              <td>Szybszy wybór i filtr „Ulubione”</td>
            </tr>
            <tr>
              <td>Ustawienia: ukończone powitanie, układ modułów na ekranie Start, obejrzane podpowiedzi</td>
              <td>Żeby apka pamiętała Twój wybór</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p>
        <strong>Kopie zapasowe iPhone’a.</strong> Jeśli masz włączoną kopię zapasową iCloud albo robisz kopię na
        komputerze, iOS dołącza do niej dane apek, w tym CaliPark. Tę kopię prowadzi Apple na Twoim koncie (albo Twój
        komputer), na zasadach Apple. My nie mamy do niej dostępu.
      </p>
      <p>
        Apka nie korzysta z aplikacji Zdrowie (HealthKit) i nie odczytuje z telefonu żadnych innych danych.
      </p>

      <h2 id="lokalizacja">3. Lokalizacja i mapa</h2>
      <p>
        O dostęp do lokalizacji apka pyta dopiero wtedy, gdy pierwszy raz otworzysz mapę Parków, i tylko „podczas
        używania apki”. Gdy się zgodzisz, apka prosi telefon o Twoją pozycję z dokładnością ok. 100 m, żeby pokazać Cię na
        mapie, wyśrodkować ją i policzyć odległość do Parków.
      </p>
      <ul>
        <li>Pozycja jest używana tylko na telefonie. Nie zapisujemy jej i nie wysyłamy nam ani nikomu innemu.</li>
        <li>Gdy odmówisz, mapa działa dalej i pokazuje całą Polskę, tylko bez odległości.</li>
        <li>
          Zgodę zmienisz w każdej chwili: <em>Ustawienia → Prywatność i ochrona → Usługi lokalizacji → CaliPark</em>.
        </li>
      </ul>
      <p>
        <strong>Mapę rysuje Apple.</strong> Do wyświetlenia mapy apka używa map Apple (MapKit), więc iPhone pobiera
        fragmenty mapy z serwerów Apple, tak jak w aplikacji Mapy. Dotyczy tego{" "}
        <a href="https://www.apple.com/pl/legal/privacy/">polityka prywatności Apple</a>. Dane o Parkach są wbudowane w
        apkę i pochodzą z OpenStreetMap (<Link href="/dane">więcej o danych</Link>), więc wyszukiwanie Parków nie
        wysyła żadnych zapytań.
      </p>
      <p>
        <strong>Nawigacja.</strong> Gdy stukniesz „Nawiguj”, apka otwiera Mapy Apple ze współrzędnymi i nazwą wybranego
        Parku. Twojej pozycji nie przekazuje; trasę liczą już Mapy Apple. Linki „Skąd te dane” i źródła w „O apce”
        otwierają zwykłe strony internetowe (OpenStreetMap, źródła drabin) w przeglądarce.
      </p>

      <h2 id="przypomnienia">4. Przypomnienia</h2>
      <p>
        Przypomnienia o treningu to lokalne powiadomienia: planuje je sam iPhone, bez naszego serwera. O zgodę na
        powiadomienia apka pyta dopiero wtedy, gdy pierwszy raz włączysz przypomnienie w planie. Raz na dobę iOS może
        uruchomić apkę w tle, żeby dołożyć przypomnienia na kolejne dni; to też dzieje się tylko na telefonie.
        Powiadomienia wyłączysz w <em>Ustawienia → Powiadomienia → CaliPark</em>.
      </p>

      <h2 id="eksport">5. Eksport i import treningów</h2>
      <p>
        W Profilu możesz zapisać wszystkie dane z punktu 2 (bez ustawień) do jednego pliku{" "}
        <code>calipark-backup-RRRR-MM-DD.json</code>. Plik powstaje na telefonie, a Ty decydujesz, gdzie go wysłać lub
        zapisać (np. Pliki, AirDrop, poczta). Nie dostajemy go. Import wczytuje plik, który sam wybierzesz, i po Twoim
        potwierdzeniu zastępuje dane w apce. Pamiętaj, że plik zawiera całą Twoją historię treningów: przechowuj go
        jak każdy prywatny dokument.
      </p>

      <h2 id="diagnostyka">6. Raporty awarii i diagnostyka</h2>
      <h3>Raporty Apple</h3>
      <p>
        Jeśli w <em>Ustawienia → Prywatność i ochrona → Analityka i ulepszanie</em> masz włączone udostępnianie danych
        deweloperom apek, Apple przekazuje nam raporty awarii i dane o wydajności CaliPark: model telefonu, wersję iOS i
        apki oraz techniczny opis błędu. Apple nie przekazuje nam w nich Twojego imienia, adresu e-mail ani treści
        treningów. Używamy ich tylko do naprawiania błędów. Tę zgodę dajesz i wycofujesz w ustawieniach iPhone’a, na
        zasadach Apple.
      </p>
      {/* Depends on W-diagnostics (MetricKit). Remove this subsection if the screen does not ship in 1.0. */}
      <h3>Ekran „Diagnostyka”</h3>
      <p>
        iOS przekazuje apce raporty o awariach, zawieszeniach i wydajności (MetricKit). Apka trzyma je tylko na
        telefonie, przez ograniczony czas, i pokazuje w <em>Profil → Pomoc i opinie → Diagnostyka</em>. Możesz je tam
        przejrzeć i usunąć. Raport trafia do nas wyłącznie wtedy, gdy sam wybierzesz „Wyślij raport” i wyślesz
        wiadomość ze swojej poczty. Raport zawiera dane techniczne (wersja apki i iOS, model telefonu, opis błędu), bez
        Twoich treningów i lokalizacji. Wysłany raport traktujemy jak e-mail z punktu 7.
      </p>

      <h2 id="kontakt">7. Kiedy do nas piszesz</h2>
      <p>
        Gdy napiszesz do nas (np. z „Pomoc i opinie” w apce), dostajemy Twój adres e-mail, treść wiadomości i to, co do
        niej dołączysz. Temat wiadomości z apki zawiera wersję CaliPark, żebyśmy wiedzieli, której wersji dotyczy.
      </p>
      <ul>
        <li>
          <strong>Cel:</strong> odpowiedź, pomoc i poprawianie apki.
        </li>
        <li>
          <strong>Podstawa prawna:</strong> nasz prawnie uzasadniony interes w odpowiadaniu na wiadomości (art. 6 ust.
          1 lit. f RODO).
        </li>
        <li>
          <strong>Jak długo:</strong> do zamknięcia sprawy, a potem najwyżej 12 miesięcy, na wypadek gdybyś wrócił
          z tym samym tematem. Wcześniej usuniemy wiadomość na Twoją prośbę.
        </li>
        <li>
          <strong>Gdzie:</strong> w naszej skrzynce pocztowej. {/* PLACEHOLDER: name the e-mail provider once chosen, e.g. "u dostawcy poczty X (serwery w UE)". */}
        </li>
      </ul>

      <h2 id="testflight">8. Testy w TestFlight</h2>
      <p>
        Wersje testowe rozsyłamy przez TestFlight, usługę Apple. Jeśli testujesz CaliPark, Apple pokazuje nam:
      </p>
      <ul>
        <li>
          Twoje imię, nazwisko i adres e-mail, jeśli zaprosiliśmy Cię e-mailem (przy dołączeniu przez publiczny link
          jesteś dla nas anonimowy),
        </li>
        <li>status zaproszenia, wersję apki, model urządzenia, liczbę uruchomień i awarii,</li>
        <li>opinie i zrzuty ekranu, które sam wyślesz przez TestFlight.</li>
      </ul>
      <p>
        Używamy tych danych tylko do prowadzenia testów i poprawiania apki, na podstawie prawnie uzasadnionego interesu
        (art. 6 ust. 1 lit. f RODO). Przechowuje je Apple w App Store Connect; usuwamy testera, gdy kończy testy albo
        o to poprosi. Więcej: <a href="https://www.apple.com/pl/legal/privacy/">polityka prywatności Apple</a>.
      </p>

      <h2 id="strona">9. Ta strona internetowa</h2>
      <p>
        Strona nie używa ciasteczek, analityki ani narzędzi śledzących i nie ma formularzy. Hostuje ją Vercel Inc. Jak
        każdy serwer, przy wyświetleniu strony Vercel przetwarza dane techniczne: adres IP, datę i godzinę, adres
        strony i informacje o przeglądarce. Służą one tylko do dostarczenia strony i ochrony przed nadużyciami, a
        Vercel przechowuje je w logach przez krótki czas.
      </p>
      <p>
        Vercel działa dla nas jako podmiot przetwarzający (art. 28 RODO) na podstawie umowy powierzenia. Dane mogą
        trafić do USA; ich przekazanie opiera się na decyzji Komisji Europejskiej w sprawie EU-US Data Privacy Framework
        albo na standardowych klauzulach umownych. Podstawa prawna: nasz prawnie uzasadniony interes w bezpiecznym
        udostępnianiu strony (art. 6 ust. 1 lit. f RODO).
        {/* PLACEHOLDER: before publishing, confirm in the Vercel dashboard that the DPA is accepted and Web Analytics / Speed Insights stay OFF. */}
      </p>

      <h2 id="czego-nie-robimy">10. Czego nie robimy</h2>
      <ul className="checklist">
        <li>Nie sprzedajemy ani nie udostępniamy Twoich danych nikomu.</li>
        <li>Nie śledzimy Cię między apkami i stronami i nie pokazujemy reklam.</li>
        <li>Nie profilujemy Cię i nie podejmujemy wobec Ciebie zautomatyzowanych decyzji.</li>
        <li>Nie używamy zewnętrznych SDK do analityki, reklam ani raportów awarii.</li>
      </ul>

      <h2 id="prawa">11. Twoje prawa</h2>
      <p>
        Dane z punktu 2 masz w całości u siebie i sam nimi zarządzasz w apce. Wobec danych, które do nas trafiają
        (e-maile, raporty, dane z TestFlight), masz prawo:
      </p>
      <ul>
        <li>dostępu do danych i otrzymania ich kopii (art. 15 RODO),</li>
        <li>sprostowania danych (art. 16),</li>
        <li>usunięcia danych (art. 17),</li>
        <li>ograniczenia przetwarzania (art. 18),</li>
        <li>przeniesienia danych (art. 20),</li>
        <li>sprzeciwu wobec przetwarzania opartego na prawnie uzasadnionym interesie (art. 21).</li>
      </ul>
      <p>
        Napisz na <ContactEmail email={site.contactEmail} />, odpowiemy w ciągu miesiąca. Masz też prawo złożyć skargę
        do Prezesa Urzędu Ochrony Danych Osobowych (ul. Stawki 2, 00-193 Warszawa,{" "}
        <a href="https://uodo.gov.pl">uodo.gov.pl</a>).
      </p>
      <p>
        Podanie danych jest dobrowolne. Bez nich apka działa w pełni; nie możemy tylko odpowiedzieć na wiadomość, której
        nie dostaniemy.
      </p>

      <h2 id="usuwanie">12. Jak usunąć swoje dane</h2>
      <ul>
        <li>
          <strong>Wszystko w apce:</strong> usuń CaliPark z telefonu. iOS skasuje wtedy wszystkie dane apki i
          zaplanowane przypomnienia.
        </li>
        <li>
          <strong>Kopie zapasowe:</strong> kopią iCloud zarządzasz w <em>Ustawienia → [Twoje imię] → iCloud → Zarządzaj
          pamięcią</em>.
        </li>
        <li>
          <strong>Pliki eksportu:</strong> apka ich nie usuwa, bo zapisałeś je poza nią. Usuń je tam, gdzie je
          zapisałeś.
        </li>
        <li>
          <strong>To, co mamy my</strong> (e-maile, raporty, dane z TestFlight): napisz na{" "}
          <ContactEmail email={site.contactEmail} />.
        </li>
      </ul>

      <h2 id="zmiany">13. Zmiany tej polityki</h2>
      <p>
        Ta wersja dotyczy CaliPark 1.0, który działa bez Konta. Jeśli dodamy funkcje, które wysyłają dane poza telefon
        (np. Konto, Społeczność z opiniami o Parkach albo synchronizację przez iCloud), najpierw zaktualizujemy tę
        politykę i poinformujemy o tym w apce. Zawsze znajdziesz tu aktualną wersję z datą.
      </p>
    </ProsePage>
  );
}
