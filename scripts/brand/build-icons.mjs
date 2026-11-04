// Builds every app and site icon from the active brand glyph.
//
//   node scripts/brand/build-icons.mjs [--previews <dir>]
//
// The glyph to use is the one word in `brand/ACTIVE` (a folder name under
// `brand/`, e.g. `drabinka` or `pinezka`). Each `brand/<name>/glyph.svg` is a
// 1024 × 1024 artboard in the accent color (#D1FF00) on a transparent
// background; it is the master artwork. This script writes:
//
//   cali-park/Resources/AppIcon.icon/            Icon Composer bundle (iOS 26 Liquid Glass)
//   cali-park/Resources/Assets.xcassets/AppIcon.appiconset/
//                                                1024 px default, dark and tinted PNGs (iOS 18 fallback)
//   site/app/icon.svg, site/public/brand/mark.svg, site/public/brand/app-icon.svg
//
// and then runs `npm run og` in `site/` for the apple-icon and OG image.
// With --previews it also renders every glyph (not only the active one) as
// default/dark/tinted 1024 px and 29/40/60 px PNGs into <dir>/<name>/.
//
// Rendering uses sharp from site/node_modules (run `npm ci` in site/ first).
import { execFileSync } from "node:child_process";
import { mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync, existsSync } from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";

const root = path.join(import.meta.dirname, "..", "..");
const sharp = createRequire(path.join(root, "site", "package.json"))("sharp");

const lime = "#D1FF00";
const background = "#121212";
const corner = 229; // iOS app icon corner radius on a 1024 artboard (for site tiles only)

const brandDir = path.join(root, "brand");
const active = readFileSync(path.join(brandDir, "ACTIVE"), "utf8").trim();
const concepts = readdirSync(brandDir, { withFileTypes: true })
  .filter((entry) => entry.isDirectory() && existsSync(path.join(brandDir, entry.name, "glyph.svg")))
  .map((entry) => entry.name);
if (!concepts.includes(active)) {
  throw new Error(`brand/ACTIVE names "${active}", but brand/${active}/glyph.svg does not exist`);
}

const glyphSVG = (name) => readFileSync(path.join(brandDir, name, "glyph.svg"), "utf8");

/** The glyph's markup without the outer <svg> element and comments, recolored. */
function glyphBody(name, color = lime) {
  const svg = glyphSVG(name).replace(/<!--[\s\S]*?-->/g, "");
  const inner = svg.slice(svg.indexOf(">", svg.indexOf("<svg")) + 1, svg.lastIndexOf("</svg>")).trim();
  return inner.replaceAll(lime, color);
}

/** A 1024 artboard: optional background (full bleed or rounded tile) under the glyph. */
function iconSVG(name, { color = lime, fill = background, tile = false, border = false } = {}) {
  const shape = fill
    ? tile
      ? `<rect width="1024" height="1024" rx="${corner}" fill="${fill}"/>`
      : `<rect width="1024" height="1024" fill="${fill}"/>`
    : "";
  const edge = border
    ? `<rect x="8" y="8" width="1008" height="1008" rx="${corner - 8}" fill="none" stroke="#FFFFFF" stroke-opacity="0.14" stroke-width="16"/>`
    : "";
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">${shape}${edge}${glyphBody(name, color)}</svg>\n`;
}

/** `opaque` drops the alpha channel: App Store Connect rejects an app icon
 *  that has one (ITMS-90717), even when every pixel is opaque. */
const png = (svg, size, file, { opaque = false } = {}) => {
  const image = sharp(Buffer.from(svg), { density: 72 * (size / 1024) * 4 }).resize(size, size, { kernel: "lanczos3" });
  return (opaque ? image.removeAlpha() : image).png({ compressionLevel: 9 }).toFile(file);
};

// MARK: - App: Icon Composer bundle

const resources = path.join(root, "cali-park", "Resources");
const iconBundle = path.join(resources, "AppIcon.icon");
rmSync(iconBundle, { recursive: true, force: true });
mkdirSync(path.join(iconBundle, "Assets"), { recursive: true });
writeFileSync(path.join(iconBundle, "Assets", "glyph.svg"), glyphSVG(active));
const iconJSON = {
  fill: { solid: "srgb:0.07059,0.07059,0.07059,1.00000" },
  groups: [
    {
      layers: [
        {
          "image-name": "glyph.svg",
          name: "glyph",
          glass: true,
          position: { scale: 1, "translation-in-points": [0, 0] },
        },
      ],
      shadow: { kind: "neutral", opacity: 0.5 },
      translucency: { enabled: false, value: 0.5 },
    },
  ],
  "supported-platforms": { squares: "shared" },
};
writeFileSync(path.join(iconBundle, "icon.json"), JSON.stringify(iconJSON, null, 2) + "\n");

// MARK: - App: asset catalog fallback (default, dark, tinted)

const appIconSet = path.join(resources, "Assets.xcassets", "AppIcon.appiconset");
rmSync(appIconSet, { recursive: true, force: true });
mkdirSync(appIconSet, { recursive: true });
await png(iconSVG(active), 1024, path.join(appIconSet, "AppIcon-1024.png"), { opaque: true });
// Dark and tinted: transparent background, the system draws its own.
await png(iconSVG(active, { fill: null }), 1024, path.join(appIconSet, "AppIcon-1024-dark.png"));
await png(iconSVG(active, { fill: null, color: "#FFFFFF" }), 1024, path.join(appIconSet, "AppIcon-1024-tinted.png"));
const image = (filename, appearance) => ({
  ...(appearance ? { appearances: [{ appearance: "luminosity", value: appearance }] } : {}),
  filename,
  idiom: "universal",
  platform: "ios",
  size: "1024x1024",
});
writeFileSync(
  path.join(appIconSet, "Contents.json"),
  JSON.stringify(
    {
      images: [
        image("AppIcon-1024.png"),
        image("AppIcon-1024-dark.png", "dark"),
        image("AppIcon-1024-tinted.png", "tinted"),
      ],
      info: { author: "xcode", version: 1 },
    },
    null,
    2,
  ) + "\n",
);

// MARK: - Site

const site = path.join(root, "site");
mkdirSync(path.join(site, "public", "brand"), { recursive: true });
const tile = iconSVG(active, { tile: true, border: true });
writeFileSync(path.join(site, "app", "icon.svg"), tile);
writeFileSync(path.join(site, "public", "brand", "mark.svg"), tile);
writeFileSync(path.join(site, "public", "brand", "app-icon.svg"), iconSVG(active));
execFileSync("npm", ["run", "og"], { cwd: site, stdio: "inherit" });

console.log(`brand: built the app and site icons from brand/${active}/glyph.svg`);

// MARK: - Previews (optional)

const previewsAt = process.argv.indexOf("--previews");
if (previewsAt !== -1) {
  const out = process.argv[previewsAt + 1];
  for (const name of concepts) {
    const dir = path.join(out, name);
    mkdirSync(dir, { recursive: true });
    await png(iconSVG(name), 1024, path.join(dir, "default-1024.png"));
    await png(iconSVG(name, { fill: "#000000" }), 1024, path.join(dir, "dark-1024.png"));
    await png(iconSVG(name, { fill: "#0B0F16", color: "#8CC2FF" }), 1024, path.join(dir, "tinted-1024.png"));
    for (const size of [29, 40, 60]) {
      await png(iconSVG(name), size, path.join(dir, `default-${size}.png`));
    }
    console.log(`previews: ${dir}`);
  }
}
