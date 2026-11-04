// Renders the brand images from SVG with sharp, so they need no browser:
//   app/opengraph-image.png (1200 × 630, also used for Twitter/X cards)
//   app/apple-icon.png      (180 × 180)
// Run `npm run og` after changing the brand (see components/Wordmark.tsx).
// Text uses the system's rounded font through fontconfig; check the output
// by eye after running it on a new machine.
import sharp from "sharp";

import path from "node:path";

const root = path.join(import.meta.dirname, "..");
const lime = "#D1FF00";
const bg = "#121212";
const font = "SF Pro Rounded, SF Pro Display, Helvetica Neue, Arial, sans-serif";

const mark = (x, y, s) => `
  <g transform="translate(${x} ${y}) scale(${s / 32})">
    <rect width="32" height="32" rx="8" fill="${lime}"/>
    <path d="M6 10h20M10 10v14M22 10v14" stroke="${bg}" stroke-width="3" stroke-linecap="round" fill="none"/>
  </g>`;

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

const icon = `<svg xmlns="http://www.w3.org/2000/svg" width="180" height="180" viewBox="0 0 180 180">
  <rect width="180" height="180" fill="${bg}"/>${mark(20, 20, 140)}</svg>`;
await sharp(Buffer.from(icon)).png().toFile(path.join(root, "app", "apple-icon.png"));

console.log("app/opengraph-image.png, app/apple-icon.png written");
