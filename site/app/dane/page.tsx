import type { Metadata } from "next";
import { ProsePage } from "@/components/Prose";
import { parksSnapshot, site } from "@/content/site";

// Facts from data/README.md and scripts/osm/README.md. Update `parksSnapshot`
// in content/site.ts whenever the snapshot is rebuilt.

export const metadata: Metadata = {
  title: "Dane o Parkach",
  description:
    "Parki w CaliPark pochodzą z OpenStreetMap. Udostępniamy cały zestaw danych na licencji ODbL.",
  alternates: { canonical: "/dane" },
};

export default function DataPage() {
  return (
    <ProsePage
      title="Dane o Parkach"
      meta={<>Dane OSM z {parksSnapshot.osmDate} · {parksSnapshot.count} Parków w Polsce</>}
      lead={
        <>
          Mapa Parków w CaliPark powstaje z danych{" "}
          <a href="https://www.openstreetmap.org">OpenStreetMap</a>, otwartej mapy świata tworzonej przez
          wolontariuszy. <a href={site.osmCopyrightURL}>© Współtwórcy OpenStreetMap</a>.
        </>
      }
    >
      <h2 id="co-to-jest-park">Co jest Parkiem</h2>
      <p>
        Park to publiczne miejsce na zewnątrz, gdzie w OpenStreetMap zaznaczono drążek, poręcze albo poręcze do dipów.
        Miejsca opisane tylko jako „street workout” bez takiego sprzętu, siłownie w budynkach, place zabaw i tereny
        prywatne nie trafiają na mapę. Kilka urządzeń stojących obok siebie łączymy w jeden Park.
      </p>
      <p>
        Nazwy bierzemy wyłącznie z OpenStreetMap. Gdy miejsce nie ma własnej nazwy, układamy ją z danych OSM: z nazwy
        parku, szkoły, ulicy albo dzielnicy w pobliżu, np. „Drążki · Mokotów” albo „Street workout · Park Jordana”.
      </p>

      <h2 id="co-zawieraja">Co zawierają dane</h2>
      <ul>
        <li>położenie i nazwę Parku oraz miasto i dzielnicę,</li>
        <li>sprzęt (drążek, poręcze, drabinki i inne) z liczbą sztuk, jeśli OSM ją podaje,</li>
        <li>nawierzchnię, oświetlenie, zadaszenie, dostęp i godziny otwarcia, jeśli są w OSM,</li>
        <li>odnośniki do elementów OpenStreetMap, z których powstał Park.</li>
      </ul>
      <p>
        Dane nie zawierają żadnych danych osobowych: pobieramy je bez informacji o autorach zmian w OSM. Nie ma w nich
        też opinii, ocen ani zdjęć.
      </p>

      <h2 id="pobierz">Pobierz dane</h2>
      <p>
        Ten sam zestaw, który jest wbudowany w apkę, udostępniamy publicznie w repozytorium CaliPark na GitHubie:
      </p>
      <ul>
        <li>
          <a href={site.dataURL}>folder <code>data/</code></a>: opis i tekst licencji,
        </li>
        <li>
          <a href={site.dataFileURL}>
            <code>parks-osm-pl.json</code>
          </a>
          : wszystkie Parki w formacie JSON.
        </li>
      </ul>
      <p>
        Możesz je kopiować, udostępniać i przerabiać na licencji{" "}
        <a href={site.odblURL}>Open Database License (ODbL) 1.0</a>. Warunki: podaj źródło (OpenStreetMap i CaliPark),
        a zmienioną bazę danych udostępniaj dalej na tej samej licencji.
      </p>

      <h2 id="aktualnosc">Jak często dane się zmieniają</h2>
      <p>
        Dane są wbudowane w apkę, więc lista Parków działa bez internetu (sama mapa potrzebuje sieci). Odświeżamy je z OpenStreetMap przy kolejnych wersjach
        apki. Datę danych zobaczysz w apce pod listą Parków i na karcie Parku, w sekcji „Skąd te dane”.
      </p>

      <h2 id="poprawki">Coś się nie zgadza?</h2>
      <p>
        Najszybciej poprawisz to u źródła. Załóż darmowe konto w OpenStreetMap i dodaj albo popraw miejsce, np. w
        edytorze <a href="https://www.openstreetmap.org/edit">iD</a>. Sprzęt opisuje się tagiem{" "}
        <code>fitness_station</code> (np. <code>horizontal_bar</code> dla drążka, <code>parallel_bars</code> dla
        poręczy). Poprawka trafi do CaliPark przy kolejnym odświeżeniu danych, a przy okazji skorzysta z niej każdy,
        kto używa OpenStreetMap.
      </p>
      <p>
        Mapę w apce rysuje Apple (MapKit); same dane o Parkach pochodzą tylko z OpenStreetMap i nie mieszamy ich z
        danymi z map Apple.
      </p>
    </ProsePage>
  );
}
