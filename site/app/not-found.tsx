import Link from "next/link";

export default function NotFound() {
  return (
    <section className="container not-found">
      <h1>Nie ma takiej strony</h1>
      <p className="muted">Może link jest stary albo ma literówkę.</p>
      <p>
        <Link href="/">Wróć na stronę główną</Link>
      </p>
    </section>
  );
}
