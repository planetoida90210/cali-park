---
title: Wygląd mapy parków
type: prototype
mode: HITL
status: closed
assignee: planetoida90210
blocked_by: []
---

# Wygląd mapy parków

## Pytanie

Jak ma wyglądać mapa, żeby była „stylowa”? Są dwie drogi:
- **MapKit:** natywny i darmowy. Pozwala wyciszyć styl mapy, mieć własne pinezki, grupowanie i ciemny motyw, ale ma ograniczony wpływ na kolory samej mapy.
- **Mapbox:** pełny własny styl mapy, ale to zewnętrzne SDK i płatność po darmowym limicie.

Prototyp: 2–3 warianty w SwiftUI na przykładowych pinezkach. Właściciel wybiera.

## Prototyp (2026-11-03)

Trzy warianty w MapKit na 25 zmyślonych Parkach w Warszawie. Opis i uruchomienie: [prototypes/map-look/README.md](../prototypes/map-look/README.md). Kod jest tylko w buildzie Debug (`cali-park/Prototypes/MapLook/`, argument `-PrototypeMapLook`). Ticket zostaje otwarty do wyboru właściciela.

- **A · Wyciszona:** ciemna, wyciszona mapa bez POI, ciemne pinezki z limonkowymi ikonami sprzętu, grupowanie, kompaktowa karta na dole. [Mapa](../prototypes/map-look/A1-wyciszona-mapa.png), [wybrany Park](../prototypes/map-look/A2-wyciszona-wybrany-park.png).
- **B · Sportowa:** satelita, duże neonowe pinezki, filtry sprzętu i karuzela kart zsynchronizowana z mapą (kamera 3D po wyborze Parku). [Mapa](../prototypes/map-look/B1-sportowa-mapa.png), [wybrany Park](../prototypes/map-look/B2-sportowa-wybrany-park.png).
- **C · Lista najpierw:** mała mapa na górze i lista najbliższych Parków z odległością i czasem dojścia. [Mapa](../prototypes/map-look/C1-lista-mapa.png), [wybrany Park](../prototypes/map-look/C2-lista-wybrany-park.png).
- [Ekran wyboru wariantu](../prototypes/map-look/00-picker.png).
- **Rekomendacja workera:** mix A + C (wyciszona mapa A jako domyślna, lista z C jako przełącznik). B wygląda efektownie, ale etykiety są gorzej czytelne i zużywa więcej baterii i danych. Zostajemy przy MapKit; Mapbox dopiero, jeśli po A nadal chcesz mapę w kolorach apki.
- Ikony sprzętu to tymczasowe SF Symbols. Docelowo potrzebne własne ikony drążka, poręczy, kółek i drabinek.

## Rozstrzygnięcie (2026-11-04)

**Wariant A „Wyciszona” na MapKit.** Właściciel: „pierwsza wersja najbardziej mi pasuje”. Wcześniej przyjął też listę najbliższych Parków z wariantu C jako przełącznik mapa/lista.

- Ciemna, wyciszona mapa bez POI, ciemne pinezki z limonkowymi ikonami sprzętu, grupowanie, kompaktowa karta wybranego Parku.
- Mapbox odrzucony na 1.0: zewnętrzne SDK i opłaty. Wracamy do niego tylko na życzenie właściciela.
- Do zrobienia przy implementacji: własne ikony sprzętu zamiast tymczasowych SF Symbols.
