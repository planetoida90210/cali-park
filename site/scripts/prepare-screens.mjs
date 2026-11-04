// Turns simulator screenshots (1206 × 2622 PNG, iPhone 17) into the WebP files
// the site shows. Usage: npm run screens -- <dir with the PNGs>
// The PNG names it expects are listed in SCREENS.
import sharp from "sharp";
import path from "node:path";

const SCREENS = {
  "01-home.png": "home.webp",
  "02-parks-map.png": "parks-map.webp",
  "03b-park-sheet.png": "park-card.webp",
  "05b-ladder.png": "ladder.webp",
  "08-programs.png": "programs.webp",
  "06-profile.png": "profile.webp",
};

const source = process.argv[2];
if (!source) {
  console.error("Usage: npm run screens -- <dir with simulator PNGs>");
  process.exit(1);
}
const target = path.join(import.meta.dirname, "..", "public", "screens");

for (const [input, output] of Object.entries(SCREENS)) {
  const info = await sharp(path.join(source, input))
    .resize({ width: 600, height: 1304, fit: "cover", position: "top" })
    .webp({ quality: 82, effort: 6 })
    .toFile(path.join(target, output));
  console.log(`${output}: ${Math.round(info.size / 1024)} KB`);
}
