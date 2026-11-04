# CaliPark site

The public site for CaliPark: landing page, privacy policy, Parks data (ODbL) and help. Polish only for now. It is a fully static Next.js export: no server, no cookies, no analytics.

| Path | Page | Source |
|---|---|---|
| `/` | Landing page | `app/page.tsx` |
| `/prywatnosc` | Privacy policy (App Store "Privacy Policy URL") | `app/prywatnosc/page.tsx` |
| `/dane` | Parks data from OpenStreetMap, ODbL | `app/dane/page.tsx` |
| `/pomoc` | FAQ, TestFlight, contact (App Store "Support URL") | `app/pomoc/page.tsx` |

App Store texts and the App Privacy answers are drafts in [`docs/release/`](../docs/release/).

## Run it

Node 24 (Next.js 16 needs 20.9 or newer). Versions are pinned and `package-lock.json` is committed.

```sh
cd site
npm ci
npm run dev        # http://localhost:3000
npm run build      # static export to out/
npm start          # serves out/ like production
```

CI (`.github/workflows/ci.yml`, job **Site build**) runs `npm ci && npm run build` on every push and pull request, on Linux next to the iOS jobs.

## Before publishing: placeholders

`grep -rn PLACEHOLDER site/` lists them. All live in `content/site.ts` unless noted:

- `controllerName`: the data administrator's full name (privacy policy).
- `contactEmail`: the contact address. Use the same address in the app: `SupportContact.email` in `cali-park/Features/Profile/Models/AboutContent.swift`.
- `testFlightURL`: the public TestFlight link, or leave `null` (the help page then says "write to us").
- `appStoreURL`: leave `null` until the app is live (the hero shows "Wkrótce w App Store").
- The e-mail provider in the privacy policy, section 7 (`app/prywatnosc/page.tsx`).
- Confirm the Vercel DPA is accepted and Web Analytics / Speed Insights stay off (privacy policy, section 9, says the site has no analytics).

The privacy policy states facts about the app (checked against the code on 2026-11-04). The comment at the top of `app/prywatnosc/page.tsx` lists what to re-check when the app changes, and what must change before a build with Accounts, Community or iCloud sync.

## Vercel project settings

Create the project in the Vercel dashboard (Add New → Project → import `planetoida90210/cali-park`). Nothing is deployed until you do this.

| Setting | Value |
|---|---|
| Framework Preset | **Next.js** |
| Root Directory | **`site`** |
| Include files outside the Root Directory in the Build Step | Off |
| Build Command | default (`npm run build` → `next build`) |
| Output Directory | default (the preset picks up the static export in `out/`) |
| Install Command | default (`npm ci`, because of the lockfile) |
| Node.js Version (Settings → Build and Deployment) | **24.x** |
| Production Branch | `main` |
| Environment variable `NEXT_PUBLIC_SITE_URL` | `https://<your domain>` (Production). Without it the build uses the `*.vercel.app` production URL for canonical links, Open Graph and the sitemap. |
| Ignored Build Step (Settings → Git) | `git diff --quiet HEAD^ HEAD -- .` so iOS-only commits don't trigger a deploy (Vercel runs it inside `site/`) |
| Web Analytics, Speed Insights | **Off** (the privacy policy promises no analytics) |
| Deployment Protection | Keep Vercel Authentication on Preview deployments |
| Domains | Add the domain, then set `NEXT_PUBLIC_SITE_URL` to it and redeploy |

`vercel.json` adds security headers (CSP, `nosniff`, `Referrer-Policy`, `Permissions-Policy`, `X-Frame-Options`). The CSP allows inline scripts because the static Next.js export inlines its page data.

After the first deploy, check: `/prywatnosc` opens without a trailing slash, `/robots.txt` and `/sitemap.xml` use the real domain, and the Open Graph preview (e.g. pasting the link in iMessage) shows the CaliPark image.

## Brand assets

The mark is the app icon. `app/icon.svg` (favicon), `app/apple-icon.png`, `app/opengraph-image.png` and `public/brand/*.svg` are generated from the brand glyph by `node scripts/brand/build-icons.mjs` at the repo root (see `brand/README.md`), which also runs `npm run og`. `components/Wordmark.tsx` shows `public/brand/mark.svg`, so changing the icon never touches the components. After editing only the OG text, `npm run og` is enough. Check the OG image by eye: the text uses the machine's system font.

Colors follow the app's asset catalog and `AppTheme` (`#121212` background, `#1E1E1E` cards, `#D1FF00` accent); see the top of `app/globals.css`.

## App screenshots

`public/screens/*.webp` are 600 × 1304 crops of real simulator screenshots (iPhone 17, iOS 26.5, Polish region, seeded with five weeks of realistic training). To refresh them, take new 1206 × 2622 PNGs with the names listed in `scripts/prepare-screens.mjs` and run:

```sh
npm run screens -- /path/to/pngs
```

## Adding `/en`

Shared UI strings live in `content/pl.ts`. For English: add `content/en.ts` with the same shape, an `app/en/` tree whose pages reuse the components with English copy, and `alternates.languages` (`pl`, `en`) in each page's metadata. Keep Polish at the root so existing links don't change.
