# Can OpenStreetMap seed the Park database for Poland?

Research date: 2026-11-03. OSM data snapshot: Geofabrik Poland extract with data up to **2026-11-02 21:21 UTC** ([Geofabrik Poland](https://download.geofabrik.de/europe/poland.html)). Every count below comes from that snapshot, and each count is exact for it. Note that the Geofabrik extract polygon reaches a little beyond the national border, so "Poland" counts from it include about 20 objects in neighbouring countries (see §2). Anything marked **(estimate)** is my own judgement, not a measured figure. Licence points quote the legal text or OSMF guidelines. This is not legal advice. A fact-check on the same evening re-ran the counts on live Overpass and re-implemented the clustering independently; see "Fact-check (2026-11-03)" at the end.

"Park" follows `GLOSSARY.md`: a public outdoor place with at least one pull-up bar or set of parallel bars. Machine-only outdoor gyms are not Parks.

## Answer

- **OSM can seed the Park database, but only a small, high-confidence core.** Poland has **9,224** `leisure=fitness_station` objects, which cluster into **7,501 places**. Only **334** of those places (4.5%) are tagged with a pull-up bar, parallel bars or `sport=calisthenics`. Another **59** are calisthenics by name only. That gives **393 seed Parks for all of Poland** and **108 in the five launch cities** (Warszawa 26, Kraków 23, Wrocław 16, Poznań 32, Gdańsk 11). The public Overpass servers were overloaded or stale while this research ran. These counts come from the 2026-11-02 Geofabrik extract, and the totals match Geofabrik's taginfo exactly. **Fact-check:** `overpass-api.de` was healthy by 19:55 UTC and the raw counts were re-run live. Inside Poland's border there are 9,206 `leisure=fitness_station` objects, and the five city totals match the extract to within 2 objects. An independent re-implementation of the clustering gave 385 A+B places inside the border (382–391 with other thresholds) and 107 in the five cities. Treat 393/108 as accurate to about ±2%.
- **92% of places (6,872) have no equipment detail.** OSM can't tell those apart from machine-only "siłownie plenerowe". Warsaw's standard municipal outdoor gym is six machines with no bar at all ([warszawa19115.pl](https://warszawa19115.pl/-/silownie-plenerowe)), so most of the unknowns are probably not Parks **(estimate)**. Treat them as unverified candidates, not as Parks.
- **Excluding machine-only gyms only works by equipment tags.** A place counts as a Park if any element has `fitness_station` ∋ `horizontal_bar`/`parallel_bars`/`dip_bench` or `sport` ∋ `calisthenics`. It counts as machine-only if it has only machine values such as `air_walker`, `elliptical_trainer` or `chest_press`. No OSM tag marks "outdoor gym without bars".
- **ODbL:** you must show "© OpenStreetMap" near the map. Mixing OSM parks with user-submitted parks of the same kind, or user corrections to OSM parks, creates a **Derivative Database**. CaliPark must then offer the Park-facts layer free under ODbL. Reviews, ratings and photos linked by park ID stay CaliPark's own, as a **Collective Database**. Contributing back to OSM is **optional, not required**.
- **The alternatives are not usable as seeds.** calisthenics-parks.com (925 Polish spots) and CaliBase grant no reuse rights. Google Places allows coordinates to be cached for at most 30 days. Under the EEA terms that apply to a Polish billing account, Places content other than latitude, longitude and place ID must not be used with any map. Polish municipal open data is patchy and mostly CC BY, which OSMF treats as incompatible with OSM without a waiver.
- **Recommendation:** a weekly OSM→Park pipeline from the Geofabrik extract (not Overpass). Publish only the 393 confirmed places after a quick review. Keep the 6,872 unknowns as hidden candidates. Accept an ODbL "Park facts" layer with a public dump, and keep Community content separate.

## Findings

### 1. How OSM tags calisthenics equipment

| Tag | What it means | Use for CaliPark |
|---|---|---|
| `leisure=fitness_station` | "An outdoor facility where people can practise typical fitness exercises". The wiki also calls it an outdoor gym, calisthenics park or trim trail. A station with several devices is drawn as an area, and each device can be its own node with `fitness_station=<type>`. A single device or a place with unknown extent gets one node ([wiki](https://wiki.openstreetmap.org/wiki/Tag:leisure%3Dfitness_station)). The Polish page allows either a node at the centre or an area outline, and recommends `sport=fitness`/`sport=exercise` ([pl wiki](https://wiki.openstreetmap.org/wiki/Pl:Tag:leisure%3Dfitness_station)). | Primary selector. On its own it says nothing about bars. |
| `fitness_station=*` | Equipment type, status "in use". The wiki lists about 60 values, including `horizontal_bar` (pull-up/muscle-up bar), `parallel_bars`, `dip_bench`, `rings`, `wall_bars`, `horizontal_ladder` and machines such as `air_walker`, `elliptical_trainer`, `rower`, `chest_press`, `leg_press` and `pull_down` ([wiki](https://wiki.openstreetmap.org/wiki/Key:fitness_station)). Several devices on one object: `fitness_station=a;b` or `fitness_station:<type>=yes` ([wiki](https://wiki.openstreetmap.org/wiki/Tag:leisure%3Dfitness_station)). | The only reliable way to tell a Park from a machine-only gym. |
| `sport=calisthenics` | "A form of strength training consisting of a variety of movements that use the body's own weight as resistance". The main use is on `leisure=fitness_station`, and it is also valid on `leisure=pitch` and others ([wiki](https://wiki.openstreetmap.org/wiki/Tag:sport%3Dcalisthenics)). | A strong Park signal even without equipment tags. |
| `sport=fitness` | Generic. In the Poland extract 6,735 of its 7,052 uses sit on `leisure=fitness_station` and 244 on indoor `leisure=fitness_centre` ([taginfo PL](https://taginfo.geofabrik.de/europe:poland/tags/sport=fitness)). Live Overpass inside the border on 2026-11-03: 7,034 / 6,720 / 243. | No signal. Drop indoor gyms. |
| `leisure=pitch` + `sport=fitness`/`calisthenics` | Rare in Poland: 21 and 4 objects. | Include with the sport check. |
| `playground=*` bars | Children's equipment (113 objects in PL). | Exclude. |
| `leisure=outdoor_gym`, `sport=street_workout`, `sport=workout` | Effectively unused in PL (0, 1 and 0). | Ignore. |

Real-world tagging is messier than the wiki. Poland has **120 distinct `fitness_station` values**. The most common is the meaningless `yes` (630), followed by `horizontal_bar` (210) and the equally meaningless `fitness_station` (152). There are free-text Polish values such as `siłownia_zewnętrzna`, `drabinki` and `brzuszki,_podciągania_,pompki,_drabinki`, plus comma-separated lists ([taginfo PL values](https://taginfo.geofabrik.de/europe:poland/keys/fitness_station#values)). A parser has to split on `;` and `,` and map the Polish words.

**Classification I used, which works as the Park rule:**

| Class | Rule (on any element of a clustered place) | Park? |
|---|---|---|
| A, confirmed | `fitness_station` (or `fitness_station:*=yes`) contains `horizontal_bar`, `parallel_bars`, `dip_bench`, `pull_up`, `street_workout(_park)`, `calisthenics`, `multirig` etc., **or** `sport` contains `calisthenics` | Yes |
| B, name only | No equipment tags, but `name`/`description` matches `street workout`, `kalisten…`, `calisthen…`, `workout`, `drąż…` or `poręcz…` | Yes after review |
| C, bar-like only | Only `horizontal_ladder`, `rings`, `wall_bars` or `captains_chair` | Owner decision (see open questions) |
| D, machines only | Only machine values (`air_walker`, `elliptical_trainer`, `rower`, `chest_press`, `leg_press`, `pull_down`, `twister`, `ski_swing`, `surfer`, `orbitrek` …) | No: the machine-only gym the glossary excludes |
| E, other only | Only `sit-up`, `push-up`, `balance_beam`, `stairs`, `hyperextension`, `sign` … | No |
| F, unknown | No equipment information at all | Unknown, so a candidate only |

To build a "place", I merged areas that touch or lie within 10 m of each other, attached each node within 15 m of an area to that area, and linked loose nodes in single-linkage clusters at 40 m. Indoor objects were dropped: `leisure=sports_centre/sports_hall/fitness_centre`, `amenity=gym`, `indoor=yes`. These thresholds are my own choice **(estimate)**.

### 2. Counts for Poland and the five cities

**Overpass status:** reachable but unusable on 2026-11-03 between about 19:25 and 19:50 UTC (the research script's last failure was at 19:49 UTC). It worked again from 19:55 UTC; see the fact-check table below.

- `overpass-api.de` returned HTTP 406 without a User-Agent, then repeatedly 502 "This Overpass API server is currently at capacity".
- `overpass.private.coffee` and `overpass.kumi.systems` mostly returned 504 `Dispatcher_Client::request_read_and_idx::timeout`. When `private.coffee` did answer, its database was stale (`timestamp_osm_base` 2026-07-24 to 07-28). The Poland count query hit "Query timed out … after 301 seconds", and a Kraków query by Wikidata area returned 0 for every selector, so the area lookup failed.
- `maps.mail.ru` returned 504. The numbers below therefore come from the Geofabrik PBF dated 2026-11-02, run through a pyosmium script. The Overpass wiki says to "use extracts if you need a lot of data" ([Overpass API wiki](https://wiki.openstreetmap.org/wiki/Overpass_API)). As a cross-check, my `leisure=fitness_station` totals (9,224 = 4,099 nodes + 5,097 ways + 28 relations) and my `fitness_station=*` total (1,869) match Geofabrik's taginfo exactly ([taginfo PL](https://taginfo.geofabrik.de/europe:poland/tags/leisure=fitness_station)). (The fact-check could not reach taginfo.geofabrik.de, which refused the connection. Its own re-count of the same PBF gives the same 9,224 and 1,869. The PBF's MD5 `7b405b7e…` matches Geofabrik's published `poland-261102.osm.pbf.md5`.)
- **Border buffer:** the Geofabrik extract polygon reaches beyond the national border. Clipped to Poland's boundary relation (r49715), the extract has **9,204** `leisure=fitness_station` objects (4,090 n / 5,086 w / 28 r) and 1,867 `fitness_station=*`. The "Poland" figures below are for the whole extract, so about 20 objects (and roughly 19 clustered places) lie in neighbouring countries. The import pipeline must clip to the border.

**Fact-check: live Overpass, 2026-11-03.** `overpass-api.de` answered normally from 19:55 UTC (`timestamp_osm_base` 2026-11-03T19:55:53Z, `timestamp_areas_base` 15:44Z). Results for Poland, using the first query block below plus the extra lines shown:

| Selector (inside `area["ISO3166-1"="PL"][admin_level=2]`) | Overpass 2026-11-03 | Extract 2026-11-02 (whole extract) |
|---|---|---|
| `nwr["leisure"="fitness_station"]` | **9,206** (4,090 / 5,088 / 28) | 9,224 (4,099 / 5,097 / 28) |
| `nwr["fitness_station"]` | 1,866 | 1,869 |
| `nwr["fitness_station"~"(^\|;)(horizontal_bar\|parallel_bars)(;\|$)"]` | 274 | n/a |
| `nwr["fitness_station"~"horizontal_bar"]` / `~"parallel_bars"` (value only, no `fitness_station:*` keys) | 224 / 64 | 224 / 64 (226–227 / 67 with `fitness_station:*=yes` keys) |
| `nwr["sport"~"calisthenics"]` | **177** (46 / 130 / 1) | 177 (5 of them indoor `leisure=fitness_centre`) |
| `nwr["leisure"="pitch"]["sport"~"fitness"]` | 20 | 21 |
| `nwr["sport"="fitness"]` | 7,034 | 7,052 |
| `nwr["leisure"="outdoor_gym"]` / `nwr["sport"="street_workout"]` / `nwr["sport"="workout"]` | 0 / 1 / 0 | 0 / 1 / 0 |
| `nwr["playground"~"horizontal_bar\|monkey_bars\|horizontal_ladder\|wall_bars\|rings\|parallel_bars"]` | 111 | 113 |

**Poland, raw tag counts:**

| Selector | Objects |
|---|---|
| `leisure=fitness_station` | **9,224** (4,099 nodes, 5,097 ways, 28 relations) |
| …of which have no `fitness_station=*` or `fitness_station:*` | **7,689 (83%)** |
| any `fitness_station=*` | 1,869 (of which 782 are just `yes`/`fitness_station`) |
| `fitness_station` ∋ `horizontal_bar` | 226 |
| `fitness_station` ∋ `parallel_bars` | 67 |
| `fitness_station` ∋ `rings`/`wall_bars`/`horizontal_ladder` | 125 |
| `sport` ∋ `calisthenics` | 177 raw (46 nodes, 130 ways, 1 relation). 172 remain after dropping 5 indoor `leisure=fitness_centre`, and 166 of those are on `leisure=fitness_station` (corrected by the fact-check: the original "172 (44/127/1)" was the outdoor-only figure, labelled as raw) |
| `leisure=pitch` + `sport` ∋ `fitness` / `calisthenics` | 21 / 4 |
| `name` matches street workout/kalistenika/drążek/poręcze | 152 |
| `playground` with bar-type values (excluded) | 113 |

**Poland, clustered places (7,501):**

| Class | Places | Share |
|---|---|---|
| A, confirmed calisthenics | **334** | 4.5% |
| B, calisthenics by name only | **59** | 0.8% |
| C, bar-like only | 62 | 0.8% |
| D, machines only | 97 | 1.3% |
| E, other equipment only | 77 | 1.0% |
| F, no equipment detail | **6,872** | 91.6% |

Of the 334 A places, 248 have explicit bar/parallel-bar equipment tags. The other 86 have only `sport=calisthenics`, so the app can't list their equipment. 48 also have machines (mixed parks), and 208 have a drawn area.

These place counts include roughly 19 places in the cross-border buffer. The fact-check re-implemented the clustering independently, with the same 10/15/40 m thresholds and its own classifier regexes. It gave 7,495 places (7,476 inside Poland's border), A 332, B 54, and A+B 385 inside the border; 247 of the A places have explicit bar tags and 85 only `sport=calisthenics`. With 5/10/25 m thresholds A+B was 390, and with 20/30/60 m it was 382. The headline therefore holds at about 385–393. The D/E split depends on which values count as "machines" and is less stable (fact-check: D 81, E 109).

**Five cities** (inside the admin boundary with the city's Wikidata ID):

| City (OSM relation) | `leisure=fitness_station` (n/w/r) | no equipment tag | ∋ `horizontal_bar` | ∋ `parallel_bars` | `sport`∋`calisthenics` | places | **A** | **B** | C | D | E | F |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warszawa ([r336074](https://www.openstreetmap.org/relation/336074)) | 503 (167/334/2) | 446 | 12 | 9 | 9 | 436 | **22** | **4** | 3 | 2 | 2 | 403 |
| Kraków ([r2768922](https://www.openstreetmap.org/relation/2768922)) | 262 (150/110/2) | 160 | 12 | 17 | 4 | 188 | **22** | **1** | 2 | 8 | 4 | 151 |
| Wrocław ([r2805691](https://www.openstreetmap.org/relation/2805691)) | 194 (30/162/2) | 182 | 7 | 6 | 6 | 181 | **14** | **2** | 4 | 0 | 0 | 161 |
| Poznań ([r2989158](https://www.openstreetmap.org/relation/2989158)) | 246 (123/119/4) | 178 | 18 | 1 | 32 | 188 | **31** | **1** | 0 | 10 | 3 | 143 |
| Gdańsk ([r2723259](https://www.openstreetmap.org/relation/2723259)) | 294 (146/148/0) | 252 | 5 | 1 | 4 | 262 | **9** | **2** | 0 | 0 | 0 | 251 |

Notes from the fact-check:
- **Live Overpass, 2026-11-03 19:58 UTC, same selectors.** The `leisure=fitness_station` totals match exactly for Warszawa (503), Wrocław (194), Poznań (246) and Gdańsk (294). Kraków is 264 (150/112/2), two ways added since the extract. The value-only `horizontal_bar`/`parallel_bars` counts match except Wrocław (6/4 vs 7/6, where the table also counts `fitness_station:*=yes` keys) and Kraków (`parallel_bars` 16 vs 17).
- **Indoor objects are excluded from the `sport`∋`calisthenics` column.** Raw Overpass counts are Warszawa 11 and Gdańsk 5, because 2 and 1 indoor `leisure=fitness_centre` objects respectively carry the tag.
- **The independent clustering gave A+B** Warszawa 26, Kraków 23, Wrocław 16, Poznań 31 and Gdańsk 11, which totals 107 against the table's 108.
- **Each Wikidata ID matches three boundary relations** (admin_level 6, 7 and 8, e.g. Warszawa r336074/r336075/r2907540), all with the same outline. The `area["wikidata"=…]["boundary"="administrative"]` query below therefore returns three areas per city, but the counts are unaffected.

**Queries to re-run when Overpass is healthy** (for example in overpass-turbo). They count the same selectors as above:

```overpassql
[out:json][timeout:300];
area["ISO3166-1"="PL"][admin_level=2]->.a;
// for a city use instead: area["wikidata"="Q31487"]["boundary"="administrative"]->.a;
// Warszawa Q270, Kraków Q31487, Wrocław Q1799, Poznań Q268, Gdańsk Q1792
nwr["leisure"="fitness_station"](area.a);out count;
nwr["fitness_station"~"(^|;)(horizontal_bar|parallel_bars)(;|$)"](area.a);out count;
nwr["sport"~"calisthenics"](area.a);out count;
nwr["leisure"="pitch"]["sport"~"fitness"](area.a);out count;
```

Candidate download for class A (show on a map with `out center tags`):

```overpassql
[out:json][timeout:300];
area["ISO3166-1"="PL"][admin_level=2]->.a;
(
  nwr["sport"~"calisthenics"]["leisure"!="fitness_centre"](area.a);
  nwr["fitness_station"~"horizontal_bar|parallel_bars|dip_bench"](area.a);
  nwr[~"^fitness_station:(horizontal_bar|parallel_bars|dip_bench)$"~"^yes$"](area.a);
);
out center tags;
```

**How this compares with calisthenics-parks.com:** it lists **925** spots in Poland ([countries page](https://calisthenics-parks.com/countries)). Its site-wide spot counter read 27,101 on the countries page and 27,115 in the [terms page header](https://calisthenics-parks.com/terms) on 2026-11-03, so the counter varies by page or cache. OSM's 393 confirmed places are about 42% of that figure. My guess is that Poland has around 1,000 or more places that meet the Park definition, and most of them sit in OSM's class F without equipment tags **(estimate)**.

### 3. Data quality

- **Equipment detail is mostly missing.** 83% of `leisure=fitness_station` objects carry no equipment tag, and 42% of the equipment values that do exist are `yes` or `fitness_station`. At place level, 91.6% are unknown. This is the dominant problem. Machine-only outdoor gyms are the Polish norm: Warsaw's "Warszawa w dobrej kondycji" standard is "wyciskacz, wahadło, biegacz, twister, orbitrek, wioślarz" ([warszawa19115.pl](https://warszawa19115.pl/-/silownie-plenerowe)). The national OSA programme also funds activity zones whose basic variant, according to municipal descriptions, is an outdoor gym plus a relaxation zone (e.g. [pzpc.pl](https://pzpc.pl/aktualnosci/wiadomosci/6212/mionisterialna-osa-czyli-otwarte-strefy-aktywnosci-w-ramach-projektu-msit-proponuje-plenerowe-silownie)). The [gov.pl OSA page](https://www.gov.pl/web/sport/program-otwartych-stref-aktywnosci-osa-) itself only mentions a "minimalny zakres rzeczowy (wariant podstawowy lub rozszerzony)" and lists "street workout park/kalistenika" as an optional extra. The official programme rules were not checked, so the outdoor-gym core is **(unverified against the primary source)**. The unknowns are therefore not a neutral sample.
- **Nodes and areas are mixed.** 4,787 places have a drawn area and 2,714 are points only. 2,376 of the point-only places are a **single node**, so they have no extent and often no equipment detail. Wrocław is mostly areas (162 ways vs 30 nodes) and Kraków mostly nodes (150 vs 110), so mapping style varies by city.
- **Duplicates and overlaps exist.** 232 places contain more than one area, for example a `leisure=pitch` plus a `leisure=fitness_station` outline, or two overlapping outlines. 185 "summary" nodes (`leisure=fitness_station` without equipment) sit inside an area that already represents the place. Without clustering, one park would show as several pins. Equipment nodes also carry `leisure=fitness_station` themselves, so raw counts overstate places by about 20% (9,224 objects vs 7,501 places).
- **Attributes are sparse.** Across all places: `name` 434 (5.8%), `opening_hours` 413, `surface` 315, `lit` 276, `operator` 58. 115 places are marked `access` private/customers/permit. Among A places, 119 of 334 have a name, so the app needs a fallback title such as "Park street workout, <street/district>".
- **Freshness is mixed.** By the last edit of any element, 1,171 places (15.6%) were last touched in 2020 or earlier, and 3,675 (49%) in 2024–2026. A recent edit is not proof of a survey (it can be a tag clean-up).
- **IDs are not stable.** OSM element IDs change when a mapper turns a node into an area or splits and merges objects. The wiki notes that "a restaurant node POI may become a building or a relation" ([Permanent ID](https://wiki.openstreetmap.org/wiki/Permanent_ID)). CaliPark needs its own stable Park ID and must treat the OSM reference as a mutable link.

### 4. ODbL obligations

OSM data is under the ODbL 1.0 ([copyright](https://www.openstreetmap.org/copyright)). The definitions that matter, quoted from the [licence text](https://opendatacommons.org/licenses/odbl/1-0/):

- **Derivative Database:** "a database based upon the Database, and includes any translation, adaptation, arrangement, modification, or any other alteration of the Database or of a Substantial part of the Contents."
- **Collective Database:** "this Database in unmodified form as part of a collection of independent databases… A work that constitutes a Collective Database will not be considered a Derivative Database."
- **Produced Work:** "a work (such as an image, audiovisual material, text, or sounds) resulting from using the whole or a Substantial part of the Contents (via a search or other query)".
- **Substantial:** the OSMF guideline treats fewer than 100 features, one-off, as insubstantial. "Repeated small extractions" count as one big one, and a systematic extract of all of one kind of feature in an area counts as systematic ([Substantial guideline](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Substantial_-_Guideline)). 393 parks, refreshed weekly, is clearly Substantial.

#### 4.1 Attribution (always required)

- ODbL 4.3: a publicly used Produced Work needs a notice "reasonably calculated to make any Person … aware that Content was obtained from the Database … and that it is available under this License".
- OSMF safe harbour ([Attribution Guidelines](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines), adopted 2021-06-25):
  - Attribution "must be to 'OpenStreetMap'". The historical forms "© OpenStreetMap contributors" and "© OpenStreetMap" are acceptable.
  - It "must also make it clear that the data is available under the Open Database License". The suggested way is to make "OpenStreetMap" a link to `openstreetmap.org/copyright`. If the credit itself can't link, the link must sit in an easy-to-find place such as a "Data licences" menu entry.
  - For interactive maps, the credit "should typically appear in a corner of the map". It may also go adjacent to the map, or on a splash screen or pop-up at app start.
  - The credit may collapse on a dismiss interaction, on map interaction (pan, click, zoom), or after five seconds, as long as an "(i)" button or About entry still leads to the licence.
  - The guideline prefers attribution "only for those areas or features that actually contain OpenStreetMap data".
- **For CaliPark:**
  - The base map is Apple MapKit (`Features/Parks/Views/MapSheetView.swift`), and Apple's "Legal" label does not cover OSM pins. Put a small "© OpenStreetMap" link in another map corner whenever OSM-sourced Parks are visible.
  - Add "Źródło: OpenStreetMap (ODbL)" on park detail screens for OSM-sourced parks.
  - Add a "Licencje danych" entry in Settings.
- **Database distribution (API or dump):** include attribution and the ODbL text or link in the data or a README (ODbL 4.2 and the guideline's "Databases" section).

#### 4.2 Is CaliPark a Produced Work or a Derivative Database?

- The rendered map is a Produced Work. The backend Park table that the app downloads as JSON is a database, though. The guideline says that if a result "is intended for the extraction of the original data, then it is a database and not a Produced Work" ([Produced Work guideline](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Produced_Work_-_Guideline)).
- Calling the app a Produced Work also doesn't avoid the obligation. ODbL 4.6 applies to "a Derivative Database **or a Produced Work from a Derivative Database**". 4.4c says a Derivative Database "is Publicly Used … if a Produced Work created from the Derivative Database is Publicly Used".
- **Pure OSM, only filtered and reformatted** (classes A–B straight from OSM, no human edits) is a "trivial transformation". The obligation is then only to tell users where to get the OSM data ([Trivial Transformations](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Trivial_Transformations_-_Guideline); the page itself says it is still at "proposal stage").

#### 4.3 Mixing OSM parks with user-submitted Parks

The two guidelines that decide this:

- **Horizontal Layers** ([guideline](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Horizontal_Map_Layers_-_Guideline), endorsed 2014-06-06):
  - "If you use OpenStreetMap data along with non-OpenStreetMap data for a given Feature Type, then the share-alike condition would apply."
  - Adding your own restaurants "only those … not present in the OpenStreetMap layer" means the layers "are interacting and the restaurants added in your non-OpenStreetMap layer must be shared".
  - "If you improve data used in the OpenStreetMap layer, such as additions or factual corrections, then you need to share those improvements."
- **Collective Database** ([guideline](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Collective_Database_Guideline_Guideline), endorsed 2016-06-17):
  - Data stays independent if, for a data type, it is "either all OSM or all non-OSM within the same regional cut". A regional cut must be at least a country ([Regional Cuts](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Regional_Cuts_-_Guideline)).
  - Non-OSM data may reference OSM features by database key without triggering share-alike. Its example: your own phone numbers joined to OSM restaurants.
  - "Complementing" a proprietary list with OSM data and "removing any duplicate objects" is **not** covered, and may make the proprietary data subject to share-alike.

What this means for each kind of CaliPark data, with Poland as the regional cut:

| CaliPark data | Share-alike (ODbL)? | Why |
|---|---|---|
| Park location/outline, name, "exists", from OSM | Yes (it is OSM data) | ODbL 4.4 |
| User-submitted new Parks, deduplicated against OSM Parks | **Yes** | Same feature type mixed and complementing (Horizontal Layers; Collective DB dedupe example) |
| User corrections to OSM Parks (moved pin, "no bars here", closed) | **Yes** | "additions or factual corrections … need to share" |
| Equipment list | **Yes if mixed** (OSM `fitness_station` where present, users elsewhere). **No** only if every Polish park's equipment came from CaliPark users and none from OSM | Collective DB property rule ("all OSM data or no OSM data for that property") |
| Reviews, star ratings, photos, check-ins keyed by CaliPark park ID | **No** (Collective Database) | OSM has no such data type, and these records contain no OSM data. Photos are also the users' copyright, so they need their own licence grant in the ToS |
| Accounts, training data | No | Unrelated |

If CaliPark wants zero share-alike, it can't use OSM for Parks at all in Poland. The FAQ allows comparing OSM with your own data: "you can compare but not take". Any change has to come "from your own physical observation" or a non-OSM source ([Legal FAQ §4](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ)). That is impractical for hundreds of parks.

#### 4.4 What share-alike requires in practice

- **Offer the Park-facts database.** ODbL 4.6 requires offering "the entire Derivative Database" **or** "a file containing all of the alterations … including any additional Contents". The copy must be machine-readable and "free of charge if distributed over the internet". In practice: a public GeoJSON or CSV of Park facts (location, name, equipment, status, source), updated on a schedule, linked from "Licencje danych". This is my suggested form, not something the licence prescribes.
- **No restrictive terms on that layer** (4.7a). You may rate-limit or authenticate the API only if an unrestricted copy is just as accessible (4.7b), and authentication is allowed if it doesn't restrict licence rights (4.7c). The app ToS must not forbid reuse of Park facts.
- **User-submitted Park facts need an ODbL-compatible grant.** 4.4d says you "must not add Contents to Derivative Databases … that are incompatible". The ToS must license users' park facts to CaliPark so they can be released under ODbL, and so CaliPark could also contribute them to OSM.
- **Charging is still allowed:** "You can charge any amount of money … However … other people may then redistribute this without payment" ([Legal FAQ §1.9](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ)). A paywall for *contributing* (submitting parks, posting reviews) is unaffected. A paywall on *reading* the Park layer would need the free parallel copy.
- **Internal use is exempt** (4.5c). A private analysis like this one triggers nothing.

#### 4.5 Contributing user submissions back to OSM: must, could, how

- **Must? No.** "Do you have to share your changes … back to the community? … we obviously prefer it … but you do not have to, as long as you comply with the above" ([Legal FAQ §1.7.1](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ)). The ODbL offer in 4.4 is the obligation, not an upload to OSM.
- **Could? Yes, if:**
  - **Rights are in place.** The uploader indicates "You have the right to authorize OSMF to use and distribute those Contents" ([Contributor Terms 1.2.4 §1(a)](https://osmfoundation.org/wiki/Licence/Contributor_Terms)). Data already under ODbL may be imported ([FAQ §2.1.4](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ)), which is one more reason to take an ODbL grant in the ToS.
  - **Nothing comes from Google.** "Can I copy data from Google? No!" ([FAQ §2.1.5](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ)). User submissions need on-site evidence such as a photo and GPS position.
  - **Community process is followed.** A bulk or systematic upload is an import. It needs a wiki page, discussion with the local community, a review post with `import` tags on the Community Forum, and a dedicated `<username>_Import` account ([Import/Guidelines](https://wiki.openstreetmap.org/wiki/Import/Guidelines)). If CaliPark coordinates several people, the [Organised Editing Guidelines](https://osmfoundation.org/wiki/Organised_Editing_Guidelines) also apply: a wiki page, a changeset hashtag, and informing the community "no less than two weeks before".
- **Options from lightest to heaviest:**
  1. **OSM Notes for moderated submissions.** `POST /api/0.6/notes` works anonymously (403 in "Moderation Zones"), or as the user if their token has `allow_write_notes` ([API v0.6](https://wiki.openstreetmap.org/wiki/API_v0.6)). Local mappers then verify. Keep it low-volume and moderated to avoid notes spam.
  2. **The owner maps verified parks himself** as an ordinary mapper with survey evidence.
  3. **Optional "Connect OpenStreetMap" (OAuth 2)** for power users to edit OSM directly from the app (v1.1+). This sits outside the Sign in with Apple-only account decision.
  4. **Bulk import.** Avoid.
- **Usage limits:**
  - The OSM editing API "is provided in order to edit the map data, not for read-only purposes", so the app must never read parks from `api.openstreetmap.org` ([API usage policy](https://operations.osmfoundation.org/policies/api/)).
  - Public Overpass is for small projects. For an app, "the usage counts towards the sum of requests made by all your users", and "Commercial use should use self-hosted or paid Overpass servers" ([Overpass wiki](https://wiki.openstreetmap.org/wiki/Overpass_API)).

### 5. Alternatives and their licences

| Source | What it has | Licence / terms | Usable as seed? |
|---|---|---|---|
| calisthenics-parks.com (seller "SPOTIC GmbH" per its [App Store listing](https://apps.apple.com/us/app/id1008398821); the Wiesbaden seat is **unverified**, because the site's imprint link spotic.net/imprint now redirects to an unrelated domain) | 925 spots in Poland and about 27,100 site-wide, with photos and ratings ([countries](https://calisthenics-parks.com/countries)) | Terms (last amended 2015-04-01) give the operator "authority for unlimited use" of user content. They contain no clause granting reuse rights to others, so all rights are reserved by default ([terms](https://calisthenics-parks.com/terms)). EU sui generis database right forbids extraction of "a substantial part" and "repeated and systematic extraction … of insubstantial parts" ([Directive 96/9/EC art. 7](https://www.legislation.gov.uk/eudr/1996/9/article/7)) | **No.** Manual comparison only |
| CaliBase (calibase.org) | 7,848 parks worldwide, community-verified ([calibase.org](https://calibase.org/)) | No licence, terms or API found, so all rights reserved by default | **No** |
| Warsaw open data: "Otwarte boiska" | School sports grounds open to residents free at set hours, "w tym … siłowni zewnętrznych". JSON. The city portal says "Tygodniowo" (weekly), while dane.gov.pl lists the source as "codziennie" (daily). Whether an API key is required is **(unverified)**: the page links a "Klucz API" section ([dane.um.warszawa.pl](https://dane.um.warszawa.pl/pl/catalogue/32a0ad2d-06d7-4e9c-acef-17a35c083d8c)) | CC BY 4.0 ([dane.gov.pl](https://api.dane.gov.pl/1.4/datasets/40838)). OSMF: "all CC BY versions have additional terms that make them incompatible with OpenStreetMap without explicit waivers" ([Licence Compatibility](https://osmfoundation.org/wiki/Licence/Licence_Compatibility)) | Partial: school grounds with limited hours. Use only for verification |
| Warsaw outdoor-gym map | Map of the "Warszawa w dobrej kondycji" machine gyms ([warszawa19115.pl](https://warszawa19115.pl/-/silownie-plenerowe) → mapa.um.warszawa.pl) | No dataset or licence found | No (and machine-only anyway) |
| Wrocław "Siłownie na świeżym powietrzu" | Interactive map of "kilkadziesiąt" gyms, including calisthenics spots ([wroclaw.pl](https://www.wroclaw.pl/silownie-na-swiezym-powietrzu-we-wroclawiu)) | No downloadable dataset or licence found | No |
| dane.gov.pl (national portal) | Searches for "siłownie plenerowe", "siłownie zewnętrzne" and "street workout" found no outdoor-gym dataset ([API search](https://api.dane.gov.pl/1.4/search?q=%22si%C5%82ownie%20plenerowe%22)) | n/a | No |
| OSA programme (Ministry of Sport) | Funds open activity zones, and street workout/calisthenics is one optional element ([gov.pl](https://www.gov.pl/web/sport/program-otwartych-stref-aktywnosci-osa-)) | No location list published | No |
| Google Places API | Good POI coverage | A Polish billing account gets the **EEA** terms, because the global terms "apply to Customers who do not have a billing account address in the European Economic Area". EEA §15.1: "Other than latitude, longitude, and place_id, Customer must not use Google Maps Content from the Places API With any Map". §15.4: coordinates may be cached "for up to 30 consecutive calendar days", then deleted ([EEA Service Specific Terms](https://cloud.google.com/terms/maps-platform/eea/maps-service-terms), last modified 2026-10-28). The non-EEA terms (§14.2 no use with a non-Google map, §14.3 the same 30 days) are at [maps-service-terms](https://cloud.google.com/maps-platform/terms/maps-service-terms). Under either set, CaliPark can't build a persistent park database from Places, and nothing from Google may go into OSM ([Legal FAQ §2.1.5](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ)) | **No** |

### 6. Getting the data operationally

- **Geofabrik `poland-latest.osm.pbf`:** 2.0 GB. It is rebuilt "once a day, around 21:00 CET" ([Geofabrik technical details](https://download.geofabrik.de/technical.html)), and a `poland-updates` directory holds `.osc.gz` change files. Public files omit user names, user IDs and changeset IDs, which Geofabrik treats as personal data under EU data-protection rules ([Geofabrik Poland](https://download.geofabrik.de/europe/poland.html)). The extract polygon (`poland.poly`) extends past the border, so clip to OSM relation 49715 before classifying.
- **Measured run:** extracting all relevant objects plus five city boundaries with pyosmium 4.3.2 took **2 min 18 s** on a 10-core Mac with 32 GB RAM. The fact-check's similar independent pass took 2 min 34 s on the same machine (Apple M5, 10 cores, 32 GB). A weekly job costs effectively nothing **(estimate)**. A minimal filter with osmium-tool would be `osmium tags-filter poland-latest.osm.pbf nwr/leisure=fitness_station nwr/fitness_station nwr/sport -o fit.osm.pbf`, followed by the classification in §1.
- **Overpass** suits ad-hoc checks in overpass-turbo, not the pipeline. Its fair-use guidance for regular use is "less than 100 queries fetching less 10 MB of data per day" ([Overpass wiki](https://wiki.openstreetmap.org/wiki/Overpass_API)).

## Recommendation

1. **Seed from OSM and accept ODbL for the Park-facts layer.** Without OSM, CaliPark launches with an empty map. With it, there are 108 Parks in the five launch cities and 393 in Poland. The price is publishing the Park-facts layer as an open dump. Community content (reviews, ratings, photos), which carries the product value, stays CaliPark's own as a Collective Database.
2. **Pipeline:**
   - Run a weekly job: Geofabrik PBF → osmium filter → clip to Poland's boundary (r49715), since the extract includes a cross-border buffer → classify (§1) → cluster → upsert.
   - Each Park keeps a CaliPark UUID plus `osm_refs` (type/id, can change), `source` (`osm`/`user`/`owner`) and per-field provenance.
   - On refresh, match by OSM ref first and then by distance under 30 m **(estimate)**.
   - Never auto-delete when OSM drops an object. Flag the Park for review.
   - Publish the ODbL dump as part of the same job. Leave out submitter account IDs and other personal data, the same way Geofabrik drops user names and IDs from public extracts on data-protection grounds. Park facts only.
3. **Launch content:**
   - Publish classes **A and B** after a one-pass manual review of the 108 places in the five cities. That is a few hours of work **(estimate)**, checking each place against imagery and the OSM history.
     - Review against OSM-compatible sources only: own survey, or the Geoportal orthophoto, which the Polish OSM community accepts after a 2013 GUGiK reply ([Pl:Geoportal.gov.pl](https://wiki.openstreetmap.org/wiki/Pl:Geoportal.gov.pl)). Never use Google Maps, Street View or satellite imagery. Corrections derived from Google could not be contributed to OSM ([Legal FAQ §2.1.5](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ)), and Google's consumer Maps terms forbid using Google Maps "to create or augment any other mapping-related dataset" for a substitute or similar service ([Google Maps/Earth Additional Terms](https://www.google.com/help/terms_maps/)).
     - Bars are thin, so aerial imagery often can't confirm them **(estimate)**.
     - Any manual correction makes the Park layer a non-trivial Derivative Database, which recommendation 1 already accepts.
   - Publish the rest of Poland's A places unreviewed but labelled "z OpenStreetMap".
   - Exclude D and E.
   - Keep C and F (6,934 places) as **hidden candidates**: never shown as Parks, but available for duplicate detection when users submit and for a later "Czy są tu drążki?" confirmation feature (v1.1).
4. **Map equipment to the OSM `fitness_station` vocabulary** (`horizontal_bar`, `parallel_bars`, `dip_bench`, `rings`, `wall_bars`, `horizontal_ladder`, `push-up`, …). Show Polish labels in the String Catalog. Round-tripping to OSM then becomes trivial.
5. **Submissions (spam resistance):**
   - Account required, as already decided.
   - Photo taken in-app with the device within about 150 m of the pin **(estimate)**.
   - Automatic duplicate check against Parks and hidden candidates within 50 m ("Czy to ten park?").
   - Status `pending` until the owner approves it or 2 other accounts confirm it **(estimate)**, with a per-account daily cap.
   - ToS clause: park facts are licensed under ODbL, and photos and reviews under a separate licence to CaliPark.
   - Don't paywall contributions at launch, because coverage is the bottleneck. Payment is legally fine under ODbL if the owner wants it later.
6. **Contribute back gradually, but don't make it a v1 requirement.** The owner maps surveyed parks himself and can add moderated OSM Notes in v1.1. Before any automated flow, post on the Polish OSM community forum.
7. **Attribution in v1:**
   - "© OpenStreetMap" link in a map corner while OSM Parks are visible.
   - Source line on park detail.
   - "Licencje danych" in Settings with the ODbL link and the dump link.

## Open questions for the owner

1. Do you accept that the Park-facts layer (locations, names, equipment, status, including user-submitted parks) is published as an open ODbL dump? This is the cost of seeding from OSM, and the alternative is a hand-collected map with no OSM.
2. Do horizontal ladders, rings or wall bars without a pull-up bar count as a Park (class C, 62 places)? The glossary currently says pull-up bar or parallel bars only.
3. Should the 6,872 OSM fitness stations without equipment detail stay hidden, or appear as a muted "niezweryfikowane" layer? Showing them conflicts with the glossary's exclusion of machine-only gyms.
4. Manual review scope before TestFlight: only the five cities (108) or all 393?
5. Will you create an OSM account and post on the Polish community forum, so CaliPark can contribute back (notes or your own edits)?
6. ToS: are you OK with users licensing park facts under ODbL (needed for share-alike and for any contribution to OSM)? Under what licence do photos and reviews fall?
7. Should CaliPark's equipment list use the OSM `fitness_station` values 1:1?

## Sources

- OSM wiki, `leisure=fitness_station`: https://wiki.openstreetmap.org/wiki/Tag:leisure%3Dfitness_station
- OSM wiki (pl), `leisure=fitness_station`: https://wiki.openstreetmap.org/wiki/Pl:Tag:leisure%3Dfitness_station
- OSM wiki, `fitness_station=*`: https://wiki.openstreetmap.org/wiki/Key:fitness_station
- OSM wiki, `sport=calisthenics`: https://wiki.openstreetmap.org/wiki/Tag:sport%3Dcalisthenics
- Geofabrik taginfo Poland (data until 2026-11-02 21:20 UTC): https://taginfo.geofabrik.de/europe:poland/tags/leisure=fitness_station, https://taginfo.geofabrik.de/europe:poland/keys/fitness_station#values, https://taginfo.geofabrik.de/europe:poland/tags/sport=fitness
- Geofabrik Poland extract: https://download.geofabrik.de/europe/poland.html
- Overpass API wiki (public instances, usage policy): https://wiki.openstreetmap.org/wiki/Overpass_API
- OSMF API usage policy: https://operations.osmfoundation.org/policies/api/
- OSM API v0.6 (Notes): https://wiki.openstreetmap.org/wiki/API_v0.6
- OSM Permanent ID: https://wiki.openstreetmap.org/wiki/Permanent_ID
- OSM copyright page: https://www.openstreetmap.org/copyright
- ODbL 1.0 legal text: https://opendatacommons.org/licenses/odbl/1-0/ (plain text: https://opendatacommons.org/licenses/odbl/odbl-10.txt)
- OSMF Community Guidelines index: https://osmfoundation.org/wiki/Licence/Community_Guidelines
- Horizontal Map Layers guideline: https://osmfoundation.org/wiki/Licence/Community_Guidelines/Horizontal_Map_Layers_-_Guideline
- Collective Database guideline: https://osmfoundation.org/wiki/Licence/Community_Guidelines/Collective_Database_Guideline_Guideline
- Regional Cuts guideline: https://osmfoundation.org/wiki/Licence/Community_Guidelines/Regional_Cuts_-_Guideline
- Produced Work guideline: https://osmfoundation.org/wiki/Licence/Community_Guidelines/Produced_Work_-_Guideline
- Substantial guideline: https://osmfoundation.org/wiki/Licence/Community_Guidelines/Substantial_-_Guideline
- Trivial Transformations guideline: https://osmfoundation.org/wiki/Licence/Community_Guidelines/Trivial_Transformations_-_Guideline
- Attribution Guidelines: https://osmfoundation.org/wiki/Licence/Attribution_Guidelines
- Licence and Legal FAQ: https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ
- Contributor Terms 1.2.4: https://osmfoundation.org/wiki/Licence/Contributor_Terms
- Licence Compatibility: https://osmfoundation.org/wiki/Licence/Licence_Compatibility
- Organised Editing Guidelines: https://osmfoundation.org/wiki/Organised_Editing_Guidelines
- Import Guidelines: https://wiki.openstreetmap.org/wiki/Import/Guidelines
- calisthenics-parks.com countries and terms: https://calisthenics-parks.com/countries, https://calisthenics-parks.com/terms
- CaliBase: https://calibase.org/
- Directive 96/9/EC art. 7 (copy of the original text): https://www.legislation.gov.uk/eudr/1996/9/article/7 (official: https://eur-lex.europa.eu/eli/dir/1996/9/oj)
- Warsaw, outdoor gyms: https://warszawa19115.pl/-/silownie-plenerowe
- Warsaw open data, "Otwarte boiska": https://dane.um.warszawa.pl/pl/catalogue/32a0ad2d-06d7-4e9c-acef-17a35c083d8c and https://api.dane.gov.pl/1.4/datasets/40838
- Wrocław, outdoor gyms: https://www.wroclaw.pl/silownie-na-swiezym-powietrzu-we-wroclawiu
- dane.gov.pl API search: https://api.dane.gov.pl/1.4/search?q=%22si%C5%82ownie%20plenerowe%22
- OSA programme: https://www.gov.pl/web/sport/program-otwartych-stref-aktywnosci-osa-
- Google Maps Platform Service Specific Terms: https://cloud.google.com/maps-platform/terms/maps-service-terms
- Google Maps Platform EEA Service Specific Terms (apply to EEA billing addresses): https://cloud.google.com/terms/maps-platform/eea/maps-service-terms
- Google Maps Platform Terms of Service (EEA switch, §3.2.3): https://cloud.google.com/maps-platform/terms
- Google Maps/Google Earth Additional Terms of Service: https://www.google.com/help/terms_maps/
- Geofabrik technical details (daily rebuild): https://download.geofabrik.de/technical.html
- Calisthenics Parks App Store listing (seller): https://apps.apple.com/us/app/id1008398821
- OSM wiki, Geoportal imagery in Poland: https://wiki.openstreetmap.org/wiki/Pl:Geoportal.gov.pl
- OSA basic variant (secondary source): https://pzpc.pl/aktualnosci/wiadomosci/6212/mionisterialna-osa-czyli-otwarte-strefy-aktywnosci-w-ramach-projektu-msit-proponuje-plenerowe-silownie
- Overpass API endpoint used for the fact-check counts: https://overpass-api.de/api/interpreter

## Fact-check (2026-11-03)

The fact-check re-ran the counts on live Overpass and re-implemented the classification and clustering independently, reading the same Geofabrik PBF (MD5 matches Geofabrik's published checksum) with a separate pyosmium/shapely script. It also re-fetched every licence and terms source. The overall finding holds: OSM can seed only a small high-confidence core of about 385–393 Parks in Poland and about 107–108 in the five cities. The ODbL analysis checks out against the licence text and the OSMF guidelines.

**Corrected:**
- **Overpass:** it *was* reachable. `overpass-api.de` answered from 19:55 UTC on 2026-11-03 with data up to 19:55Z. The live counts and query text are now in §2. They agree with the extract to within ±0.3% for Poland and exactly for most city totals.
- **"Poland" totals:** these are for the whole Geofabrik extract, whose polygon includes a cross-border buffer. Inside Poland's border there are 9,204 `leisure=fitness_station` objects (live Overpass: 9,206), not 9,224, and about 19 of the 7,501 places lie outside Poland. A "clip to r49715" step was added to the pipeline.
- **`sport`∋`calisthenics`:** the raw count is 177 (46/130/1), confirmed by both Overpass and the extract. 172 is the figure after excluding 5 indoor `leisure=fitness_centre` objects, and the table now says so. The city column likewise excludes indoor objects (raw: Warszawa 11, Gdańsk 5).
- **Second most common `fitness_station` value:** it is `horizontal_bar` (210), not `fitness_station` (152).
- **calisthenics-parks.com:** the countries page shows 27,101 spots site-wide, and only the terms header shows 27,115. The operator is "SPOTIC GmbH" according to the App Store listing. The Wiesbaden seat is unverified, because the imprint link redirects to an unrelated domain. The terms have no explicit anti-reuse clause; they simply grant no reuse rights.
- **Google Places:** a Polish owner falls under the EEA Service Specific Terms (§15.1, no use of Places content other than lat/lng/place_id with any map; §15.4, 30-day lat/lng cache), not the global §14.2/§14.3 the research cited. The conclusion is unchanged: not usable as a seed.
- **OSA programme:** the cited gov.pl page does not say the zones are outdoor-gym-centred. That claim now rests on a secondary municipal source and is marked unverified against the programme rules.
- **Warsaw "Otwarte boiska":** the update frequency is weekly on the city portal and "codziennie" on dane.gov.pl. The API-key requirement could not be confirmed.
- **Attribution wording:** linking "OpenStreetMap" to /copyright is the guideline's *suggested* way to make the ODbL clear, not a strict "must". Collapse on map interaction is also allowed.
- **Overpass wiki:** it recommends extracts "if you need a lot of data", not specifically when servers are overloaded. Wording fixed.

**Added:**
- The independent clustering replication. With the same thresholds it gives A 332, B 54, and A+B 385 inside the border; across thresholds A+B ranges 382–391. The city figures are 26/23/16/31/11 = 107. Single-node places (2,376), named places (434), A places with a name (119) and the freshness shares (15.6% / 49.0%) reproduced exactly.
- Manual review must use OSM-compatible sources (own survey, Geoportal orthophoto) and never Google imagery.
- The public ODbL dump must not contain submitter identities.
- Geofabrik's daily rebuild cadence, now sourced to its technical page.

**Verified as stated:**
- ODbL 1.0 quotes and section numbers (4.3, 4.4c, 4.4d, 4.5c, 4.6, 4.7a–c).
- Horizontal Layers (2014-06-06), Collective Database (2016-06-17), Regional Cuts, Substantial (<100 features, one-off), Produced Work and Trivial Transformations ("proposal stage") guidelines.
- Attribution Guidelines (adopted 2021-06-25).
- Legal FAQ §1.7.1, §1.9, §2.1.4, §2.1.5 and §4.
- Contributor Terms 1.2.4 §1(a).
- Licence Compatibility on CC BY.
- Organised Editing ("no less than two weeks before").
- Import Guidelines (`<username>_Import` account).
- API v0.6 Notes: anonymous notes allowed, 403 in Moderation Zones since May 2026, `allow_write_notes` (OAuth 2 scope name `write_notes`).
- API usage policy ("not for read-only purposes").
- Overpass usage figures (100 queries / 10 MB per day for regular use; "Commercial use should use self-hosted or paid Overpass servers").
- Permanent ID quote.
- OSM wiki tag descriptions.
- Geofabrik 2.0 GB and the omission of user metadata.
- City relation IDs and Wikidata IDs.
- Warsaw's six-machine standard.
- CC BY 4.0 on dane.gov.pl.
- Wrocław "kilkadziesiąt", with no dataset.
- No outdoor-gym location dataset on dane.gov.pl: the search hits are "Otwarte boiska" and a manufacturer's equipment spec sheets.
- CaliBase 7,848 parks, with no licence.
- Directive 96/9/EC art. 7(1) and 7(5).

**Could not verify:**
- Geofabrik taginfo pages: connection refused. The figures attributed to taginfo were re-derived from the same PBF instead.
- The SPOTIC Wiesbaden address.
- The OSA programme's official minimum scope.
- Whether the Warsaw dataset needs an API key.
- The researcher's exact D/E split, which depends on the machine-value list (the fact-check got D 81 / E 109 vs 97 / 77).
- That Apple's MapKit "Legal" attribution does not cover third-party pins. This is a reasonable reading, but no Apple document was checked.
