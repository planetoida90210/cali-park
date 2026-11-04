// Renders the brand images from SVG with sharp, so they need no browser:
//   app/opengraph-image.png (1200 × 630, also used for Twitter/X cards)
//   app/apple-icon.png      (180 × 180)
// The brand mark comes from public/brand/ (mark.svg, app-icon.svg), which
// `node scripts/brand/build-icons.mjs` at the repo root writes and which then
// runs this script; run `npm run og` alone only after editing the text.
// Text uses the system's rounded font through fontconfig; check the output
// by eye after running it on a new machine.
import sharp from "sharp";

import { readFileSync } from "node:fs";
import path from "node:path";

const root = path.join(import.meta.dirname, "..");
const lime = "#D1FF00";
const bg = "#121212";
const font = "SF Pro Rounded, SF Pro Display, Helvetica Neue, Arial, sans-serif";

const brandSVG = (name) => readFileSync(path.join(root, "public", "brand", name), "utf8");
// The brand mark (a 1024 × 1024 SVG) nested at (x, y) with side s.
const mark = (x, y, s, name = "mark.svg") => {
  const svg = brandSVG(name);
  const inner = svg.slice(svg.indexOf(">", svg.indexOf("<svg")) + 1, svg.lastIndexOf("</svg>"));
  return `<svg x="${x}" y="${y}" width="${s}" height="${s}" viewBox="0 0 1024 1024">${inner}</svg>`;
};

const og = `
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <rect width="1200" height="630" fill="${bg}"/>
  <circle cx="1040" cy="560" r="300" fill="${lime}" opacity="0.07"/>
  ${mark(80, 80, 72)}
  <text x="172" y="134" font-family="${font}" font-size="52" font-weight="800" fill="#FFFFFF">Cali<tspan fill="${lime}">Park</tspan></text>
  <text x="80" y="330" font-family="${font}" font-size="76" font-weight="800" fill="#FFFFFF">Kalistenika z planem.</text>
  <text x="80" y="420" font-family="${font}" font-size="76" font-weight="800" fill="${lime}">Krok po kroku.</text>
  <text x="80" y="530" font-family="${font}" font-size="32" font-weight="500" fill="#A3A3A3">Drabiny progresji · gotowe programy · mapa Parków · bez Konta</text>
</svg>`;

await sharp(Buffer.from(og)).png({ compressionLevel: 9 }).toFile(path.join(root, "app", "opengraph-image.png"));

// iOS rounds the apple-touch-icon itself, so it is the full-bleed app icon.
await sharp(Buffer.from(brandSVG("app-icon.svg")), { density: 72 * (180 / 1024) * 4 })
  .resize(180, 180, { kernel: "lanczos3" })
  .png({ compressionLevel: 9 })
  .toFile(path.join(root, "app", "apple-icon.png"));

console.log("app/opengraph-image.png, app/apple-icon.png written");
