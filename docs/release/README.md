# Wydanie: co musi się stać przed zewnętrznym TestFlightem

Stan 2026-11-04. Szkice są gotowe: strona w `site/` (nieopublikowana), [teksty do App Store](app-store-listing.md), [odpowiedzi „App Privacy”](app-privacy.md).

- **[Dzień zakupu konta](checklist.md):** krok po kroku od App ID do zewnętrznego TestFlightu, numery kompilacji, sprawdzenie archiwum bez konta.
- **[Przegląd wytycznych App Review](app-review.md)** dla 1.0 z samym treningiem: ryzyka z numerami wytycznych i pytania do właściciela.

## Decyzje

- **Nazwa w App Store:** „CaliPark: kalistenika”, podtytuł „Trening na drążku z planem” (Q39).
- **TestFlight:** zewnętrzni testerzy tylko z zaproszeń mailowych od właściciela, bez publicznego linku (Q40). `testFlightURL` na stronie zostaje `null`.
- **Etykieta prywatności:** „Data Not Collected” (Q41); uzasadnienie w [app-privacy.md](app-privacy.md). Zmienia się dopiero z Kontem, Społecznością albo syncem.
- **Strona:** Vercel właściciela (Q32), tekst gotowy do publikacji (Q42); publikacja czeka na punkty niżej.

## Blokery (właściciel, kiedy będzie gotowy)

Bez nich nie da się opublikować polityki prywatności, a bez polityki Apple nie wpuści zewnętrznego TestFlightu. Wszystko i tak czeka na płatne konto Apple Developer (ticket 017).

1. **Apple Developer Program** (99 USD/rok, ticket 017): bundle ID, zespół, podpisywanie, App Store Connect.
2. **Domena** (Q35, odłożone) podpięta w Vercelu; `NEXT_PUBLIC_SITE_URL`.
3. **Mail kontaktowy** na domenie (Q36, odłożone); ten sam adres w `site/content/site.ts` i w `SupportContact.email` w apce.
4. **Administrator danych** w polityce prywatności (Q37). RODO (art. 13) wymaga podania, kto jest administratorem; konto Apple Developer osoby prywatnej i tak pokazuje imię i nazwisko w App Store. Do tego czasu placeholder `[IMIĘ I NAZWISKO]`, strona nieopublikowana.
5. Publikacja strony, potem link do polityki w apce („O apce”) i w App Store Connect.

`grep -rn PLACEHOLDER site/` pokazuje wszystkie miejsca do uzupełnienia.
