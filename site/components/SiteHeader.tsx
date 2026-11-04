import Link from "next/link";
import { ui } from "@/content/pl";
import { Wordmark } from "./Wordmark";

export function SiteHeader() {
  return (
    <header className="site-header">
      <div className="container site-header__inner">
        <Link href="/" className="site-header__brand" aria-label="CaliPark, strona główna">
          <Wordmark />
        </Link>
        <nav aria-label={ui.navLabel}>
          <ul className="site-nav">
            {ui.nav.map((item) => (
              <li key={item.href}>
                <Link href={item.href}>{item.label}</Link>
              </li>
            ))}
          </ul>
        </nav>
      </div>
    </header>
  );
}
