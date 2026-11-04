// SWAP POINT for the brand. The app icon is not chosen yet (W-icon), so the
// site uses a neutral mark (a pull-up bar on a lime tile) and the text
// "CaliPark". When the icon lands:
//   1. replace <BrandMark> below with the icon artwork (e.g. an <img> from
//      `public/brand/`),
//   2. regenerate `app/icon.svg`, `app/apple-icon.png` and
//      `app/opengraph-image.png` (see README, "Brand assets").
// Every page gets the brand only through this file.

export function BrandMark({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 32 32" aria-hidden="true" focusable="false">
      <rect width="32" height="32" rx="8" fill="#D1FF00" />
      <path d="M6 10h20M10 10v14M22 10v14" stroke="#121212" strokeWidth="3" strokeLinecap="round" />
    </svg>
  );
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
