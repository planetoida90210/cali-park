import Link from "next/link";
import type { ReactNode } from "react";
import { PhoneShot } from "@/components/PhoneShot";
import { parksSnapshot, site } from "@/content/site";

// Every claim on this page matches what the 1.0 build does (training only,
// no Account, no backend). Check the app before adding a feature here.

const icons = {
  lock: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="5" y="11" width="14" height="10" rx="2" />
      <path d="M8 11V8a4 4 0 0 1 8 0v3" />
    </svg>
  ),
  ladder: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M7 3v18M17 3v18M7 7h10M7 12h10M7 17h10" />
    </svg>
  ),
  list: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="5" y="4" width="14" height="17" rx="2" />
      <path d="M9 9h6M9 13h6M9 17h3" />
    </svg>
  ),
  target: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9" />
      <circle cx="12" cy="12" r="5" />
      <circle cx="12" cy="12" r="1" />
    </svg>
  ),
  pin: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.8 12 21 12 21z" />
      <circle cx="12" cy="9.5" r="2.5" />
    </svg>
  ),
  bell: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4l2-2zM10 20a2 2 0 0 0 4 0" />
    </svg>
  ),
} satisfies Record<string, ReactNode>;

const features: { icon: ReactNode; title: string; body: ReactNode[] }[] = [
  {
    icon: icons.lock,
    title: "Trening bez Konta",
    body: [
      "Nie zakładasz konta i nie podajesz e-maila. Treningi, plany i postępy zapisują się tylko na Twoim telefonie.",
      "Zmieniasz telefon? Eksportujesz wszystko do jednego pliku i wczytujesz go na nowym.",
    ],
  },
  {
    icon: icons.ladder,
    title: "Drabiny progresji ze źródłami",
    body: [
      "13 ścieżek: od zwisu na drążku do podciągnięć, od pompek przy ścianie do pseudo-planche, aż po front lever i stanie na rękach.",
      "Każdy szczebel ma jasne kryterium awansu, np. 3 × 8, i źródło: Recommended Routine, Overcoming Gravity, GMB i inne.",
    ],
  },
  {
    icon: icons.list,
    title: "Gotowe programy",
    body: [
      "Minimum, Fundamenty, Pierwsze podciągnięcie i Skille. Podgląd od razu pokazuje ćwiczenia na Twoim poziomie.",
      "Jednym stuknięciem robisz z programu własny plan i zmieniasz w nim, co chcesz.",
    ],
  },
  {
    icon: icons.target,
    title: "Cel tygodniowy",
    body: [
      "Wybierasz, ile dni w tygodniu trenujesz, ile treningów z planu robisz albo jaką objętość ćwiczenia chcesz zrobić.",
      "Pierścień pokazuje postęp, seria tygodni rośnie z każdym zaliczonym tygodniem. Urlop? Pauza do 90 dni nie zrywa serii.",
    ],
  },
  {
    icon: icons.pin,
    title: "Mapa Parków z OpenStreetMap",
    body: [
      `${parksSnapshot.count} miejsc w Polsce z drążkiem albo poręczami, z odległością od Ciebie i nawigacją w Mapach Apple.`,
      "Twoja pozycja służy tylko do pokazania mapy i odległości. Nie zapisujemy jej i nigdzie nie wysyłamy.",
    ],
  },
  {
    icon: icons.bell,
    title: "Przypomnienia i szybki zapis",
    body: [
      "Przypomnienie o treningu przychodzi tylko w dni z planu, i tylko wtedy, gdy plan nie jest jeszcze zrobiony.",
      "Serie zapisujesz kilkoma stuknięciami, a apka sama liczy XP, poziomy i awanse na drabinach.",
    ],
  },
];

const screens = [
  { src: "/screens/home.webp", alt: "Ekran Start: plan „Trening A” na dziś z przyciskiem Rozpocznij, pierścień celu tygodniowego 1 z 3 dni i seria 5 tygodni.", caption: "Start: plan na dziś i cel tygodniowy" },
  { src: "/screens/ladder.webp", alt: "Ścieżka Podciąganie: zaliczone szczeble od zwisu na drążku do podciągnięć z gumą, aktualny szczebel Podciągnięcia 3 × 8.", caption: "Drabina podciągnięć z kryteriami" },
  { src: "/screens/programs.webp", alt: "Lista gotowych programów: Minimum, Fundamenty, Pierwsze podciągnięcie i Skille, z czasem trwania i źródłem.", caption: "Gotowe programy ze źródłami" },
  { src: "/screens/parks-map.webp", alt: "Mapa Warszawy z pinezkami Parków do kalisteniki i atrybucją OpenStreetMap.", caption: "Mapa Parków z OSM" },
  { src: "/screens/park-card.webp", alt: "Karta Parku „Drążki · Mokotów”: 2,1 km od Ciebie, etykieta Z OSM i przycisk Nawiguj.", caption: "Karta Parku z nawigacją" },
  { src: "/screens/profile.webp", alt: "Profil: 16 treningów, seria 5 tygodni z celem, poziom 8, cel tygodniowy, historia oraz eksport i import treningów.", caption: "Profil, historia i eksport" },
];

export default function HomePage() {
  return (
    <>
      <section className="hero" aria-labelledby="hero-title">
        <div className="container hero__grid">
          <div>
            <span className="eyebrow">Apka na iPhone’a · po polsku</span>
            <h1 id="hero-title">
              Kalistenika z planem. <span className="accent">Krok po kroku.</span>
            </h1>
            <p className="hero__lead">
              CaliPark prowadzi Cię po drabinach progresji, od pierwszego zwisu do muscle-upa, podsuwa gotowy
              program na Twoim poziomie i pokazuje drążki w okolicy. Bez Konta, bez reklam.
            </p>
            <div className="actions">
              {site.appStoreURL ? (
                <a className="button button--primary" href={site.appStoreURL}>
                  Pobierz z App Store
                </a>
              ) : (
                <span className="button button--static" role="note">
                  Wkrótce w App Store
                </span>
              )}
              <Link className="button button--secondary" href="/pomoc#testflight">
                TestFlight dla ekipy
              </Link>
            </div>
            <p className="hero__note">Darmowa. Na iPhone’a z iOS 18.4 lub nowszym.</p>
          </div>
          <div className="hero__visual">
            <PhoneShot src="/screens/home.webp" alt={screens[0].alt} priority />
            <PhoneShot src="/screens/ladder.webp" alt={screens[1].alt} priority />
          </div>
        </div>
      </section>

      <section className="section" id="funkcje" aria-labelledby="funkcje-title">
        <div className="container">
          <div className="section__intro">
            <h2 id="funkcje-title">Co potrafi CaliPark</h2>
            <p>Wszystko, czego potrzebujesz, żeby trenować regularnie na drążku i poręczach. Nic ponad to.</p>
          </div>
          <ul className="features">
            {features.map((feature) => (
              <li className="feature" key={feature.title}>
                <div className="feature__icon" aria-hidden="true">
                  {feature.icon}
                </div>
                <h3>{feature.title}</h3>
                {feature.body.map((paragraph, index) => (
                  <p key={index}>{paragraph}</p>
                ))}
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section className="section" id="ekrany" aria-labelledby="ekrany-title">
        <div className="container">
          <div className="section__intro">
            <h2 id="ekrany-title">Tak wygląda apka</h2>
            <p>Zrzuty z wersji, którą testujemy na iPhonie.</p>
          </div>
          <div className="gallery" role="list" tabIndex={0} aria-label="Zrzuty ekranu, przewijane w poziomie">
            {screens.map((screen) => (
              <div role="listitem" key={screen.src}>
                <PhoneShot src={screen.src} alt={screen.alt} caption={screen.caption} />
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section" aria-labelledby="prywatnosc-title">
        <div className="container split">
          <div>
            <h2 id="prywatnosc-title">Twoje dane zostają u Ciebie</h2>
            <p className="muted">
              CaliPark w wersji 1.0 nie ma serwera. Nie wiemy, kiedy trenujesz ani gdzie jesteś, i tak ma zostać.
            </p>
            <p>
              <Link href="/prywatnosc">Przeczytaj politykę prywatności</Link>
            </p>
          </div>
          <div className="card">
            <ul className="checklist">
              <li>Bez Konta, bez logowania, bez e-maila.</li>
              <li>Bez analityki, reklam i śledzenia. Żadnych zewnętrznych SDK.</li>
              <li>Lokalizacja tylko na telefonie, nigdy nie zapisywana.</li>
              <li>Przypomnienia planuje sam iPhone, bez serwera.</li>
            </ul>
          </div>
        </div>
      </section>

      <section className="section" aria-labelledby="osm-title">
        <div className="container split">
          <div>
            <h2 id="osm-title">Mapa z otwartych danych</h2>
            <p className="muted">
              Parki pochodzą z OpenStreetMap, mapy tworzonej przez wolontariuszy. Zestaw, którego używa apka,
              udostępniamy dalej na tej samej licencji ODbL.
            </p>
            <p>
              <Link href="/dane">Skąd są dane o Parkach</Link>
            </p>
          </div>
          <div className="card">
            <p>
              Brakuje drążka w Twojej okolicy? Dodaj go w OpenStreetMap razem ze sprzętem (drążek, poręcze), a
              trafi do CaliPark przy kolejnej aktualizacji danych w apce.
            </p>
            <p className="muted">
              Dane OSM z {parksSnapshot.osmDate}. <a href={site.osmCopyrightURL}>© Współtwórcy OpenStreetMap</a>
            </p>
          </div>
        </div>
      </section>
    </>
  );
}
