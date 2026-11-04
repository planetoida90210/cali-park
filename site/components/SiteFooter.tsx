import Link from "next/link";
import { site } from "@/content/site";
import { ui } from "@/content/pl";
import { Wordmark } from "./Wordmark";

export function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="container site-footer__inner">
        <div className="site-footer__brand">
          <Wordmark />
          <p className="muted">Kalistenika na iPhone’a. Zrobione w Polsce.</p>
        </div>
        <nav aria-label={ui.footerNavLabel}>
          <ul className="footer-nav">
            <li><Link href="/prywatnosc">Polityka prywatności</Link></li>
            <li><Link href="/dane">Dane o Parkach</Link></li>
            <li><Link href="/pomoc">Pomoc i kontakt</Link></li>
            <li><a href={site.repoURL}>Kod na GitHubie</a></li>
          </ul>
        </nav>
        <div className="site-footer__legal">
          <p>
            Mapa Parków: <a href={site.osmCopyrightURL}>{ui.osmCredit}</a>.{" "}
            <Link href="/dane">{ui.dataLicence}</Link>.
          </p>
          <p className="muted">{ui.trademarks}</p>
          <p className="muted">© 2026 CaliPark</p>
        </div>
      </div>
    </footer>
  );
}
