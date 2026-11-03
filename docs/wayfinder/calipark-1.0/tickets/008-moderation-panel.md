---
title: Panel moderacji: w apce, strona www czy oba
type: grilling
mode: HITL
status: closed
assignee: planetoida90210
blocked_by: [007]
---

# Panel moderacji: w apce, strona www czy oba

## Pytanie

Gdzie właściciel i ekipa moderują Zgłoszenia, zdjęcia i zgłoszone opinie? Opcje:
- w apce (rola Moderatora),
- na osobnej stronie www,
- w obu miejscach.

Na dużym ekranie przegląda się wygodniej, ale strona www to druga aplikacja do zbudowania i zabezpieczenia. Apple nie wymaga panelu www. Część backendów ma gotowy panel admina, a to rozstrzyga „Wybór backendu”.

## Kontekst z researchu (2026-11-03)

DSA wymaga formularza zgłoszeń dostępnego dla każdego, także bez Konta, oraz zapisanego uzasadnienia każdego usunięcia. Apple 1.2 wymaga reakcji na zgłoszenia w 24h. Panel musi to obsłużyć.

## Rozstrzygnięcie (2026-11-04)

**Panel moderacji to mała strona www tylko dla Moderatorów. W apce jest tylko zgłaszanie treści.** Właściciel potwierdził rekomendację.

- Logowanie przez Supabase Auth, rola Moderatora sprawdzana w bazie (RLS), nie tylko w UI.
- Każde usunięcie zapisuje uzasadnienie (DSA art. 17). Kolejka obsługuje Zgłoszenia Parków, zdjęcia i zgłoszone opinie, z reakcją w 24h (Apple 1.2).
- Formularz zgłoszeń treści działa też bez Konta (DSA).
- Supabase Studio nie służy ekipie jako panel, bo daje pełny dostęp do bazy.
