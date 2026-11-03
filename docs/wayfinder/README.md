# Wayfinder: lokalny tracker

Mapy wayfindera w tym repo żyją w Markdownie zamiast w issue trackerze. Ten plik opisuje, jak wykonywać operacje wayfindingu.

## Układ

```
docs/wayfinder/
├── <mapa>/
│   ├── MAP.md              mapa (odpowiednik issue z etykietą wayfinder:map)
│   └── tickets/NNN-slug.md  tickety, czyli dzieci mapy
└── research/               wyniki ticketów researchowych, linkowane z ticketów
```

Aktywna mapa: [calipark-1.0/MAP.md](calipark-1.0/MAP.md).

## Ticket

Każdy ticket to plik z frontmatterem:

```yaml
---
title: <nazwa ticketu, po niej się do niego odwołujemy>
type: research | prototype | grilling | task
mode: AFK | HITL
status: open | closed
assignee: <kto pracuje; puste = wolny>
blocked_by: [NNN, NNN]   # numery ticketów
---
```

Treść zaczyna się od `## Pytanie`. Rozstrzygnięcie dopisuje się na końcu jako `## Rozstrzygnięcie (RRRR-MM-DD)` i dopiero wtedy ustawia się `status: closed`.

## Operacje

- **Frontier:** tickety z `status: open`, pustym `assignee` i takim `blocked_by`, w którym wszystkie wymienione tickety są `closed`.
- **Claim:** zanim zaczniesz pracę, wpisz `assignee: planetoida90210` i zapisz plik.
- **Zamknięcie:** dopisz `## Rozstrzygnięcie`, ustaw `status: closed` i dodaj jedną linię do sekcji „Decyzje do tej pory” w `MAP.md`.
- **Poza zakresem:** ustaw `status: closed`, dopisz uzasadnienie i dodaj linię do sekcji „Poza zakresem” w `MAP.md`, a nie do decyzji.
- **Nowy ticket:** dodaj kolejny numer, a krawędzie `blocked_by` uzupełnij w drugim przejściu.
