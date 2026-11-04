// The brand on the site. Every page gets it only through this file.
// The mark is the app icon on a rounded tile, generated into
// `public/brand/mark.svg` by `node scripts/brand/build-icons.mjs` at the repo
// root (together with `app/icon.svg`, `app/apple-icon.png` and the OG image).
// To change the icon, change `brand/ACTIVE` and rerun that script; this file
// does not change.

export function BrandMark({ className }: { className?: string }) {
  // A plain <img>: the site is a static export with unoptimized images.
  return <img className={className} src="/brand/mark.svg" alt="" aria-hidden="true" width={32} height={32} />;
}

export function Wordmark({ size = "md" }: { size?: "md" | "lg" }) {
  return (
    <span className={`wordmark wordmark--${size}`}>
      <BrandMark className="wordmark__mark" />
      <span>
        Cali<span className="wordmark__accent">Park</span>
      </span>
    </span>
  );
}
