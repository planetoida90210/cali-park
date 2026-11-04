import Image from "next/image";

// One app screenshot in a simple device frame. Screenshots are 600 × 1304
// WebP files in public/screens/, made by `npm run screens`.
export function PhoneShot({
  src,
  alt,
  caption,
  priority = false,
}: {
  src: string;
  alt: string;
  caption?: string;
  priority?: boolean;
}) {
  return (
    <figure className="phone">
      <div className="phone__frame">
        <Image
          src={src}
          alt={alt}
          width={600}
          height={1304}
          sizes="(max-width: 640px) 70vw, 280px"
          priority={priority}
          className="phone__screen"
        />
      </div>
      {caption ? <figcaption className="phone__caption">{caption}</figcaption> : null}
    </figure>
  );
}
