#!/usr/bin/env python3
"""Build the bundled OpenStreetMap Park snapshot for Poland.

One Overpass query fetches every calisthenics place in Poland together with the
OSM context needed to name it (containing park, school, nearby street,
administrative areas). The script then applies the Park rules from
docs/wayfinder/calipark-1.0/proposals/012-park-model.md and writes:

  cali-park/Resources/Parks/parks-osm-pl.json   compact, bundled in the app
  data/parks-osm-pl.json                        same data, pretty-printed (ODbL dump)

Standard library only. See scripts/osm/README.md for how to refresh.

Usage:
  scripts/osm/build_parks_snapshot.py                       # query Overpass once
  scripts/osm/build_parks_snapshot.py --raw-out raw.json    # also keep the raw response
  scripts/osm/build_parks_snapshot.py --raw-in raw.json     # rebuild offline, no network
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
import urllib.parse
import urllib.request
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
USER_AGENT = "CaliPark-osm-snapshot/1.0 (+https://github.com/planetoida90210/cali-park)"

REPO_ROOT = Path(__file__).resolve().parents[2]
BUNDLE_OUT = REPO_ROOT / "cali-park" / "Resources" / "Parks" / "parks-osm-pl.json"
DUMP_OUT = REPO_ROOT / "data" / "parks-osm-pl.json"

# Park IDs are UUIDv5 of "osm:<ref>" in this namespace, so they stay the same
# between refreshes as long as the anchor OSM element stays. Never change it.
PARK_ID_NAMESPACE = uuid.UUID("6f2c1d0e-4b7a-5c3e-9a8d-2e1f0c7b5a49")

SCHEMA_VERSION = 1

# ---------------------------------------------------------------------------
# The query
# ---------------------------------------------------------------------------

# "core" = anything that may be Park evidence (sport=calisthenics included: it
# anchors the place and brings naming context, even though it no longer makes a
# Park on its own). Everything within 40 m of it with
# fitness tags is fetched as well, to complete the equipment list and to spot
# machines next to a Park. The foreach block emits naming context per core
# element, separated by `make ctx` marker elements.
#
# `around` always gets the elements together with their nodes (`.corex`, `.x`):
# on 2026-11-04 overpass-api.de returned nothing for `around` on a set of ways
# alone. The nodes lie on the ways, so this changes nothing where `around`
# works on ways.
QUERY = r"""
[out:json][timeout:600];
area["ISO3166-1"="PL"][admin_level=2]->.pl;
(
  nwr["sport"~"calisthenics"](area.pl);
  nwr["fitness_station"~"horizontal_bar|parallel_bars|dip|pull_?-?up|street_workout|calisthenics|multirig|drąż|poręcz",i](area.pl);
  nwr[~"^fitness_station:(horizontal_bar|parallel_bars|dip_bench)$"~"^yes$"](area.pl);
)->.core;
(.core; .core >>;)->.corex;
(
  nwr(around.corex:40)["leisure"="fitness_station"];
  nwr(around.corex:40)["fitness_station"];
)->.near;
make ctx kind="elements"; out;
(.core; .near;);
out tags bb;
foreach.core->.p(
  make ctx kind="begin", t=p.u(type()), i=p.u(id()); out;
  (.p; .p >>;)->.x;
  node.x->.pn;
  .pn is_in->.a;
  make ctx kind="areas"; out;
  (
    area.a["name"]["leisure"~"^(park|recreation_ground|garden)$"];
    area.a["name"]["landuse"="recreation_ground"];
    area.a["name"]["amenity"~"^(school|college|university)$"];
    area.a["name"]["boundary"="administrative"]["admin_level"~"^(6|7|8|9|10)$"];
  );
  out tags;
  make ctx kind="school"; out;
  nwr(around.x:30)["name"]["amenity"~"^(school|college|university)$"];
  out tags;
  make ctx kind="park"; out;
  nwr(around.x:30)["name"]["leisure"~"^(park|recreation_ground)$"];
  out tags;
  make ctx kind="street15"; out;
  way(around.x:15)["name"]["highway"];
  out tags;
  make ctx kind="street30"; out;
  way(around.x:30)["name"]["highway"];
  out tags;
  make ctx kind="street50"; out;
  way(around.x:50)["name"]["highway"];
  out tags;
);
"""

# ---------------------------------------------------------------------------
# Equipment taxonomy (012 §3). Keys are OSM fitness_station values.
# ---------------------------------------------------------------------------

CORE_EQUIPMENT = {"horizontal_bar", "parallel_bars", "dip_bench"}

PARK_EQUIPMENT = CORE_EQUIPMENT | {
    "rings", "horizontal_ladder", "wall_bars", "fitness_pole", "climbing_pole",
    "captains_chair", "push-up", "sit-up", "stretch_bars", "box", "balance_beam",
    "battling_ropes", "tire", "punching_bag",
}

# Aliases seen in Polish OSM data, normalised (lowercase, "_" and "-" kept).
EQUIPMENT_ALIASES = {
    "pull_up": "horizontal_bar", "pull-up": "horizontal_bar", "pullup": "horizontal_bar",
    "pull_up_bar": "horizontal_bar", "pull-up_bar": "horizontal_bar", "pullup_bar": "horizontal_bar",
    "chin_up": "horizontal_bar", "chin-up": "horizontal_bar", "high_bar": "horizontal_bar",
    "drążek": "horizontal_bar", "drążki": "horizontal_bar", "drazek": "horizontal_bar", "drazki": "horizontal_bar",
    "podciąganie": "horizontal_bar", "podciągania": "horizontal_bar",
    "parallel_bar": "parallel_bars", "poręcze": "parallel_bars", "poręcz": "parallel_bars", "porecze": "parallel_bars",
    "dip": "dip_bench", "dips": "dip_bench", "dip_bar": "dip_bench", "dip_bars": "dip_bench",
    "dip_station": "dip_bench", "dipbar": "dip_bench",
    "monkey_bars": "horizontal_ladder",
    "push_up": "push-up", "pushup": "push-up", "pompki": "push-up",
    "sit_up": "sit-up", "situp": "sit-up", "brzuszki": "sit-up",
    "stretching": "stretch_bars",
    "battle_ropes": "battling_ropes",
}

# Values that say "calisthenics place" without naming a device.
CALISTHENICS_VALUES = {"street_workout", "street_workout_park", "calisthenics", "multirig", "kalistenika"}

# Values that carry no information; never Park evidence and never a machine.
MEANINGLESS_VALUES = {
    "yes", "no", "fitness_station", "sign", "information_board", "board", "info",
    "siłownia_zewnętrzna", "siłownia_plenerowa", "outdoor_gym", "fitness",
    # Ambiguous Polish word: wall bars or a horizontal ladder (012 §3). Review only.
    "drabinki", "drabinka", "ladder",
}

# Indoor or private objects never make a Park, even when tagged calisthenics.
INDOOR_LEISURE = {"fitness_centre", "sports_centre", "sports_hall"}
CLOSED_ACCESS = {"private", "no"}

SURFACES = {
    "rubber", "tartan", "artificial_turf", "sand", "woodchips", "grass", "ground",
    "gravel", "paving_stones", "concrete", "asphalt",
}

# OSM names that only repeat the feature type. They are treated as "no name",
# so the place gets a generated name instead of hundreds of identical pins.
GENERIC_NAMES = {
    "siłownia plenerowa", "siłownia zewnętrzna", "siłownia pod chmurką", "street workout",
    "street workout park", "streetworkout", "workout park", "kalistenika", "park kalisteniczny",
    "plac do ćwiczeń", "strefa aktywności", "strefa street workout", "drążki", "poręcze",
    "siłownia", "outdoor gym", "calisthenics", "calisthenics park", "fitness",
    "plenerowa siłownia", "siłownia na świeżym powietrzu", "otwarta strefa aktywności",
    "mini siłownia", "drążek", "drążek podwójny", "poręcze gimnastyczne", "małpi gaj",
    "street workout zone", "park street workout", "street workout area", "workout",
}

# Context names (park, school, street) longer than this make the generated
# name unreadable on a pin card, so the next fallback is used instead.
CONTEXT_NAME_MAX_LENGTH = 32

# Only real streets name a Park; planned roads, platforms and paths do not.
STREET_HIGHWAYS = {
    "motorway", "trunk", "primary", "secondary", "tertiary", "unclassified", "residential",
    "living_street", "pedestrian", "service", "road",
}

SCHOOL_ABBREVIATIONS = {"SP", "ZS", "ZSO", "ZSP", "LO"}

NAME_MAX_LENGTH = 60


# ---------------------------------------------------------------------------
# Model
# ---------------------------------------------------------------------------

@dataclass
class Element:
    type: str
    id: int
    tags: dict
    lat: float
    lon: float
    bounds: tuple[float, float, float, float] | None = None  # minlat, minlon, maxlat, maxlon

    @property
    def ref(self) -> str:
        return f"{self.type[0]}{self.id}"

    @property
    def is_area(self) -> bool:
        return self.type in ("way", "relation")


@dataclass
class Context:
    areas: list[dict] = field(default_factory=list)
    schools: list[dict] = field(default_factory=list)
    parks: list[dict] = field(default_factory=list)
    streets: dict[int, list[dict]] = field(default_factory=dict)  # radius -> tags list


@dataclass
class Signals:
    equipment: set[str] = field(default_factory=set)
    calisthenics: bool = False
    machines: bool = False

    @property
    def has_core_equipment(self) -> bool:
        return bool(self.equipment & CORE_EQUIPMENT)

    @property
    def is_core(self) -> bool:
        """A Park candidate element: core equipment or the calisthenics tag.

        Candidates pick the anchor (so Park IDs stay stable) and the naming
        context. Only core equipment makes a Park (`is_park`)."""
        return self.has_core_equipment or self.calisthenics


# ---------------------------------------------------------------------------
# Tag interpretation
# ---------------------------------------------------------------------------

def split_values(raw: str) -> list[str]:
    parts = re.split(r"[;,]", raw)
    return [p.strip().lower().replace(" ", "_") for p in parts if p.strip()]


def equipment_key(value: str) -> str | None:
    value = value.strip("_")
    if value in PARK_EQUIPMENT:
        return value
    return EQUIPMENT_ALIASES.get(value)


def element_signals(tags: dict) -> Signals:
    signals = Signals()
    values: list[str] = []
    if "fitness_station" in tags:
        values += split_values(tags["fitness_station"])
    for key, val in tags.items():
        if key.startswith("fitness_station:") and val.lower() == "yes":
            values.append(key.split(":", 1)[1].lower())
    for value in values:
        key = equipment_key(value)
        if key:
            signals.equipment.add(key)
        elif value in CALISTHENICS_VALUES:
            signals.calisthenics = True
        elif value in MEANINGLESS_VALUES:
            continue
        else:
            # 012 §3: anything outside the Park table is treated as a machine.
            signals.machines = True
    sports = split_values(tags.get("sport", ""))
    if "calisthenics" in sports or "street_workout" in sports:
        signals.calisthenics = True
    return signals


def is_excluded(tags: dict) -> bool:
    if tags.get("leisure") in INDOOR_LEISURE or tags.get("amenity") == "gym":
        return True
    if tags.get("indoor") == "yes":
        return True
    if tags.get("playground"):
        return True
    return tags.get("access") in CLOSED_ACCESS


def tri_state(value: str | None) -> bool | None:
    if value is None:
        return None
    value = value.lower()
    if value in ("yes", "24/7", "automatic", "limited", "sunset-sunrise", "dusk-dawn"):
        return True
    if value == "no":
        return False
    return None


# ---------------------------------------------------------------------------
# Geometry
# ---------------------------------------------------------------------------

def distance_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6_371_000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = p2 - p1
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def expand(bounds, meters: float):
    minlat, minlon, maxlat, maxlon = bounds
    dlat = meters / 111_320.0
    dlon = meters / (111_320.0 * math.cos(math.radians((minlat + maxlat) / 2)))
    return (minlat - dlat, minlon - dlon, maxlat + dlat, maxlon + dlon)


def contains(bounds, lat: float, lon: float) -> bool:
    minlat, minlon, maxlat, maxlon = bounds
    return minlat <= lat <= maxlat and minlon <= lon <= maxlon


def overlaps(a, b) -> bool:
    return not (a[2] < b[0] or b[2] < a[0] or a[3] < b[1] or b[3] < a[1])


def same_place(a: Element, b: Element) -> bool:
    """Clustering rule from the OSM research (§1): areas within 10 m, a node
    within 15 m of an area, loose nodes within 40 m."""
    if a.is_area and b.is_area and a.bounds and b.bounds:
        return overlaps(expand(a.bounds, 10), b.bounds)
    if a.is_area and a.bounds and not b.is_area:
        return contains(expand(a.bounds, 15), b.lat, b.lon)
    if b.is_area and b.bounds and not a.is_area:
        return contains(expand(b.bounds, 15), a.lat, a.lon)
    return distance_m(a.lat, a.lon, b.lat, b.lon) <= 40


# ---------------------------------------------------------------------------
# Parsing the Overpass response
# ---------------------------------------------------------------------------

def parse_response(payload: dict) -> tuple[dict[str, Element], dict[str, Context], str]:
    elements: dict[str, Element] = {}
    contexts: dict[str, Context] = {}
    section = None
    current: Context | None = None
    for raw in payload.get("elements", []):
        if raw["type"] == "ctx":
            kind = raw["tags"]["kind"]
            if kind == "elements":
                section = "elements"
            elif kind == "begin":
                ref = f"{raw['tags']['t'][0]}{raw['tags']['i']}"
                current = contexts.setdefault(ref, Context())
                section = None
            else:
                section = kind
            continue
        tags = raw.get("tags", {})
        if section == "elements":
            if raw["type"] == "node":
                el = Element(raw["type"], raw["id"], tags, raw["lat"], raw["lon"])
            else:
                b = raw.get("bounds")
                if not b:
                    continue
                bounds = (b["minlat"], b["minlon"], b["maxlat"], b["maxlon"])
                el = Element(raw["type"], raw["id"], tags,
                             (bounds[0] + bounds[2]) / 2, (bounds[1] + bounds[3]) / 2, bounds)
            elements[el.ref] = el
        elif current is not None and section:
            if section == "areas":
                current.areas.append(tags)
            elif section == "school":
                current.schools.append(tags)
            elif section == "park":
                current.parks.append(tags)
            elif section.startswith("street"):
                current.streets.setdefault(int(section[6:]), []).append(tags)
    osm_base = payload.get("osm3s", {}).get("timestamp_osm_base", "")
    return elements, contexts, osm_base


# ---------------------------------------------------------------------------
# Naming (012 §4) — OSM data only, never MapKit
# ---------------------------------------------------------------------------

ROMAN_DISTRICT = re.compile(r"^Dzielnica\s+[IVXLC]+\s+", re.IGNORECASE)


def clean_name(name: str | None) -> str | None:
    if not name:
        return None
    name = " ".join(name.split())
    if name.lower() in GENERIC_NAMES or len(name) < 3:
        return None
    return name


def admin_name(tags: dict) -> str:
    name = tags["name"]
    name = re.sub(r"^(gmina|miasto|powiat)\s+", "", name, flags=re.IGNORECASE)
    return ROMAN_DISTRICT.sub("", name)


def locality(context: Context) -> tuple[str | None, str | None]:
    by_level: dict[int, str] = {}
    for tags in context.areas:
        if tags.get("boundary") == "administrative":
            try:
                level = int(tags.get("admin_level", ""))
            except ValueError:
                continue
            by_level.setdefault(level, admin_name(tags))
    city = by_level.get(8) or by_level.get(7) or by_level.get(6)
    district = by_level.get(9) or by_level.get(10)
    if district == city:
        district = None
    return city, district


def school_label(name: str) -> str | None:
    """'Szkoła Podstawowa nr 12 im. Jana Pawła II' -> 'przy SP 12'.

    "przy" needs the locative case, which only abbreviations survive, so other
    school names get no preposition. Returns None when the label is too long."""
    short = abbreviate_school(re.sub(r"\s+im(\.|ienia)\s.*$", "", name, flags=re.IGNORECASE))
    if short in SCHOOL_ABBREVIATIONS:
        # No number: keep the patron so "przy SP" is not ambiguous.
        short = abbreviate_school(name)
    label = f"przy {short}" if short.split(" ")[0] in SCHOOL_ABBREVIATIONS else short
    return label if len(label) <= CONTEXT_NAME_MAX_LENGTH else None


def abbreviate_school(name: str) -> str:
    s = name
    replacements = [
        (r"Szkoła Podstawowa", "SP"), (r"Zespół Szkół Ogólnokształcących", "ZSO"),
        (r"Zespół Szkolno-Przedszkolny", "ZSP"), (r"Zespół Szkół", "ZS"),
        (r"Liceum Ogólnokształcące", "LO"), (r"Technikum", "Technikum"),
        (r"Publiczna\s+", ""), (r"Niepubliczna\s+", ""),
    ]
    for pattern, repl in replacements:
        s = re.sub(pattern, repl, s, flags=re.IGNORECASE)
    s = re.sub(r"\bnr\.?\s*", "", s, flags=re.IGNORECASE)
    s = " ".join(s.split())
    return s


def street_label(name: str) -> str:
    lowered = name.lower()
    prefixes = ("ul.", "al.", "aleja", "aleje", "plac", "pl.", "rondo", "bulwar", "skwer", "osiedle", "os.", "most")
    if lowered.startswith(prefixes):
        return name
    return f"ul. {name}"


def short_enough(name: str | None) -> str | None:
    return name if name and len(name) <= CONTEXT_NAME_MAX_LENGTH else None


def prefix_for(equipment: set[str]) -> str:
    """'Drążki' (bar only), 'Poręcze' (parallel or dip bars only) or
    'Street workout' (both). Every Park has at least one of them (`is_park`)."""
    has_bar = "horizontal_bar" in equipment
    has_parallel = bool(equipment & {"parallel_bars", "dip_bench"})
    if not has_parallel:
        return "Drążki"
    if not has_bar:
        return "Poręcze"
    return "Street workout"


def generated_name(equipment: set[str], contexts: list[Context], city: str | None, district: str | None) -> str:
    prefix = prefix_for(equipment)

    def first(values):
        return next((v for v in values if v), None)

    park = first(short_enough(clean_name(t.get("name"))) for c in contexts for t in c.areas
                 if t.get("leisure") in ("park", "recreation_ground", "garden") or t.get("landuse") == "recreation_ground")
    if not park:
        park = first(short_enough(clean_name(t.get("name"))) for c in contexts for t in c.parks)
    if park:
        return f"{prefix} · {park}"
    schools = [t.get("name") for c in contexts for t in c.areas
               if t.get("amenity") in ("school", "college", "university")]
    schools += [t.get("name") for c in contexts for t in c.schools]
    school = first(school_label(n) for n in schools if clean_name(n))
    if school:
        return f"{prefix} · {school}"
    for radius in (15, 30, 50):
        street = first(short_enough(street_label(n)) for n in (
            clean_name(t.get("name")) for c in contexts for t in c.streets.get(radius, [])
            if t.get("highway") in STREET_HIGHWAYS) if n)
        if street:
            return f"{prefix} · {street}"
    place = district or city
    return f"{prefix} · {place}" if place else prefix


# ---------------------------------------------------------------------------
# Building places
# ---------------------------------------------------------------------------

class UnionFind:
    def __init__(self, n: int):
        self.parent = list(range(n))

    def find(self, i: int) -> int:
        while self.parent[i] != i:
            self.parent[i] = self.parent[self.parent[i]]
            i = self.parent[i]
        return i

    def union(self, a: int, b: int) -> None:
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.parent[max(ra, rb)] = min(ra, rb)


def cluster(elements: list[Element]) -> list[list[Element]]:
    uf = UnionFind(len(elements))
    # Grid bucketing keeps this near-linear: only compare neighbours.
    cell = 0.002  # ~ 220 m latitude, enough for 40 m links and most areas
    grid: dict[tuple[int, int], list[int]] = {}
    for i, el in enumerate(elements):
        grid.setdefault((int(el.lat // cell), int(el.lon // cell)), []).append(i)
    for i, a in enumerate(elements):
        gx, gy = int(a.lat // cell), int(a.lon // cell)
        reach = 1
        if a.bounds:
            span = max(a.bounds[2] - a.bounds[0], a.bounds[3] - a.bounds[1])
            reach = 1 + int(span // cell)
        for dx in range(-reach, reach + 1):
            for dy in range(-reach, reach + 1):
                for j in grid.get((gx + dx, gy + dy), []):
                    if j > i and same_place(a, elements[j]):
                        uf.union(i, j)
    groups: dict[int, list[Element]] = {}
    for i, el in enumerate(elements):
        groups.setdefault(uf.find(i), []).append(el)
    return list(groups.values())


def anchor(members: list[tuple[Element, Signals]]) -> Element:
    """The element that gives the Park its ID and position: the largest core
    area, else the first core node (by OSM ref, so it is stable)."""
    core = [el for el, s in members if s.is_core]
    areas = [el for el in core if el.bounds]
    if areas:
        def size(el: Element) -> float:
            b = el.bounds
            return (b[2] - b[0]) * (b[3] - b[1])
        return sorted(areas, key=lambda el: (-size(el), el.ref))[0]
    return sorted(core, key=lambda el: el.ref)[0]


def is_park(members: list[tuple[Element, Signals]]) -> bool:
    """012 with the owner's addendum (Q28): a Park needs a pull-up bar, parallel
    bars or dip bars in the data. `sport=calisthenics` alone is not a Park."""
    return any(s.has_core_equipment for _, s in members)


def build_parks(elements: dict[str, Element], contexts: dict[str, Context]) -> tuple[list[dict], int]:
    """The Parks, sorted by ID, and how many calisthenics-only places were left out."""
    usable = [el for el in elements.values() if not is_excluded(el.tags)]
    parks: list[dict] = []
    calisthenics_only = 0
    for group in cluster(usable):
        members = [(el, element_signals(el.tags)) for el in group]
        if not is_park(members):
            if any(s.is_core for _, s in members):
                calisthenics_only += 1
            continue
        main = anchor(members)
        core_refs = sorted({el.ref for el, s in members if s.is_core})
        equipment_counts: dict[str, int] = {}
        for el, s in members:
            for key in s.equipment:
                equipment_counts[key] = equipment_counts.get(key, 0) + 1
        equipment = [
            {"type": key, "count": count if count >= 2 and count_is_devices(members, key) else None}
            for key, count in sorted(equipment_counts.items(), key=lambda kv: equipment_order(kv[0]))
        ]
        group_contexts = [contexts[ref] for ref in core_refs if ref in contexts]
        city, district = None, None
        for ctx in group_contexts:
            city, district = locality(ctx)
            if city:
                break
        tag_sources = [main.tags] + [el.tags for el, _ in members if el is not main]
        name = next((n for n in (clean_name(t.get("name")) for t in tag_sources) if n), None)
        if name and len(name) > NAME_MAX_LENGTH:
            name = None
        surface = next((t["surface"] for t in tag_sources if t.get("surface") in SURFACES), None)
        lit = next((v for v in (tri_state(t.get("lit")) for t in tag_sources) if v is not None), None)
        covered = next((v for v in (tri_state(t.get("covered")) for t in tag_sources) if v is not None), None)
        access = "customers" if any(t.get("access") == "customers" for t in tag_sources) else "public"
        opening_hours = next((t["opening_hours"] for t in tag_sources if t.get("opening_hours")), None)
        parks.append({
            "id": str(uuid.uuid5(PARK_ID_NAMESPACE, f"osm:{main.ref}")),
            "status": "published",
            "verification": "osm",
            "source": "osm",
            "latitude": round(main.lat, 6),
            "longitude": round(main.lon, 6),
            "osmRefs": sorted({el.ref for el, _ in members}, key=ref_sort_key),
            "name": name,
            "generatedName": generated_name(set(equipment_counts), group_contexts, city, district),
            "locality": {"city": city, "district": district},
            "equipment": equipment,
            "isCalisthenicsTagged": any(s.calisthenics for _, s in members),
            "hasMachines": any(s.machines for _, s in members),
            "surface": surface,
            "lit": lit,
            "covered": covered,
            "access": access,
            "openingHours": opening_hours,
        })
    parks.sort(key=lambda p: p["id"])
    return parks, calisthenics_only


def count_is_devices(members, key: str) -> bool:
    """Only count separate device nodes; an area tag plus one node is one device."""
    return sum(1 for el, s in members if key in s.equipment and not el.is_area) >= 2


def equipment_order(key: str) -> tuple[int, str]:
    order = ["horizontal_bar", "parallel_bars", "dip_bench", "rings", "horizontal_ladder",
             "wall_bars", "fitness_pole", "climbing_pole"]
    return (order.index(key) if key in order else len(order), key)


def ref_sort_key(ref: str) -> tuple[str, int]:
    return (ref[0], int(ref[1:]))


# ---------------------------------------------------------------------------
# I/O
# ---------------------------------------------------------------------------

def fetch() -> dict:
    data = urllib.parse.urlencode({"data": QUERY}).encode()
    request = urllib.request.Request(OVERPASS_URL, data=data, headers={
        "User-Agent": USER_AGENT,
        "Accept": "application/json",
    })
    print("Querying Overpass once (this can take several minutes)…", file=sys.stderr)
    with urllib.request.urlopen(request, timeout=900) as response:
        return json.load(response)


def snapshot(parks: list[dict], osm_base: str) -> dict:
    return {
        "schemaVersion": SCHEMA_VERSION,
        "source": "OpenStreetMap",
        "attribution": "© OpenStreetMap contributors",
        "license": "ODbL-1.0",
        "licenseURL": "https://opendatacommons.org/licenses/odbl/1-0/",
        "copyrightURL": "https://www.openstreetmap.org/copyright",
        "osmDataTimestamp": osm_base,
        "generatedAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "parks": parks,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--raw-in", type=Path, help="read a saved Overpass response instead of querying")
    parser.add_argument("--raw-out", type=Path, help="save the raw Overpass response")
    args = parser.parse_args()

    if args.raw_in:
        payload = json.loads(args.raw_in.read_text())
    else:
        payload = fetch()
        if args.raw_out:
            args.raw_out.write_text(json.dumps(payload))
    if "remark" in payload:
        print(f"Overpass remark: {payload['remark']}", file=sys.stderr)
        if "error" in payload["remark"].lower() or "timed out" in payload["remark"].lower():
            return 1

    elements, contexts, osm_base = parse_response(payload)
    parks, calisthenics_only = build_parks(elements, contexts)
    if not parks:
        print("No Parks found; refusing to write an empty snapshot.", file=sys.stderr)
        return 1
    result = snapshot(parks, osm_base)

    BUNDLE_OUT.parent.mkdir(parents=True, exist_ok=True)
    DUMP_OUT.parent.mkdir(parents=True, exist_ok=True)
    BUNDLE_OUT.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")) + "\n")
    DUMP_OUT.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")

    named = sum(1 for p in parks if p["name"])
    no_city = sum(1 for p in parks if not p["locality"]["city"])
    print(f"OSM data: {osm_base}", file=sys.stderr)
    print(f"Parks: {len(parks)} (named {named}, without city {no_city}); "
          f"left out {calisthenics_only} places tagged only sport=calisthenics", file=sys.stderr)
    print(f"Wrote {BUNDLE_OUT.relative_to(REPO_ROOT)} and {DUMP_OUT.relative_to(REPO_ROOT)}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
