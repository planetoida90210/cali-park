import type { NextConfig } from "next";

// Fully static site: `next build` writes plain HTML/CSS to `out/`. No server,
// no cookies, no runtime. Vercel serves it with the Next.js preset as is.
const nextConfig: NextConfig = {
  output: "export",
  images: { unoptimized: true },
  poweredByHeader: false,
};

export default nextConfig;
