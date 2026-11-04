# OSM Park snapshot

`build_parks_snapshot.py` builds the Parks the app shows from OpenStreetMap. It
needs only Python 3 (standard library) and runs one Overpass query for Poland.

Output (same data in both files):

- `cali-park/Resources/Parks/parks-osm-pl.json`: compact, bundled in the app and read by `BundledParkDirectory`.
- `data/parks-osm-pl.json`: pretty-printed, the public ODbL dump (see `data/README.md`).

## Refresh

```sh
scripts/osm/build_parks_snapshot.py --raw-out /tmp/overpass-pl.json
```

- The query takes about 7 minutes on `overpass-api.de`. Run it once; don't loop or retry in a script. If the server is busy (HTTP 429/504), try again later by hand.
- `--raw-out` keeps the response, so you can tweak the rules and rebuild offline with `--raw-in /tmp/overpass-pl.json` without asking Overpass again.
- The script refuses to write an empty snapshot.
- Commit both output files together, then run the unit tests: `ParkDirectoryTests` checks the bundled file (count, Poland bounding box, Park evidence, unique IDs).

## Rules (ticket 012)

- **What is fetched:** inside Poland's border (`ISO3166-1=PL`), every element with `sport` containing `calisthenics`, or `fitness_station` naming a pull-up bar, parallel bars or dip bars (including `fitness_station:<type>=yes` and Polish words such as „drążek”, „poręcze”). Everything tagged `leisure=fitness_station` or `fitness_station` within 40 m is fetched too, to complete the equipment list.
- **Places:** elements are clustered like in the OSM research (areas within 10 m, a node within 15 m of an area, nodes within 40 m), so one Park is one pin.
- **What makes a Park:** a pull-up bar, parallel bars or dip bars (`horizontal_bar`, `parallel_bars`, `dip_bench`), or `sport=calisthenics`. Indoor gyms, playgrounds and `access=private/no` never count.
- **Equipment:** keys are OSM `fitness_station` values 1:1 (`EquipmentType` in the app). Machines (`air_walker`, `elliptical_trainer`… and any value outside the 012 table) are never listed; they only set `hasMachines`. Meaningless values (`yes`, `fitness_station`) and the ambiguous „drabinki” are ignored. `count` is set only when OSM maps two or more devices one by one.
- **Name:** the OSM `name`, unless it only repeats the feature type („Siłownia plenerowa”, „Street workout”…). Otherwise `generatedName`, built from OSM data only, never from MapKit:
  1. the named park or recreation ground the Park lies in or within 30 m: „Street workout · Park Jordana”,
  2. a named school within 30 m: „Drążki · przy SP 12”,
  3. the nearest named street within 15/30/50 m: „Poręcze · ul. Polna”,
  4. the district or town: „Street workout · Mokotów”.
  The prefix is „Drążki” (bar only), „Poręcze” (parallel or dip bars only) or „Street workout” (both, or equipment unknown). Context names longer than 32 characters are skipped.
- **Locality:** city from `admin_level` 8, else 7, else 6; district from `admin_level` 9 or 10.
- **ID:** UUIDv5 of `osm:<anchor ref>` (the largest Park area, else the first Park node). It stays the same between refreshes while the anchor element exists. Never change `PARK_ID_NAMESPACE`.

## Format

`schemaVersion` 1. Top level: `source`, `attribution`, `license`, `licenseURL`, `copyrightURL`, `osmDataTimestamp` (Overpass `timestamp_osm_base`), `generatedAt`, `parks`. Each Park carries the 012 Park facts: `id`, `status`, `verification`, `source`, `latitude`, `longitude`, `osmRefs`, `name`, `generatedName`, `locality {city, district}`, `equipment [{type, count}]`, `isCalisthenicsTagged`, `hasMachines`, `surface`, `lit`, `covered`, `access`, `openingHours`. No personal data: Overpass is queried without `meta`, so no user names, user IDs or changesets.
