import type { ReactNode } from "react";

/** A readable text page: title, optional lead and meta line, then the body. */
export function ProsePage({
  title,
  lead,
  meta,
  children,
}: {
  title: string;
  lead?: ReactNode;
  meta?: ReactNode;
  children: ReactNode;
}) {
  return (
    <article className="container prose">
      <header className="prose__header">
        <h1>{title}</h1>
        {meta ? <p className="prose__meta">{meta}</p> : null}
        {lead ? <p className="prose__lead">{lead}</p> : null}
      </header>
      {children}
    </article>
  );
}

/** The contact address, with a visible marker while it is still a placeholder. */
export function ContactEmail({ email }: { email: string }) {
  if (email.startsWith("[")) {
    return <mark className="placeholder">{email}</mark>;
  }
  return <a href={`mailto:${email}`}>{email}</a>;
}
