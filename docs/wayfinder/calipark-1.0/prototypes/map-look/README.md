# Prototyp: wygląd mapy Parków

Ticket: [Wygląd mapy parków](../../tickets/011-map-look.md). Trzy warianty w MapKit dla SwiftUI, bez zewnętrznych SDK. Kod był jednorazowy i kompilował się tylko w buildzie Debug. Usunęliśmy go 2026-11-04, po wdrożeniu prawdziwej mapy Parków (wariant A, `cali-park/Features/Parks/`). Zrzuty zostają. Wszystkie 25 Parków i ich współrzędne są zmyślone. Pozycja „Tu jesteś” jest na sztywno przy Pałacu Kultury.

Każdy wariant ma dwa zrzuty: mapę na starcie i wybrany Park.

## A · Wyciszona

Stonowana ciemna mapa bez punktów POI. Własne pinezki z ikoną sprzętu, a sąsiednie Parki łączą się w kółko z liczbą. Po stuknięciu w pinezkę na dole pojawia się mała szklana karta Parku z przyciskiem „Prowadź”.

| Mapa | Wybrany Park |
| --- | --- |
| ![A, mapa](A1-wyciszona-mapa.png) | ![A, wybrany Park](A2-wyciszona-wybrany-park.png) |

## B · Sportowa

Zdjęcia satelitarne z nazwami ulic, duże neonowe pinezki i chipy filtrów sprzętu. Na dole jest karuzela kart: przesunięcie karty przelatuje kamerą nad Park w 3D, a stuknięcie w pinezkę przewija karuzelę.

| Mapa | Wybrany Park |
| --- | --- |
| ![B, mapa](B1-sportowa-mapa.png) | ![B, wybrany Park](B2-sportowa-wybrany-park.png) |

## C · Lista najpierw

Mała mapa u góry z wyraźnymi neonowymi kropkami, a pod nią lista najbliższych Parków z odległością i czasem dojścia. Stuknięcie w wiersz centruje mapę, a stuknięcie w kropkę przewija listę do Parku.

| Mapa | Wybrany Park |
| --- | --- |
| ![C, mapa](C1-lista-mapa.png) | ![C, wybrany Park](C2-lista-wybrany-park.png) |

## Kod prototypu

Prototyp był w `cali-park/Prototypes/MapLook/` i otwierał się argumentem `-PrototypeMapLook`. Kod usunęliśmy po wdrożeniu prawdziwej mapy Parków. Zmyślone Parki, grupowanie i kropka „Tu jesteś”, z których korzysta prototyp Zgłoszenia, są teraz w `cali-park/Prototypes/ParkSubmission/SubmissionSampleParks.swift`.

![Lista wariantów](00-picker.png)

## MapKit a Mapbox

MapKit pozwala wyciszyć mapę, przełączyć ją na satelitę, schować POI i narysować własne pinezki, ale nie pozwala zmienić kolorów ulic, wody czy zieleni. Mapbox dałby w pełni własny styl mapy, na przykład grafitowe ulice z limonkowymi akcentami w kolorach apki. Kosztem jest zewnętrzne SDK, konto i opłaty po przekroczeniu darmowego limitu.
