# Progression ladders and built-in programs: source audit

Research question: are the 13 ladders and advancement criteria in [`docs/PROGRESSIONS.md`](../../PROGRESSIONS.md) grounded in established calisthenics sources? Which rungs or criteria disagree with the sources or look invented? Which 2–4 built-in programs could CaliPark 1.0 ship on top of the existing ladders? What may be reused legally, and how can the owner use paid Skool communities legitimately?

Researched 2026-11-03. All sources were read on that date. reddit.com blocks automated fetches, so I read the r/bodyweightfitness wiki pages through Internet Archive snapshots of the live pages. Each citation links the live page and the snapshot I read. *(estimate)* marks figures that are mine. *(CaliPark convention)* marks rules that come from no source. *(unverified)* marks claims the fact-check could not confirm from a primary source. This is not legal advice. A fact-check pass on the same day corrected several points; see [Fact-check (2026-11-03)](#fact-check-2026-11-03) at the end.

## Answer

- **Most ladders are grounded.** Front lever and back lever match the Overcoming Gravity 2nd ed. (OG2) chart rung for rung. Row, dip and muscle-up follow the OG2 order. Push-up is the Recommended Routine (RR) ladder plus one extra rung (knee push-ups). The RR push-up page has no knee rung, but the RR main page names knee push-ups as an easier variation, and Hybrid Calisthenics and Calimove both use that rung. Pull-up and core are sourced, with small gaps.
- **Five ladders need fixes.** The biggest gap is in **handstand**: it jumps from a wall hold straight to wall HSPU, skipping pike and elevated pike push-ups (OG2 levels 1–4). **L-sit** puts the one-leg-extended L-sit *before* the tuck L-sit, while OG2 and GMB put tuck first (GMB: one foot lifted → tuck → … → one leg extended → full). **Planche** skips the straight-arm frog stand/lean step, and straddle → full spans three OG2 levels. **Flag** skips the advanced tuck flag, and its equipment tag is wrong: it needs a vertical pole, not a pull-up bar. **Legs** has no split squat or Bulgarian split squat, and it puts step-ups out of RR order.
- **Criteria.** The rule "3 × 8 → next rung, restart at 3 × 5" is exactly RR, and StartBodyweight uses the same rule. "3 × 30 s" for entry holds is exactly RR's hold rule. But "3 × 20 s = OG rule" is **not stated as a rule in any public OG material checked**: OG2 prescribes holds from a tested max hold, and 3 × 20 s is the last row of its isometric table (max hold ≈ 30 s). Whether the book's text states a 3 × 20 s advancement rule is *(unverified)*, because the book was not read. The rule is defensible, but the doc should say where it comes from. 3 × 5 and 3 × 3 for hard rungs, 3 × 15 s for the full L-sit and the "first 5 s" mastery marker are CaliPark's own conventions, and the doc should label them that way.
- **Programs.** Ship three in v1:
  1. **Fundamenty**, a 3×/week full-body routine on the RR template. To be faithful to RR it needs a five-rung hinge ladder plus anti-rotation and extension ladders.
  2. **Minimum**, the r/bodyweightfitness Minimalist Routine. The existing ladders already cover it, as long as lunges stay in the `legs` ladder.
  3. **Skille**, a handstand + L-sit add-on built from the RR Skill Day. The RR Skill Day page explicitly excludes front lever, back lever, planche and flag ("strength skills. They don't belong here"), so the optional lever/planche/flag block uses the OG2 isometric table and belongs on strength days, not inside Skill Day.

  A fourth program, **Pierwsze podciągnięcie** (first pull-up), works as an optional preset.
- **Licensing.** Methods, rung order and sets/reps are free to reuse: see 17 U.S.C. § 102(b), the 2015 *Bikram* ruling and art. 1 ust. 2¹ of the Polish copyright act. Prose, form cues, images, videos, translations and brand names are not. FitnessFAQs, Reddit and Skool terms all forbid copying their content. The RR moderators say they do not endorse paid RR apps, so keep the RR-based programs free and credited.
- **Skool.** Sizeable calisthenics communities exist. Examples: World Of Calisthenics (4,561 members, free), Caliversity (12,443 members, free to join; its About page lists programs next to 80–1,000 USD figures without saying whether those are prices), Daniel Hristov Academy (1,773, free) and Calisthenics Masterclass (37 USD/month). Their paid content is behind a login. Skool's terms forbid scraping, copying and compiling it. Use those groups only for personal validation, or hire a coach to review the ladders.

## Findings

### 1. Sources and how far each one can be trusted

| Source | What it is | Access | Used here for |
|---|---|---|---|
| r/bodyweightfitness **Recommended Routine** (RR) and exercise pages | Community wiki. The current version dates from the 2018 update ([RR][rr]). | Free. reddit.com blocks bots, so I read archived copies. | Ladders for pull-up, row, push-up, dip, squat, hinge, core and support. Rep and hold rules. |
| r/bodyweightfitness **Minimalist Routine** and **Skill Day** | Wiki routines linked from the RR FAQ ([min][minr], [skill][skillday]) | Free | Programs 2 and 4 |
| **Overcoming Gravity 2nd ed.** (Steven Low) | Book, plus a public chart sheet and articles by the author ([OG page][ogpage], [chart sheet][ogsheet], [isometric table][ogpril]) | The book is paid and I did not read it. The charts and articles are free. | Rung order for every ladder; isometric dosing |
| **StartBodyweight** (SBW) | Older Blogger-based site with a basic routine and progressions ([routine][sbw], [pull-up][sbwpull]) | Free | Second opinion on rep rules and the pull-up ladder |
| **Calisthenicmovement / Cali Move** | Vendor blog plus paid programs ([beginner plan][cmplan], [push-up][cmpush], [pull-up challenge][cmpull], [levels][cmlevels]) | The blog is free; the programs are paid. | Rep-range philosophy, push-up levels, notes on bands and eccentrics |
| **Hybrid Calisthenics** (Hampton Liu) | Free routine with high-rep "Standards" ([routine][hcroutine], [programs][hcprog], [pull-ups][hcpull], [push-ups][hcpush]) | Free; "All Rights Reserved" | Contrasting rep philosophy, knee push-up rung |
| **GMB** | Vendor articles ([L-sit][gmblsit]) | gmb.io returns HTTP 403 to automated fetches. The fact-check read the Internet Archive snapshot of 2026-07-18 ([snapshot][gmblsitwb]). | L-sit order |
| **Antranik** | Personal site with an RR walkthrough and L-sit/statics guides ([rr][antrr], [L-sit][antlsit], [statics][antstatic]) | Free; "All Rights Reserved" | L-sit order and the 60 s criterion. Shows that the RR walkthrough describes the **pre-2018** RR. |
| **FitnessFAQs** (Daniel Vadnal) | 11 paid programs ([programs][ffprog]) plus YouTube | Paid; no public text with numeric criteria | Not used for any criterion; terms checked ([ToU][fftou]) |

Limits: I did not read the OG2 book. The [preview PDF][ogpreview] is image-only and covers only chapters 1–3. The OG2 sheet marks prerequisites by colour, and the CSV export loses the colours. The sheet's leg and core columns (glute bridge, Nordic curl, shrimp squat, reverse hyper, hanging leg raise, dragon flag) are labelled *"not in the book. They are proposed progressions"*, with book page "N/A" ([sheet][ogsheet]). Below I label them "OG2 sheet extra".

### 2. Ladder-by-ladder audit

Rungs are listed as in `docs/PROGRESSIONS.md`. "L*n*" is the OG2 chart level.

| # | Ladder | CaliPark rungs (criterion) | What the sources say | Verdict |
|---|---|---|---|---|
| 1 | `pullUp` | dead hang 3×30 s → scapular pulls 3×8 → negatives 3×5 → band pull-ups 3×8 (parallel track) → pull-ups 3×8 → L-pull-ups 3×5 → archer pull-ups 3×5 | **RR:** scapular pulls (3–5 s pause) → arch hangs → negatives ("build up to 10sec") → pull-ups → weighted. After 3×8 pull-ups the alternative paths are L-sit pull-ups, arch-body pull-ups, or typewriter → archer. RR mentions bands only under scapular pulls, as assistance "if you can't pull out of the dead hang at all"; it has no band pull-up rung ([pull-up][rrpull]). **OG2:** jump pull-ups L1 → bar eccentrics L2 → pull-ups L3 → L-pull-ups L4. Assisted pull-ups are L2 and ring archer pull-ups L7 ([sheet][ogsheet]). **SBW:** leg-assisted → jackknife → 5 s eccentrics → half → full → close → wide → archer, capped at 6 per arm ([SBW][sbwpull]). | **Mostly sourced.** (a) No source has a dead hang rung; it is grip prep. Harmless, but unsourced. (b) The RR arch hang is missing. (c) L-pull-ups → archer is OG2 L4 → L7, and RR puts the two on different branches. (d) The archer criterion must be per arm (SBW: ≤ 6 per arm). (e) The negatives criterion has no descent time (RR: 10 s, SBW: 5 s). |
| 2 | `row` | incline rows → Australian (horizontal) → wide rows → archer rows 3×5 → tuck front lever rows | **RR:** vertical → incline → horizontal → wide → weighted. After 3×8 wide rows the branches are archer → one-arm, or a tuck FL hold (3×10–30 s, prerequisites skin the cat 5×2 and arch hang 3×8) → tuck FL pulls 3×5–8 ([row][rrrow]). **OG2:** ring rows L2 → wide L3 → archer L4 → tuck FL rows L5. | **Matches the OG2 order.** RR treats archer rows and tuck FL rows as alternatives and wants a 20–30 s tuck FL hold first. Add that as a non-binding hint. |
| 3 | `pushUp` | wall → incline → knee → full → diamond → pseudo-planche (`Push-up handles`) | **RR:** vertical (wall) → incline → full → diamond → pseudo-planche push-ups. Equipment: "Nothing! Or rings" ([push-up][rrpush]). **Hybrid:** wall → incline → advanced incline → **knee** → full ([HC][hcpush]). **Calimove** level 2: "low incline / knee" ([CM][cmpush]). | **Sourced.** The knee rung is not on the RR push-up page, but the RR main page lists knee push-ups as an easier variation, and Hybrid and Calimove both have it ([RR][rr]). Pseudo-planche push-ups need no equipment, so the `Push-up handles` tag is wrong. Today the tag is only displayed in the step sheet (`StepDetailSheetView`); nothing filters rungs by equipment yet, but a future park-equipment filter would hide this rung. |
| 4 | `dip` | support hold 3×30 s → negatives 3×5 → bar dips 3×8 → ring dips 3×8 | **RR dip page:** support "work up to 3 sets of 1 minute holds" → negatives "work up to 10 sec descents" → bar dips → weighted. Ring dips have the prerequisite "3x8 PB Dips + 60sec RTO Support Hold" ([dip][rrdip], [support][rrsupport]). **OG2:** support L1, RTO support L2, bar eccentrics L2, bar dips L3, ring dip eccentrics L3, ring dips L4. | **The rungs match.** The criteria are softer than the RR dip page (30 s vs 60 s), though the RR main page's general hold rule is 30 s. A ring support hold is missing before ring dips. |
| 5 | `legs` | assisted squat → squat → lunges → step-ups → assisted pistol 3×5 → pistol 3×5 | **RR:** assisted → squat → **split squat** → **Bulgarian split squat** → shrimp ×3. After 3×8 Bulgarian split squats: step-ups → deep step-ups, *or* partial pistol → pistol ([squat][rrsquat]). RR explicitly separates split squats from lunges. **OG2 book:** parallel → full → side-to-side squat → pistol (L4). **OG2 sheet extra:** lunges L1, split squat L2, shrimp L3. | **Partly sourced.** "Lunges" stands in for split squats. The Bulgarian split squat is missing, and any park bench works for it. Step-ups are an *alternative* to pistols in RR, not a step before them. Unilateral criteria must be per leg. RR's FAQ counts deep step-ups as "5-8 Reps left leg, 5-8 reps right leg". |
| 6 | `core` | plank 3×30 s → hanging knee raises → hanging leg raises → toes to bar (3×8) | **RR anti-extension:** plank ("Work up to a 30s hold then move on") → ring rollouts. The alternative path is tucked hanging leg raises → pike negatives → straight hanging leg raises. The RR triplet also has **anti-rotation** (Pallof press, Copenhagen plank) and **extension** (reverse hyper, arch body), at 3×8–12 ([core][rrcore]). **OG2:** 25 s plank L2, 60 s plank L3 (book). Hanging toes to bar is L3–L4 (sheet extra). | **Sourced** for what it covers. Anti-rotation and extension are missing, which matters only for an RR-faithful program. |
| 7 | `muscleUp` | chest-to-bar 3×5 → negatives 3×3 → kipping 3×3 → strict, first clean rep | **OG2:** muscle-up negatives L3 → kipping L4 → muscle-up L5 → strict bar muscle-up L7. **SBW:** sternum and belly-button pull-ups as muscle-up steps. **RR:** "Strive for chest to bar". | **Matches.** |
| 8 | `lSit` | foot-supported → **one leg** ("one leg raised, the other tucked") → tuck → full 3×15 s (others 3×20 s) | **OG2:** tuck L1 → "1 Leg Bent L-sit" L2 → L-sit L3. **GMB (6 steps):** both feet on the ground → one foot off the ground → tuck → slight leg extension → single-leg extension ("one leg fully while the other is tucked", at least 5 s per side) → full L-sit; holds of 5–30 s ([GMB snapshot][gmblsitwb]). **Antranik:** foot-supported → *one-foot-supported* → tucked → less tucked → full, 1 min per rung ([Antranik][antlsit]). | **Fix the order.** As described in `ExerciseCatalog`, rung 2 (one leg extended, other tucked) is harder than rung 3 according to OG2 and GMB. Either redefine rung 2 as "one foot supported" (Antranik, GMB step 2) or swap rungs 2 and 3 (OG2). GMB supports doing both: foot-supported → one foot lifted → tuck → one leg extended → full (five rungs, so it inserts one). The one-leg rung needs a per-side criterion. The full L-sit at 3×15 s breaks the ladder's own 3×20 s base. |
| 9 | `frontLever` | tuck → advanced tuck → straddle → half-lay → full, first 5 s | **OG2:** tuck L4, advanced tuck L5, straddle L6, half-lay/one-leg L7, full L8. **Antranik:** tuck → advanced tuck → one-leg → straddle → full ([Antranik][antstatic]). | **Matches OG2 exactly.** Add the RR tuck FL prerequisites (skin the cat 5×2, arch hang 3×8) as hints. |
| 10 | `backLever` | German hang → skin the cat 3×5 → tuck → advanced tuck → straddle → half-lay → full | **OG2:** German hang L1, skin the cat L2, tuck L3, advanced tuck L4, straddle L5, half-lay/one-leg L6, full L7. | **Matches OG2 exactly.** |
| 11 | `planche` | frog stand 3×30 s → tuck → advanced tuck → straddle → full | **OG2:** frog stand L3, **straight-arm frog stand L4**, tuck L5, advanced tuck L6, straddle L8, **half-lay/one-leg L9**, full L11. | **Fix.** Add the straight-arm frog stand (or planche lean) before tuck. Straddle → full spans three levels, so add half-lay or one-leg, the way the front lever ladder already does. |
| 12 | `humanFlag` | vertical flag support → tuck → straddle → full; equipment `Pull-up bar` | **OG2:** tuck L5, **advanced tuck L6**, straddle L7, full L8. The catalog's own instructions say "Chwyć pionowy drążek" (grab a vertical pole). | **Fix.** Add the advanced tuck flag. "Vertical flag support" appears in no source I checked. The equipment needs a vertical pole or wall bars. The equipment pool has no vertical-pole key. It does have `Monkey bars`, but `EquipmentItem` labels it "Drabinki", which Polish users read as wall bars (stall bars), so that key is ambiguous and should be split before the flag or the park form relies on it. |
| 13 | `handstand` | wall plank 3×30 s → wall handstand 3×30 s → wall HSPU 3×5 | **OG2:** wall handstand L1–3. Push-up column: **pike headstand push-up L1 → box (elevated pike) L2 → wall headstand push-up eccentric L3 → wall headstand push-up L4** → wall HSPU L5. **Calimove:** pike push-ups at level 2, wall HSPU at level 3 ([levels][cmlevels]). **RR:** the push-up and dip pages both offer "HeSPU" (headstand push-ups) as an alternate path ([push-up][rrpush], [dip][rrdip]). **RR Skill Day:** handstand prerequisite is a 30 s plank ([skill][skillday]). | **Biggest gap.** From a wall hold straight to wall HSPU skips OG2 L1–L4. Add pike push-ups and elevated pike push-ups, and optionally wall HSPU negatives. "Wall plank" appears in no source checked, but it is a plausible entry drill. |

### 3. Advancement criteria audit

| CaliPark criterion | Used on | Source status |
|---|---|---|
| **3 × 8 → next rung, restart at 3 × 5** | Dynamic rungs | **Exactly RR**: "perform 3 sets of 5 reps … add one rep per set until you are performing 3 sets of 8 reps … move on to the next progression, but again at 3 sets of 5 reps" ([RR][rr]). SBW is the same at 8,8,8 → next at 4,4,4, plus a deload rule: "If you do not show progress more than twice in a row, it is time to deload" ([SBW][sbw]). |
| One qualifying session (engine) | All | Matches RR, which counts 3 sets in one session. |
| **3 × 30 s** | Entry holds (dead hang, support, German hang, frog stand, plank, wall drills) | **RR's hold rule**: "holding the position statically for 10-30 seconds. Move on to the next harder progression once you hit 30 seconds for all 3 sets" ([RR][rr]). Stricter sources ask for 60 s: the RR dip/support pages, SBW planks ("Once you can hold a variation for 1 min, move on") and Antranik's L-sit. |
| **3 × 20 s** | Lever, planche, flag and L-sit statics | **Not an explicit rule in the public OG material checked** (the book text is *(unverified)*). OG2 tests a max hold and prescribes hold time and sets from a table. Its *sweet spot* runs from 8×1 s (max 1 s) to **3×20 s (max 29–30 s)**, the last row ([OG2 isometric table][ogtable], [article][ogpril]). The author's guidance elsewhere is "60-70% of the max hold time" ([article][ogpril]) and, for planche, "4-5×6-10s" ([plateau article][ogplateau]). So 3×20 s ≈ "you have outgrown the OG2 table", which is defensible. RR would ask for 3×30 s on any hold. The article's worked examples (10 s max → 6 × 7 s; 20 s max → 13 s holds) differ slightly from the OG2 table image (5 × 7 s; 4 × 14 s), so implement the table and cite it. |
| **3 × 5 / 3 × 3** | Negatives, unilateral moves, muscle-up steps | *(CaliPark convention.)* RR uses 3×5–8 for every rung, negatives included. SBW caps archer and one-arm work at 6 per arm. Two gaps: unilateral rungs need "per side", and negatives need a descent time. The current `AdvancementCriterion` (`setsOfReps` / `setsOfHold`) can express neither. |
| **3 × 15 s** full L-sit | `lSit` rung 4 | Unsourced, and inconsistent with the 3×20 s base. |
| **First 5 s / first clean rep** | Full levers, flag, planche, strict muscle-up | *(CaliPark convention.)* No source I checked defines it. As a "mastery marker" it is fine, but say it is ours. |
| Placement "12+ in one set ≈ 3 × 8" | `PlacementCalibration` | *(Estimate.)* It is consistent with, and more conservative than, RR's example of "one rep short of failure such as 7-7-7" for a max of 8 ([RR][rr]); by that example a max of about 9 already gives 3 × 8. |

### 4. Statements in the "Źródła" (sources) section of PROGRESSIONS.md that need correcting

- **OG charts.** The doc cites calisthenics-101.co.uk. The primary sources are the author's [chart sheet][ogsheet] and [printable PDF][ogpdf], both linked from [stevenlow.org][ogpage]. Lunges and toes-to-bar come from the sheet's "not in the book" extra columns, and the doc should say so.
- **"Kryterium izometrii: 3 × 20 s → następna wariacja"** (isometric criterion: 3 × 20 s → next variation). Restate it as "the last row of the OG2 isometric table (max hold ≈ 30 s)". See section 3.
- **The RR link.** The doc cites `redditbwf.github.io/wiki/recommended_routine.html`. That GitHub mirror is live, but its text differs from the current reddit wiki: for example, it words the rep rule differently and has no free-apps/monetization note. Who maintains it is *(unverified)*. Cite the reddit.com wiki ([RR][rr]) as the primary source.
- **The Antranik walkthrough** ([antranik.org/rr][antrr]) describes the **pre-2018** RR: bodyline drills, a skill block, prerequisites such as 3×8 rows before pull-ups and 3×8 diamond push-ups before dips, and L-sit paired with squats. The current RR ([RR][rr]) differs. Cite the wiki for rules.
- **"FPU guides"** (first pull-up guides) is unnamed. Name RR, OG2, SBW and Calimove. None of them uses a dead hang rung or the order "dead hang → scapular pulls → negatives → band".
- **Polish translation.** The only Polish RR translation is listed under "Old Translations (before 2018)" ([RR][rr]). It is outdated, and it is someone else's derivative work, so write the Polish copy from scratch.

### 5. Rep philosophies differ, and CaliPark sits in the mainstream

| Source | Typical working range | Advance when |
|---|---|---|
| RR | 3 × 5–8, about 1 rep short of failure | 3 × 8 clean ([RR][rr]) |
| StartBodyweight | 3 × 4–8 | 8,8,8 ([SBW][sbw]) |
| Calimove beginner plan | 3 × 7–14 (push-ups), 3 × 1–6 (pull-ups) | Top of the range on all 3 sets ([CM][cmplan]) |
| Hybrid Calisthenics | 2–3 sets, high-rep "Standards" | e.g. full pull-ups "3 Sets of 12", full push-ups "3 Sets of 25" ([HC pull][hcpull], [HC push][hcpush]) |
| Steven Low / OG | Strength 3–8 reps, "3-5 sets of 3-6 repetitions", not to failure | Harder progression when you exceed the target reps ([fundamentals][ogfund]) |

CaliPark's 3 × 8 is the RR/SBW consensus and a good default. Hybrid's much higher standards are a different philosophy, not a contradiction.

### 6. Candidate built-in programs

Every program below uses the **current rung of a ladder**, not a fixed exercise. All sets × reps follow the RR rule from section 3 unless noted.

#### Program 1: "Fundamenty" (Foundations; full body, based on the RR)

Source: RR, current wiki ([RR][rr]). It runs 3×/week with at least one rest day between sessions, for about an hour ("This routine is about an hour long").

| Block | Ladder (current rung) | Sets × reps | Rest |
|---|---|---|---|
| Warm-up | own content, 5–10 min | — | — |
| Pair 1 | `pullUp` ↔ `legs` | 3 × 5–8 each | 90 s after each set |
| Pair 2 | `dip` ↔ **hinge (missing ladder)** | 3 × 5–8 each | 90 s |
| Pair 3 | `row` ↔ `pushUp` | 3 × 5–8 each | 90 s |
| Core triplet | `core` ↔ **anti-rotation (missing)** ↔ **extension (missing)** | 3 × 8–12 (holds 10–30 s) | 60 s |

- **Rules (RR):**
  - Start on the hardest rung you can do for 3 × 5, add one rep per set each session, and move up at 3 × 8.
  - Stop about one rep short of failure.
  - If reps drop between sets, rest up to 3 minutes.
- **Scaling for true beginners (RR FAQ):** 1–2 sets instead of 3, or 2 days/week, or "just pick one of the 1 push, 1 pull, and 1 legs exercise to start".
- **Gaps.** To call it RR, CaliPark needs three more ladders:
  - **Hinge**, per RR (five rungs): Romanian deadlift → single-leg deadlift → banded Nordic negatives → banded Nordic → Nordic curl ([hinge][rrhinge]). Feet can be anchored under a park bench or low bar. The two banded rungs need `Resistance bands`; RR's alternate paths (hamstring slides, Harop curls) avoid the band.
  - **Anti-rotation**: RR's main rung is the banded Pallof press, which needs a band. Its alternate Copenhagen plank series needs only a bench.
  - **Extension**: reverse hyperextension on a bench, or the arch raises → arch-body hold → arch-body rocks path.

  Without them, name the program "inspired by RR" and use only the `core` ladder in the triplet.

#### Program 2: "Minimum" (r/bodyweightfitness Minimalist Routine)

Source: Minimalist Routine ([min][minr]). It is "derived from /u/m092's Concept Wednesday".

| Circuit (no rest between moves) | Ladder |
|---|---|
| Walking lunges | `legs` (lunges rung, or current rung) |
| Push-ups | `pushUp` |
| Rows | `row` |
| Plank shoulder taps | `core` rung 1 (plank). The catalog has no shoulder-tap exercise. |

- **Volume and effort:** 2–6 circuits, with each set 1–2 reps short of failure.
- **Frequency:** 3×/week for strength, or every day for general health.
- **Progression:** move up after "at least three sets of 8-10 reps", which fits CaliPark's 3 × 8.
- **Duration:** about 15–25 min *(estimate)*.
- **Coverage:** the existing ladders cover it 100%. It is the cheapest program to ship, and it suits the TestFlight cohort. This depends on `lungesID` staying in the catalog: if the `legs` fix *replaces* lunges with split squats, Minimum loses its first exercise, so add split squats alongside lunges instead.

#### Program 3: "Pierwsze podciągnięcie" (First pull-up; optional preset)

This is a CaliPark composition of sourced rules, not a published program. It targets people with 0–3 strict pull-ups. 3×/week, about 30–40 min *(estimate)*.

| Order | Ladder | Prescription | Source |
|---|---|---|---|
| 1 (fresh) | `pullUp` | Scapular pulls 3 × 5–8 with a 3–5 s hold. Negatives 3 × 3–5 with 5–10 s descents. Pull-ups 3 × 5–8, about 1 rep short of failure. | RR ([pull-up][rrpull]), SBW 5 s eccentrics ([SBW][sbwpull]) |
| (parallel track) | band pull-ups | A band that allows "about 4-8 reps" | Calimove ([challenge][cmpull]) |
| 2 | `row` | 3 × 5–8 | RR: rows "cannot be substituted" ([RR][rr]). SBW: horizontal pulls have "a much gentler gradient … The two benefit from each other" ([SBW][sbwpull]). |
| 3 | `pushUp` ↔ `legs` | 3 × 5–8 each, paired, 90 s rest | RR |

- **Drop negatives** once the user can do more than 3 strict pull-ups. Calimove: eccentrics are "not that effective anymore" past that point ([challenge][cmpull]).
- **Exit:** at 3 × 8 pull-ups, switch to Fundamenty.
- **Don't** replicate Calimove's branded "8 Weeks Pull Up Challenge" structure. Only the general facts about bands and eccentrics are used here.

#### Program 4: "Skille" (skill add-on)

Sources: RR Skill Day ([skill][skillday]) for blocks A–B, and the OG2 isometric table ([table][ogtable]) plus Steven Low's plateau article ([plateau][ogplateau]) for block C. Block A–B runs 2–3×/week, either on rest days from strength work (RR main page: "at least one rest day (or skill day) in between") or before the strength work (Skill Day FAQ). About 15–20 min with warm-up and mobility *(estimate)*.

| Block | Ladder | Prescription |
|---|---|---|
| A. Handstand practice | `handstand` | 5–10 min, resting as needed. Prerequisite: a 30 s plank (RR Skill Day). |
| B. L-sit | `lSit` | 2–3 min of holds, 10–30 s each. Move on at 30 s (RR Skill Day). |
| C. One static (optional, **on strength days**) | `frontLever`, `backLever`, `planche` or `humanFlag` | Test the max hold on the current rung, then take sets × hold from the OG2 table (e.g. max 10 s → 5 × 7 s, max 20 s → 4 × 14 s, max 30 s → 3 × 20 s). Advance at 3 × 20 s, which matches CaliPark's criterion. |

- **Block C is not Skill Day content.** The RR Skill Day FAQ says front lever, back lever, planche, manna, human flag and dragon flag "are all skills but they are strength skills. They don't belong here" ([skill][skillday]). Steven Low's planche example puts the static on the Monday/Wednesday/Friday strength days ([plateau][ogplateau]), and RR's own row page offers a tuck front lever path in place of rows ([row][rrrow]). So attach block C to Fundamenty's strength days, not to the skill sessions, and credit OG2 for it, not RR.
- **Limit:** one static at a time *(CaliPark convention)*. Steven Low's planche example is 3×/week at "4-5×6-10s" ([plateau][ogplateau]).
- **Hints, not gates:**
  - Front lever: skin the cat 5 × 2 and arch hang 3 × 8 (RR row page).
  - Back lever: German hang and skin the cat (OG2 L1–L2).
  - Planche: frog stand (OG2 L3).
- **Don't** reproduce the OG2 table image. Implement the rule, "60-70% of the max hold time" plus the table's set counts, in code and cite it.

#### What the code needs for programs (from the repo)

- **`PlannedExercise`** (`cali-park/Features/Planner/Models/PlannedExercise.swift`) stores a fixed `exerciseID` plus optional `targetSets`/`targetReps`. Programs need four more things:
  - a **ladder reference** ("current rung of `ProgressionPathID`");
  - a **rep range** (5–8);
  - **target seconds** for holds;
  - **rest**, a **pair/circuit group** and a **per-side** flag.
- **Ladder edits** (pike push-ups, Bulgarian split squat, advanced tuck flag…) insert rungs. The audit's P1 says placement declarations and celebration records store a **rung index** ([audit README](../../audit/README.md), A-6/C-5). Inserting rungs would silently shift those records. Switch them to exercise IDs *before* editing the ladders. Also keep `PROGRESSIONS.md` and `ProgressionCatalog` in sync 1:1, as `CLAUDE.md` requires. The placement table in `PROGRESSIONS.md` ("Nogi": at 12+ the current rung becomes Wykroki) and `PlacementCalibration` must change too if the `legs` ladder changes; the audit's A-7 shows an earlier mapping change shipped without migrating saved placements.

### 7. Licensing: what can be reused

**Legal basis.**

- **US.** 17 U.S.C. § 102(b) excludes "any idea, procedure, process, system, method of operation … regardless of the form in which it is described". Copyright in a book "does not give the author the right to prevent others from employing the system" ([Circular 33][circ33]).
- **US case law.** The Ninth Circuit held that a sequence of 26 yoga poses and two breathing exercises was "an idea, process, or system designed to improve health". The sequence was therefore not protected, either as a compilation or as choreography. Only "the words and pictures used to describe the Sequence" were protected (*Bikram's Yoga College v. Evolation Yoga*, No. 13-55763, Oct 8, 2015, [opinion][bikram]).
- **Poland.** Art. 1 ust. 2¹ of the copyright act: "Ochroną objęty może być wyłącznie sposób wyrażenia; nie są objęte ochroną odkrycia, idee, procedury, metody i zasady działania oraz koncepcje matematyczne" (only the form of expression is protected; discoveries, ideas, procedures, methods and operating principles, and mathematical concepts are not). The provision was added by the 2002 amendment ([Dz.U. 2002 nr 197 poz. 1662][plcopy]). The Bikram ruling binds only US courts; for a Polish developer it is persuasive context, and the Polish provision is the one that applies at home.
- **Caveat.** I did not check whether the EU/Polish *sui generis* database right could cover a chart. Don't copy any chart wholesale regardless.

| Free to reuse (method) | Do not copy without written permission (expression, brand, contract) |
|---|---|
| Which exercises, in which order (rungs) | Wiki, blog and book prose; form cues and FAQ text written verbatim |
| Sets, reps, rest, frequency, tempo | Photos, GIFs, videos, illustrations, the OG2 chart and table as images or wholesale copies |
| Progression rules (3×5 → 3×8, 60–70 % of max hold) | Translations: the old Polish RR translation belongs to its translators |
| Generic exercise names ("pike push-up", "tuck planche") | Branded program names and anything implying endorsement ("official RR", "Overcoming Gravity program", "8 Weeks Pull Up Challenge") |
| Citing and linking sources | Paid content. FitnessFAQs: "You may not reproduce, distribute, modify, sell, or exploit content without written permission" ([ToU §15][fftou]). Skool content (section 8). |

**Terms of the platforms themselves.**

- **Reddit.** Users "retain any ownership rights" in their content. Without a written agreement you may not "commercially exploit the Services or Content". "Scraping the Services without Reddit's prior written consent is prohibited" ([User Agreement, eff. July 1, 2026, last revised May 26, 2026][redditua]). The page has a separate version for users in the EEA, which covers the owner in Poland; both versions contain the "commercially exploit" and scraping clauses. So write your own text; never import wiki pages.
- **Other sites.** Hybrid Calisthenics, Calimove and Antranik all mark their sites "All Rights Reserved" or "Copyright ©" ([HC][hcroutine], [CM][cmplan], [Antranik][antrr]).

**Community norm (not law).** The RR page says: "If you are being charged for any Recommended Routine app don't use it. We do not endorse monetization of the RR" ([RR][rr]). If CaliPark later adds a paywall for contributions, keep Fundamenty and Minimum free, and credit r/bodyweightfitness with a link. The same RR page keeps a "Free Apps for Recommended Routine" list (Boostcamp, Calistree, Progressive workouts, Fitloop, 8x3 and others). Those are the direct comparison points for a free RR program. Calistree's App Store listing has a "Skill trees" section and is free with in-app purchases (US store on 2026-11-03: 5.99 USD/month, 44.99 USD/year, 179 USD lifetime) ([App Store][calistree]), so a free app with optional paid extras can still appear on that list. Whether the moderators would list CaliPark is *(unverified)*.

### 8. Skool calisthenics communities (public information only)

Skool's terms (effective July 1, 2023) say:

- "You will not … access the Services manually or with any robot, spider, web crawler, extraction software … to scrape, copy or monitor any portion of the Services or any content."
- "You will not copy or distribute any content displayed through the Services."
- "You will not create or compile … any collection, compilation, or other directory from any content displayed through the Services except for your personal, non commercial use."
- The acceptable-use section also bars using the Services "for any commercial purpose, including but not limited to contacting, advertising to, soliciting or selling to, any Users."
- Creators keep ownership: "Your content is yours" ([Skool T&C][skooltc]).

Paid classrooms are behind a login, and nothing in them may be scraped or copied into CaliPark.

I fetched these About pages on 2026-11-03, and the fact-check re-read them the same day (member counts from each page's embedded data). Member counts and prices change.

| Community | Host (as stated) | Members | Price | Visibility | Offers |
|---|---|---|---|---|---|
| [World Of Calisthenics][sk-woc] | Simon Imhäuser, "Heavyweight World Champion" | 4,561 | Free | Public | Planche/FL intro, "5 Calisthenics Fundamentals" |
| [Calisthenics Masterclass][sk-cm] | Simon Imhäuser | 172 | 37 USD/month or 259 USD/year, free trial | Private | Planche, FL, handstand and muscle-up programs, feedback, weekly Q&A |
| [Caliversity][sk-cv] | "Daemon Caliversity" | 12,443 | Free to join | Public | Lists eight programs with dollar figures from 80 to 1,000 USD (e.g. "7++ Levels Planche and Front Lever Program ($1000)"). The page does not say whether these are purchase prices or the claimed value of included content *(unverified)*. |
| [Daniel Hristov Academy][sk-dh] | Daniel Hristov, "4x world champion" | 1,773 | Free | Private | Free planche/FL lessons, paid "Revolution" programs |
| [Strength Club][sk-sc] | Louay Sattar | 1,908 | 1 USD/month | Private | Workshops, programs, handstand guide |
| [Awesome! Hybrid Calisthenics][sk-ahc] | Brandon Beauchesne-Hebert | 1,387 | Free, plus a paid Premium tier (price not shown) listing "Skill Tree Database" and "Workout App Access" | Public | 250-page "Masterbook", courses, feedback. The host's links point to awesomeninjafitness.com, not hybridcalisthenics.com (Hampton Liu), so don't assume any connection. Its skill-tree database is a competing concept. |
| [Calisthenics Monks][sk-monks] | Hadi Khattar | 434 | 8 USD/month or 80 USD/year ("Price increasing to 49$ soon!") | Private | Video feedback, live calls, roadmap |
| [Calisthenics made easy][sk-cme] | George Santos | 332 | Free, plus "Warriors" tier at 19.99 USD/month for the first 100 members, then 37 USD/month | Public | Community feed, challenges, tutorials; paid tier adds programs and coaching calls |

Fetched, but the price was not visible in the page data *(unverified)*:

- [P.R.O.J.E.C.T Calisthenics][sk-proj]: 17 members, private. Earlier search snippets said about 49 USD/month.
- [Costa Calisthenics][sk-costa]: German, 96 members, private, monthly/annual tiers. Earlier search snippets said about 10 USD/month.
- [Level Up][sk-lu]: French, 163 members, private, 7-day free trial. Earlier search snippets said about 21 USD/month.

One search found no Polish-language calisthenics community on Skool. The search was not exhaustive *(unverified)*.

**Legitimate ways to use Skool:**

1. **Join free public groups as yourself** and read and ask. Good questions: "Do you put one-leg L-sit before or after tuck?", "Pike push-ups before wall HSPU?" Record the answers in your own notes as a sanity check. Never paste their material into the repo.
2. **Buying one program for your own training is fine.** Use it to judge whether your ladders are reasonable. CaliPark content must still come from public sources and your own writing.
3. **To use a coach's material or name, get written permission or a licence.** Cleaner still, pay a coach to *review* your ladders (a Polish coach or physiotherapist fits the PL launch). Fee unknown *(estimate needed)*.
4. **Don't promote CaliPark or recruit TestFlight users in a group** without the owner's OK. Never scrape member lists. The Skool terms ban both commercial contact and compiling.

## Recommendation

1. **Fix the ladders before TestFlight.** Do the storage fix first (A-6/C-5, rung index → exercise ID), then edit `ProgressionCatalog` and `PROGRESSIONS.md` together.
   - **handstand**: insert pike push-ups and elevated pike push-ups before wall HSPU (OG2 L1–L2).
   - **lSit**: swap rungs 2↔3 (OG2), or redefine rung 2 as one-foot-supported (Antranik, GMB step 2), or do both as GMB does. Make the full L-sit a mastery marker, or set it to 3×20 s.
   - **planche**: add straight-arm frog stand / planche lean, and half-lay or one-leg.
   - **humanFlag**: add the advanced tuck flag. Fix the equipment, which needs a vertical pole or wall bars. The pool has no vertical-pole key, and the existing `Monkey bars` key is labelled "Drabinki" (wall bars in Polish), so split it. The Community scope already lists equipment, so decide the keys there.
   - **legs**: add the split squat and Bulgarian split squat *alongside* lunges (Minimum needs lunges), and move step-ups to a branch beside pistols. Update the placement mapping for "Nogi" at the same time.
   - **Small fixes:** pseudo-planche push-ups need no equipment. Add a ring support hold (or hint) before ring dips. Add the arch hang. Make archer, pistol, lunge and step-up criteria per side. Give negatives a descent cue (5–10 s).
2. **Correct the "Źródła" (sources) section** as listed in section 4. Label the CaliPark conventions (3×5, 3×3, first 5 s, 3×20 s derived from OG2). I did not edit the file.
3. **Ship programs Minimum, Fundamenty and Skille in v1,** and Pierwsze podciągnięcie as a preset if time allows.
   - Minimum works on today's ladders.
   - Fundamenty needs a hinge ladder (five rungs in RR, two of them banded) plus anti-rotation and extension ladders. Either add them or label the program "inspired by RR".
   - Skille needs hold targets in the program model. Keep it to handstand + L-sit (RR Skill Day); offer the lever/planche/flag block as an OG2-based add-on to strength days.
4. **Extend the program model.** Add a ladder reference, rep range, target seconds, rest, grouping and per-side, as described in section 6.
5. **Licensing practice:**
   - Write all Polish copy yourself.
   - Add an in-app "Źródła" list with links per ladder and program.
   - No third-party images or text.
   - Keep the RR-based programs free forever.
6. **Use Skool only for personal validation.** Consider a paid expert review of the ladders as the cheapest credibility win.

## Open questions for the owner

1. Should Fundamenty be **faithful RR**, which means adding hinge, anti-rotation and extension ladders, or **"inspired by RR"** using only today's ladders?
2. Can ladder edits wait for the A-6/C-5 storage fix, or do you want to freeze rung counts for v1 and fix only order, labels and equipment?
3. For statics, keep **3 × 20 s** (top of the OG2 table) or move to RR's **3 × 30 s**? And should the full L-sit be a mastery marker or a 3 × 20 s rung?
4. Should unilateral criteria be per side? That needs a model change to `AdvancementCriterion`.
5. Should Pierwsze podciągnięcie be its own program or a goal preset of Fundamenty?
6. Would you pay a Polish coach or physiotherapist to review the ladders before launch, and what budget?
7. If contributions ever go behind a paywall, do you agree that training content (and anything RR-based) stays free?
8. Should Park equipment get a "vertical pole / wall bars" key, and should the ambiguous `Monkey bars` / "Drabinki" key be split? It matters for both the flag ladder and the Community park submission form.

## Sources

r/bodyweightfitness wiki. These are live URLs; I read the archived snapshots linked after each one, because reddit.com blocks automated access.
- Recommended Routine: https://www.reddit.com/r/bodyweightfitness/wiki/kb/recommended_routine/ — snapshot https://web.archive.org/web/20260401032459/https://www.reddit.com/r/bodyweightfitness/wiki/kb/recommended_routine/
- Pull-up: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/pullup/ — https://web.archive.org/web/20260324211234/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/pullup/
- Row: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/row/ — https://web.archive.org/web/20260329003454/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/row/
- Push-up: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/pushup/ — https://web.archive.org/web/20250330082127/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/pushup/
- Dip: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/dip/ — https://web.archive.org/web/20250327183521/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/dip/
- Support: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/support/ — https://web.archive.org/web/20251021063411/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/support/
- Squat: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/squat/ — https://web.archive.org/web/20260402025504/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/squat/
- Hinge: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/hinge/ — https://web.archive.org/web/20250327183525/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/hinge/
- Core: https://www.reddit.com/r/bodyweightfitness/wiki/exercises/core/ — https://web.archive.org/web/20250330013944/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/core/
- Minimalist Routine: https://www.reddit.com/r/bodyweightfitness/wiki/minroutine — https://web.archive.org/web/20250727065914/https://www.reddit.com/r/bodyweightfitness/wiki/minroutine/
- Skill Day: https://www.reddit.com/r/bodyweightfitness/wiki/kb/skillday — https://web.archive.org/web/20250726172547/https://www.reddit.com/r/bodyweightfitness/wiki/kb/skillday/

Overcoming Gravity / Steven Low
- Book page: https://stevenlow.org/overcoming-gravity/
- OG2 charts (Google Sheet): https://docs.google.com/spreadsheets/d/19l4tVfdTJLheLMwZBYqcw1oeEBPRh8mxngqrCz2YnVg/
- OG2 charts (printable PDF): https://stevenlow.org/wp-content/uploads/2017/02/OG2ChartsPrint.pdf
- OG2 preview (TOC, ch. 1–3): https://stevenlow.org/wp-content/uploads/2018/09/OG2-preview-TOC-Intro-Ch1-3.pdf
- Prilepin tables for isometrics, with the OG2 isometric table: https://stevenlow.org/prilepin-tables-for-bodyweight-strength-isometric-and-eccentric-exercises/ (table image: https://stevenlow.org/wp-content/uploads/2016/12/isometrictable.jpg)
- Programming isometrics after a plateau: https://stevenlow.org/how-to-program-for-advanced-isometric-movements-after-a-plateau/
- Fundamentals of bodyweight strength training: https://stevenlow.org/the-fundamentals-of-bodyweight-strength-training/

Other training sources
- StartBodyweight basic routine: http://www.startbodyweight.com/p/start-bodyweight-basic-routine.html
- StartBodyweight pull-up progression: http://www.startbodyweight.com/p/pull-up-progression.html
- Cali Move beginner plan: https://blog.calimove.com/2026/09/09/calisthenics-training-plan-for-beginners/
- Cali Move push-up progression: https://blog.calimove.com/2026/02/04/push-up-progression/
- Cali Move 8-week pull-up challenge: https://blog.calimove.com/2023/05/11/8-weeks-pull-up-challenge/
- Cali Move levels: https://blog.calimove.com/2024/05/24/from-beginner-to-superhuman-calisthenics-levels-explained/
- Hybrid Calisthenics routine: https://www.hybridcalisthenics.com/routine
- Hybrid Calisthenics programs: https://www.hybridcalisthenics.com/programs
- Hybrid Calisthenics pull-ups: https://www.hybridcalisthenics.com/pullups
- Hybrid Calisthenics push-ups: https://www.hybridcalisthenics.com/pushups
- GMB L-sit: https://gmb.io/l-sit/ (returns 403 to automated fetches; read via snapshot https://web.archive.org/web/20260718150020/https://gmb.io/l-sit/)
- Antranik RR walkthrough: https://antranik.org/rr/
- Antranik L-sit tutorial: https://antranik.org/l-sit-tutorial/
- Antranik static-hold progressions: https://antranik.org/progression-exercises-for-static-holds/
- FitnessFAQs programs: https://www.fitnessfaqs.com/programs
- FitnessFAQs terms of use: https://www.fitnessfaqs.com/terms-of-use
- Calistree on the App Store (competitor listed on the RR free-apps list): https://apps.apple.com/app/id1558561315
- RR GitHub mirror cited by PROGRESSIONS.md (older text): https://redditbwf.github.io/wiki/recommended_routine.html

Law and platform terms
- U.S. Copyright Office, Circular 33, *Works Not Protected by Copyright*: https://www.copyright.gov/circs/circ33.pdf
- *Bikram's Yoga College of India v. Evolation Yoga*, 9th Cir. No. 13-55763 (Oct 8, 2015): https://cdn.ca9.uscourts.gov/datastore/opinions/2015/10/08/13-55763.pdf
- Ustawa z 28 października 2002 r. o zmianie ustawy o prawie autorskim (adds art. 1 ust. 2¹): https://api.sejm.gov.pl/eli/acts/DU/2002/1662/text.html
- Reddit User Agreement (effective July 1, 2026): https://redditinc.com/policies/user-agreement
- Skool Terms and Conditions (effective July 1, 2023): https://www.skool.com/legal?t=terms

Skool community pages (About pages, read 2026-11-03)
- https://www.skool.com/calisthenics-masterclass-free/about
- https://www.skool.com/calisthenics-masterclass/about
- https://www.skool.com/school-of-caliversity-2834/about
- https://www.skool.com/daniel-hristov-academy/about
- https://www.skool.com/ultra-strength-club-4323/about
- https://www.skool.com/awesome-ninja-fitness/about
- https://www.skool.com/cali-monks-4748/about
- Fetched in the fact-check (prices not visible for the last three): https://www.skool.com/calisthenics-made-easy-8541/about, https://www.skool.com/projectcalisthenics/about, https://www.skool.com/costacalisthenics/about, https://www.skool.com/level-up-8502/about

Repo context
- `docs/PROGRESSIONS.md`; `docs/audit/README.md` (A-6, C-5); `cali-park/Features/Exercises/Services/ExerciseCatalog.swift` (rung descriptions and equipment); `cali-park/Features/Planner/Models/PlannedExercise.swift`; `cali-park/Features/Skills/Models/AdvancementCriterion.swift`

[rr]: https://web.archive.org/web/20260401032459/https://www.reddit.com/r/bodyweightfitness/wiki/kb/recommended_routine/
[rrpull]: https://web.archive.org/web/20260324211234/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/pullup/
[rrrow]: https://web.archive.org/web/20260329003454/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/row/
[rrpush]: https://web.archive.org/web/20250330082127/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/pushup/
[rrdip]: https://web.archive.org/web/20250327183521/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/dip/
[rrsupport]: https://web.archive.org/web/20251021063411/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/support/
[rrsquat]: https://web.archive.org/web/20260402025504/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/squat/
[rrhinge]: https://web.archive.org/web/20250327183525/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/hinge/
[rrcore]: https://web.archive.org/web/20250330013944/https://www.reddit.com/r/bodyweightfitness/wiki/exercises/core/
[minr]: https://web.archive.org/web/20250727065914/https://www.reddit.com/r/bodyweightfitness/wiki/minroutine/
[skillday]: https://web.archive.org/web/20250726172547/https://www.reddit.com/r/bodyweightfitness/wiki/kb/skillday/
[ogpage]: https://stevenlow.org/overcoming-gravity/
[ogsheet]: https://docs.google.com/spreadsheets/d/19l4tVfdTJLheLMwZBYqcw1oeEBPRh8mxngqrCz2YnVg/
[ogpdf]: https://stevenlow.org/wp-content/uploads/2017/02/OG2ChartsPrint.pdf
[ogpreview]: https://stevenlow.org/wp-content/uploads/2018/09/OG2-preview-TOC-Intro-Ch1-3.pdf
[ogpril]: https://stevenlow.org/prilepin-tables-for-bodyweight-strength-isometric-and-eccentric-exercises/
[ogtable]: https://stevenlow.org/wp-content/uploads/2016/12/isometrictable.jpg
[ogplateau]: https://stevenlow.org/how-to-program-for-advanced-isometric-movements-after-a-plateau/
[ogfund]: https://stevenlow.org/the-fundamentals-of-bodyweight-strength-training/
[sbw]: http://www.startbodyweight.com/p/start-bodyweight-basic-routine.html
[sbwpull]: http://www.startbodyweight.com/p/pull-up-progression.html
[cmplan]: https://blog.calimove.com/2026/09/09/calisthenics-training-plan-for-beginners/
[cmpush]: https://blog.calimove.com/2026/02/04/push-up-progression/
[cmpull]: https://blog.calimove.com/2023/05/11/8-weeks-pull-up-challenge/
[cmlevels]: https://blog.calimove.com/2024/05/24/from-beginner-to-superhuman-calisthenics-levels-explained/
[hcroutine]: https://www.hybridcalisthenics.com/routine
[hcprog]: https://www.hybridcalisthenics.com/programs
[hcpull]: https://www.hybridcalisthenics.com/pullups
[hcpush]: https://www.hybridcalisthenics.com/pushups
[gmblsit]: https://gmb.io/l-sit/
[gmblsitwb]: https://web.archive.org/web/20260718150020/https://gmb.io/l-sit/
[calistree]: https://apps.apple.com/app/id1558561315
[antrr]: https://antranik.org/rr/
[antlsit]: https://antranik.org/l-sit-tutorial/
[antstatic]: https://antranik.org/progression-exercises-for-static-holds/
[ffprog]: https://www.fitnessfaqs.com/programs
[fftou]: https://www.fitnessfaqs.com/terms-of-use
[circ33]: https://www.copyright.gov/circs/circ33.pdf
[bikram]: https://cdn.ca9.uscourts.gov/datastore/opinions/2015/10/08/13-55763.pdf
[plcopy]: https://api.sejm.gov.pl/eli/acts/DU/2002/1662/text.html
[redditua]: https://redditinc.com/policies/user-agreement
[skooltc]: https://www.skool.com/legal?t=terms
[sk-woc]: https://www.skool.com/calisthenics-masterclass-free/about
[sk-cm]: https://www.skool.com/calisthenics-masterclass/about
[sk-cv]: https://www.skool.com/school-of-caliversity-2834/about
[sk-dh]: https://www.skool.com/daniel-hristov-academy/about
[sk-sc]: https://www.skool.com/ultra-strength-club-4323/about
[sk-ahc]: https://www.skool.com/awesome-ninja-fitness/about
[sk-monks]: https://www.skool.com/cali-monks-4748/about
[sk-cme]: https://www.skool.com/calisthenics-made-easy-8541/about
[sk-proj]: https://www.skool.com/projectcalisthenics/about
[sk-costa]: https://www.skool.com/costacalisthenics/about
[sk-lu]: https://www.skool.com/level-up-8502/about

## Fact-check (2026-11-03)

Every source below was re-opened on 2026-11-03: the r/bodyweightfitness wiki snapshots (RR, pull-up, row, push-up, dip, support, squat, hinge, core, Minimalist Routine, Skill Day), the OG2 chart sheet (CSV export), the OG2 isometric table image, Steven Low's three articles, both StartBodyweight pages, four Cali Move posts, three Hybrid Calisthenics pages, three Antranik pages, GMB (via the Internet Archive), FitnessFAQs terms and programs, Circular 33, the *Bikram* opinion, the 2002 Polish amendment, the Reddit User Agreement, the Skool terms, and all eleven Skool About pages.

**Confirmed as written:** every OG2 level number in section 2, rung for rung (front lever, back lever, planche, flag, HSPU column, L-sit, pull-ups, rows, dips, muscle-up, squats, sheet-extra legs and core). Also confirmed: the RR rep and hold rules and every RR quote (rest times, "about an hour", 7-7-7, rows "cannot be substituted", the beginner-scaling FAQ, the monetization note, Polish only under "Old Translations"), the RR exercise-page details, the Minimalist Routine and Skill Day details, the OG2 table rows (8×1 s … 5×7 s … 4×14 s … 3×20 s), the "60-70% of the max hold time", "4-5×6-10s" and "3-5 sets of 3-6 repetitions" quotes, the SBW rules (8,8,8 → 4,4,4, deload, 1 min planks, 5 s eccentrics, 6 per arm), the Cali Move and Hybrid figures, the Antranik orders, the FitnessFAQs ToU §15 quote (11 programs plus a bundle), 17 U.S.C. § 102(b) and Circular 33, the *Bikram* holding, the Reddit and Skool clauses and their effective dates, and the repo claims (`PlannedExercise`, `AdvancementCriterion`, A-6/C-5 under audit P1, the catalog's one-leg L-sit, flag and pseudo-planche entries).

**Corrected:**
- **GMB L-sit order.** The search-engine extract was incomplete. The archived page has six steps and includes "one foot off the ground" before the tuck. The "verify by hand" caveat was replaced with the snapshot citation. GMB therefore backs both of the proposed L-sit fixes.
- **Knee push-ups.** The RR main page does name knee push-ups as an easier variation; only the RR push-up page lacks them.
- **Bands in RR.** RR mentions bands only as assistance for scapular pulls. It has no band pull-up rung.
- **Pseudo-planche equipment.** The tag does not hide the rung today; it is only displayed. It would hide the rung once an equipment filter exists.
- **Flag equipment.** A `Monkey bars` key exists, but its Polish label "Drabinki" reads as wall bars, so the key is ambiguous rather than missing.
- **Program "Skille".** The RR Skill Day page explicitly excludes lever, planche and flag work. The static block was moved to strength days and credited to OG2 only.
- **Hinge ladder.** RR's hinge ladder has five rungs, not four. Two of them, and RR's main anti-rotation rung (Pallof press), need a band.
- **Minimum and legs.** Replacing lunges would break Minimum, so the recommendation now says to add split squats alongside lunges and to update the placement mapping.
- **3 × 20 s.** "Mis-attributed" was softened to "not stated in public OG material; book not read". The article's worked examples differ slightly from the table, so the doc now says to implement the table.
- **Legal and terms details.** *Bikram* covers 26 poses *and two breathing exercises*. The Polish quote is now complete ("oraz koncepcje matematyczne"), with a note that the US ruling is only persuasive in Poland. The Reddit UA date now carries "last revised May 26, 2026", plus a note that the EEA version (which applies to the owner) has the same clauses.
- **Skool.** Member counts are now exact: World Of Calisthenics 4,561 (was 4.5k), Daniel Hristov 1,773 (was 1.7k), Awesome! 1,387 (was 1.3k), Calisthenics made easy 332 (was 321). Caliversity's 80–1,000 USD figures are not labelled as prices. Awesome!'s paid tier lists "Skill Tree Database" and "Workout App Access", not apps with those names. Monks also has an 80 USD/year option. The four search-only groups were fetched.

**Added:** the `redditbwf.github.io` mirror cited by `PROGRESSIONS.md` is an older text, so cite the reddit wiki instead. The RR page's free-apps list includes Calistree, a skill-tree competitor that is freemium (US prices cited). The Skool "commercial purpose … soliciting … any Users" clause was added. The planche, flag and handstand evidence is unchanged; the RR push-up and dip pages also offer HeSPU, which supports adding pike/headstand push-ups.

**Could not verify:**
- Whether the OG2 book's text states a 3 × 20 s rule.
- Whether Caliversity's dollar figures are prices.
- Current prices for P.R.O.J.E.C.T, Costa and Level Up.
- Who maintains the GitHub RR mirror.
- Whether a Polish-language Skool calisthenics community exists.
- Whether the EU sui generis database right could cover a progression chart.
- Whether RR moderators would list CaliPark.

**Not covered and worth a separate check:** a health and safety notice for built-in programs (for example, "stop on pain; consult a doctor if you have conditions"), and whether App Review expects one for fitness content. See `appstore-compliance.md`; nothing here was verified.

**Bottom line (unchanged in substance):** the ladders are mostly grounded. Fix handstand, L-sit, planche, flag and legs before TestFlight, after moving rung storage to exercise IDs (A-6/C-5). Ship Minimum first because it needs no new ladders. Fundamenty needs hinge, anti-rotation and extension ladders, or else the "inspired by RR" label. Keep Skille to handstand + L-sit, with statics as an OG2 add-on on strength days. Keep RR-based programs free and credited, write all copy yourself, and use Skool only for personal validation.
