// Polish UI strings shared by the layout. When an English version comes,
// add `content/en.ts` with the same shape and an `app/en/` tree that reuses
// the components (see README, "Adding /en").

export const ui = {
  lang: "pl",
  locale: "pl_PL",
  skipToContent: "Przejdź do treści",
  nav: [
    { href: "/#funkcje", label: "Funkcje" },
    { href: "/prywatnosc", label: "Prywatność" },
    { href: "/dane", label: "Dane o Parkach" },
    { href: "/pomoc", label: "Pomoc" },
  ],
  navLabel: "Główna nawigacja",
  footerNavLabel: "Stopka",
  osmCredit: "© Współtwórcy OpenStreetMap",
  dataLicence: "Dane Parków na licencji ODbL",
  trademarks: "Apple, iPhone, App Store i TestFlight są znakami towarowymi Apple Inc.",
} as const;

export type UI = typeof ui;
