import type { Metadata } from "next";
import Link from "next/link";
import type { ReactNode } from "react";
import { ContactEmail, ProsePage } from "@/components/Prose";
import { site } from "@/content/site";

export const metadata: Metadata = {
  title: "Pomoc",
  description: "Najczęstsze pytania o CaliPark, testy w TestFlight i kontakt.",
  alternates: { canonical: "/pomoc" },
};

const faq: { q: string; a: ReactNode }[] = [
  {
    q: "Czy CaliPark jest darmowy?",
    a: <p>Tak. Trening w CaliPark jest darmowy, bez reklam i bez Konta.</p>,
  },
  {
    q: "Na jakich telefonach działa?",
    a: (
      <p>
        Na iPhonie z iOS 18.4 lub nowszym. Wersji na Androida na razie nie ma. Apka jest po polsku; inne języki dojdą
        później.
      </p>
    ),
  },
  {
    q: "Od czego zacząć?",
    a: (
      <>
        <p>
          Przy pierwszym uruchomieniu apka pyta, ile podciągnięć, pompek czy dipów robisz, i ustawia Cię na właściwych
          szczeblach. Potem proponuje gotowy program i cel tygodniowy.
        </p>
        <p>
          Źle oszacowałeś? W zakładce <em>Ścieżki</em> wybierz <em>Ustaw poziom</em> i popraw odpowiedzi.
        </p>
      </>
    ),
  },
  {
    q: "Skąd są kryteria na drabinach progresji?",
    a: (
      <p>
        Ze sprawdzonych źródeł kalistenicznych: Recommended Routine z r/bodyweightfitness, Overcoming Gravity
        Stevena Lowa, GMB, StartBodyweight i Cali Move. Przy każdym kryterium jest linia „Skąd to kryterium?”, a pełna
        lista źródeł jest w <em>Profil → O apce</em>.
      </p>
    ),
  },
  {
    q: "Gdzie są moje treningi? Jak przenieść je na nowy telefon?",
    a: (
      <>
        <p>
          Wszystko jest zapisane tylko na Twoim telefonie. Na nowy telefon przeniesiesz dane na dwa sposoby:
        </p>
        <ul>
          <li>
            w <em>Profil → Eksport i import treningów</em> zapisz plik, a na nowym telefonie go zaimportuj,
          </li>
          <li>albo przywróć nowy iPhone z kopii zapasowej iCloud lub z komputera.</li>
        </ul>
        <p>Usunięcie apki bez kopii lub eksportu usuwa treningi na zawsze.</p>
      </>
    ),
  },
  {
    q: "Nie widzę odległości do Parków.",
    a: (
      <p>
        Odległość wymaga dostępu do lokalizacji. Włączysz go w{" "}
        <em>Ustawienia → Prywatność i ochrona → Usługi lokalizacji → CaliPark</em> (opcja „Podczas używania apki”).
        Pozycja zostaje na telefonie.
      </p>
    ),
  },
  {
    q: "Na mapie brakuje mojego Parku.",
    a: (
      <p>
        Parki pochodzą z OpenStreetMap i muszą mieć tam zaznaczony drążek albo poręcze. Jak dodać albo poprawić
        miejsce, opisujemy na stronie <Link href="/dane#poprawki">Dane o Parkach</Link>.
      </p>
    ),
  },
  {
    q: "Nie przychodzą przypomnienia.",
    a: (
      <>
        <p>Sprawdź po kolei:</p>
        <ul>
          <li>
            czy przypomnienie jest włączone w planie, a powiadomienia w <em>Ustawienia → Powiadomienia → CaliPark</em>,
          </li>
          <li>czy to dzień z planu: przypomnienie przychodzi tylko w zaplanowane dni,</li>
          <li>czy plan nie jest już na dziś zrobiony: wtedy przypomnienie się nie pojawi.</li>
        </ul>
        <p>Jeśli długo nie otwierasz apki, otwórz ją na chwilę: dołoży przypomnienia na kolejne tygodnie.</p>
      </>
    ),
  },
  {
    q: "Czy CaliPark zbiera moje dane?",
    a: (
      <p>
        Nie. Wersja 1.0 nie ma serwera ani analityki, a lokalizacja nie opuszcza telefonu. Szczegóły są w{" "}
        <Link href="/prywatnosc">polityce prywatności</Link>.
      </p>
    ),
  },
];

export default function HelpPage() {
  return (
    <ProsePage
      title="Pomoc"
      lead="Odpowiedzi na najczęstsze pytania. Nie ma tu Twojego? Napisz do nas, odpisujemy na każdą wiadomość."
    >
      <h2 id="pytania">Najczęstsze pytania</h2>
      <div className="faq">
        {faq.map((item) => (
          <details key={item.q}>
            <summary>{item.q}</summary>
            <div>{item.a}</div>
          </details>
        ))}
      </div>

      <h2 id="testflight">Testy w TestFlight</h2>
      <p>
        Zanim CaliPark trafi do App Store, testujemy go z ekipą przez TestFlight, aplikację Apple do wersji testowych.
      </p>
      <ol>
        <li>
          Zainstaluj <a href="https://apps.apple.com/pl/app/testflight/id899247664">TestFlight</a> z App Store.
        </li>
        <li>
          {site.testFlightURL ? (
            <>
              Otwórz <a href={site.testFlightURL}>link do testów CaliPark</a> na iPhonie i stuknij „Akceptuj”.
            </>
          ) : (
            <>
              Napisz na <ContactEmail email={site.contactEmail} />, że chcesz testować. Wyślemy Ci zaproszenie na
              adres e-mail, którego używasz w Apple ID.
            </>
          )}
        </li>
        <li>Zainstaluj CaliPark z TestFlight i trenuj jak zwykle.</li>
      </ol>
      <p>
        <strong>Jak zgłosić błąd lub pomysł:</strong> zrób zrzut ekranu w apce, stuknij miniaturkę i wybierz
        „Udostępnij do wersji beta”. Opinia trafi do nas razem ze zrzutem. Możesz też otworzyć TestFlight i wybrać
        „Wyślij opinię o wersji beta”. Co widzimy jako twórcy, opisuje{" "}
        <Link href="/prywatnosc#testflight">polityka prywatności</Link>.
      </p>

      <h2 id="kontakt">Kontakt</h2>
      <p>
        Pytanie, błąd albo pomysł: <ContactEmail email={site.contactEmail} />. Z apki napiszesz przez{" "}
        <em>Profil → Pomoc i opinie → Napisz do nas</em>; wiadomość ma wtedy w temacie wersję apki.
      </p>
      <p className="muted">
        Piszesz z poczty? Dopisz wersję apki (<em>Profil → O apce</em>) i model iPhone’a, a szybciej znajdziemy
        przyczynę.
      </p>
    </ProsePage>
  );
}
