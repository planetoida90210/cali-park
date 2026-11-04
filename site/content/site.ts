// Site-wide facts in one place. Everything the owner must fill in before
// publishing is marked PLACEHOLDER; `grep -rn PLACEHOLDER site/` lists them.

/**
 * The public address of the site, used for canonical URLs, the sitemap and
 * Open Graph tags. Set NEXT_PUBLIC_SITE_URL in Vercel once the domain is
 * known. Without it, a Vercel build uses the project's production URL and a
 * local build uses localhost.
 */
export const SITE_URL = (
  process.env.NEXT_PUBLIC_SITE_URL ??
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : "http://localhost:3000")
).replace(/\/$/, "");

export const site = {
  name: "CaliPark",
  /** One line, used in the hero, the page title and Open Graph. */
  tagline: "Kalistenika z planem. Od pierwszego zwisu do muscle-upa.",
  description:
    "CaliPark to polska apka na iPhone’a do kalisteniki: drabiny progresji ze źródłami, gotowe programy, cel tygodniowy i mapa drążków z OpenStreetMap. Bez Konta, dane zostają na telefonie.",

  /** PLACEHOLDER: the data administrator's full name (privacy policy). */
  controllerName: "[IMIĘ I NAZWISKO]",
  /**
   * PLACEHOLDER: the contact address. The same address must replace
   * `SupportContact.email` in the app (cali-park/Features/Profile/Models/AboutContent.swift).
   */
  contactEmail: "[E-MAIL]",
  /** PLACEHOLDER: the public TestFlight link, once the beta is open. `null` hides the link. */
  testFlightURL: null as string | null,
  /** PLACEHOLDER: the App Store page, once the app is live. `null` shows "Wkrótce". */
  appStoreURL: null as string | null,

  repoURL: "https://github.com/planetoida90210/cali-park",
  dataURL: "https://github.com/planetoida90210/cali-park/tree/main/data",
  dataFileURL: "https://github.com/planetoida90210/cali-park/blob/main/data/parks-osm-pl.json",
  osmCopyrightURL: "https://www.openstreetmap.org/copyright",
  odblURL: "https://opendatacommons.org/licenses/odbl/1-0/",
} as const;

/** Whether the contact address is still the placeholder (shows a visible marker). */
export const contactIsPlaceholder = site.contactEmail.startsWith("[");

/** Facts about the bundled Parks snapshot, from data/parks-osm-pl.json. Update when the snapshot is rebuilt. */
export const parksSnapshot = {
  count: 233,
  osmDate: "4 listopada 2026",
  osmDateISO: "2026-11-04",
} as const;
