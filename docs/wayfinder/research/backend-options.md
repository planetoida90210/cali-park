# Backend options for Parks and Community (CaliPark 1.0)

Research date: 2026-11-03. Prices, quotas and rules change, so every number below links to its primary source. Anything marked **(estimate)** is my own assumption or calculation, not a vendor figure. The owner makes the decision. This document only lays out the trade-offs.

Scope: the backend for Parks (map, details, equipment) and Community (reviews with ratings, photos, report/block/moderation, park submissions) in v1. Training data stays local, and moving it to a new phone is a separate question (see "Interplay with training-data sync" below).

## Answer

- **Supabase Cloud (Pro plan, `eu-central-1` Frankfurt) fits best by default.** It covers every hard requirement with first-party features: native Sign in with Apple, PostGIS nearest-park queries, row-level security, storage with a CDN, and an EU region. The owner has already shipped it about 10 times.
- **The worry that Supabase gets expensive doesn't hold for this app's traffic.** Under the cost model below, CaliPark stays on the flat **$25/month** Pro plan up to about 45,000 MAU, and costs about $26 at 50,000 MAU. Photo egress is the only line that grows. Pro's spend cap is on by default ([pricing](https://supabase.com/pricing)), but **the cap doesn't bill overage. It blocks it.** Once a usage item such as egress passes its quota, "further usage of that item is disallowed until the next billing cycle" ([Control your costs](https://supabase.com/docs/guides/platform/cost-control)). Under the model, photos would stop loading late in the month from about 45,000 MAU. Before that point, turn the cap off and set usage alerts.
- **Self-hosting Supabase on Hetzner doesn't save money at this scale.** Hetzner raised prices in 2026, and the 4 GB VPS that self-hosted Supabase needs at minimum costs about €24/month with backups. That is roughly the same as Supabase Cloud Pro, and you also take on 11 containers to operate (13 with the optional logging stack).
- **The real alternative is a small custom API on Hetzner with Postgres/PostGIS and R2.** It costs about €15–31/month at every MAU tier (excl. VAT), keeps data at rest in the EU, and makes photo egress almost free. Only Hetzner is an EU company here. Cloudflare (R2) is a US company, and its CDN caches photos worldwide. For an all-EU-company setup, use Hetzner Object Storage instead of R2. The price is several weeks of building plus permanent ops work. **Writing it in Rust doesn't by itself make it safer.** The application code of every option here is already written in memory-safe languages, and the risks that matter (authorization, validation, abuse) are logic bugs that Rust doesn't prevent.
- **PocketBase is the cheapest EU-only option to run, but it's pre-1.0, has no official Swift SDK and no documented native Sign in with Apple ID-token flow.** **Firebase** runs Auth only in US data centers, has no hard spend cap and locks you in more. **The CloudKit public database** costs nothing, but nothing on the server checks writes, so you can't validate them, rate-limit them or verify a purchase before one. It also replaces Sign in with Apple with the user's iCloud identity. It is a poor fit for spam-resistant Community content.

## Findings

### 1. Requirements that apply to every option

Apple sets these regardless of backend.

- **UGC rules (Guideline 1.2).** Apps with user-generated content must have "A method for filtering objectionable material from being posted", "A mechanism to report offensive content and timely responses to concerns", "The ability to block abusive users from the service", and published contact information ([App Review Guidelines 1.2](https://developer.apple.com/app-store/review/guidelines/#user-generated-content)). A pending queue (pre-moderation) is the simplest way to meet the first item.
- **Account deletion (5.1.1(v)).** An app that supports account creation must offer deletion inside the app ([guidelines](https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage)). Apple's support page tells you to "delete the entire account record, along with associated personal data", and says "only offering to temporarily deactivate or disable an account is insufficient". It adds that people expect deletion to cover **"user-generated content that's shared with others, such as photos, videos, text posts, and reviews"**. Plan for reviews and photos to go with the account. Apps using Sign in with Apple "should use the Sign in with Apple REST API to revoke user tokens". The same page says to "Use server-to-server notification endpoints to process changes for Sign in with Apple accounts" ([Offering account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/)). If you follow that advice, you need a small HTTPS endpoint registered for the App ID, whichever backend you choose. Supabase Auth explicitly doesn't support these notifications (see below). I didn't check whether Firebase handles them.
- **Sign in with Apple token revocation** goes through `POST https://appleid.apple.com/auth/revoke` with `client_id`, `client_secret`, `token` and `token_type_hint` ([Revoke tokens](https://developer.apple.com/documentation/signinwithapplerestapi/revoke-tokens)). `client_secret` is a JWT signed with your `.p8` key, and it may not expire more than 15,777,000 seconds (six months) in the future ([Creating a client secret](https://developer.apple.com/documentation/accountorganizationaldatasharing/creating-a-client-secret)). Revocation therefore needs a small piece of server code holding the `.p8` key, in every option except CloudKit.
- **Server-side token check.** A server verifying an identity token must check the ES256 signature, `nonce`, `iss = https://appleid.apple.com`, `aud = client_id` and `exp` ([Verifying a user](https://developer.apple.com/documentation/signinwithapple/verifying-a-user)).
- **Stable identity.** Sign in with Apple user identifiers are **developer-team-scoped** ([TN3159](https://developer.apple.com/documentation/technotes/tn3159-migrating-sign-in-with-apple-users-for-an-app-transfer)). Storing Apple's `sub` as the canonical user key therefore keeps accounts portable across any backend migration. Changing developer team later, for example from individual to company, needs a transfer migration. TN3159 gives a 60-day window after the app transfer for it.
- **Anti-spam signal.** `realUserStatus` hints whether the user "appears to be a real person". Apple calls it one input for fraud prevention, not a guarantee ([realUserStatus](https://developer.apple.com/documentation/authenticationservices/asauthorizationappleidcredential/realuserstatus)).
- **Paid membership is a prerequisite.** Sign in with Apple, CloudKit and App Attest are listed as Apple Developer Program capabilities, not free-account ones ([Supported capabilities (iOS)](https://developer.apple.com/help/account/reference/supported-capabilities-ios)). The fee is 99 USD/year, "in local currency where available" ([Purchase and activation](https://developer.apple.com/support/purchase-activation/)). **You can't test Sign in with Apple end to end on any backend until the membership is bought.** Backend work can start with a dev-only login.
- **Contribution paywall.** Unlocking a feature must use In-App Purchase (Guideline 3.1.1, [guidelines](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)). Enforcing "only paying users can submit" needs server code that verifies StoreKit signed transactions. Apple ships an App Store Server Library for [Swift](https://github.com/apple/app-store-server-library-swift) and [Node](https://github.com/apple/app-store-server-library-node).
- **GDPR.** A processor must be bound by an Art. 28 contract, which in practice is the vendor's DPA, and data subjects have the right to erasure under Art. 17 ([GDPR](https://eur-lex.europa.eu/eli/reg/2016/679/oj)). US transfers can rely on the EU-US Data Privacy Framework adequacy decision ([Decision 2023/1795](https://eur-lex.europa.eu/eli/dec_impl/2023/1795/oj)) or on SCCs. The DPF survived a first annulment action: the General Court dismissed *Latombe v Commission* (T-553/23) on 3 September 2025. An appeal to the Court of Justice is reported as pending. I took both facts from secondary sources and couldn't open the court register, so treat them as **(unverified)** ([Hogan Lovells summary](https://www.hlc.com/en/publications/transatlantic-data-transfers-eu-general-court-upholds-dat-privacy-framework)). Supabase's DPA uses SCCs and doesn't mention the DPF. Cloudflare's DPA cites both (see below).
- **EU Digital Services Act (missing from the original draft, and it applies to every option).** A Park/review/photo service is a hosting service under the DSA, and probably an "online platform". Two obligations apply even to micro and small enterprises. Art. 16 requires a notice-and-action mechanism for reporting illegal content. Art. 17 requires a "statement of reasons" to the affected user whenever you remove or restrict their content. Art. 19 exempts micro and small enterprises from the further platform duties in Section 3, such as Art. 20 internal complaint handling, but not from Art. 16–17 ([DSA, Regulation 2022/2065](https://eur-lex.europa.eu/eli/reg/2022/2065/oj)). I read the article structure from an [OJ-text mirror](https://www.springlex.eu/en/packages/dsa/dsa-regulation/article-19/) because EUR-Lex blocked automated access. The moderation data model therefore needs a stored reason for every rejection or removal, on any backend. **Whether CaliPark counts as an online platform, and what exactly it must show users, needs a legal check (unverified).**

### 2. Option-by-option facts

#### Supabase Cloud

- **Pricing** ([supabase.com/pricing](https://supabase.com/pricing)):
  - **Free:** 50,000 MAU, 500 MB DB, 1 GB file storage, 5 GB egress plus 5 GB cached egress, no automatic backups, a limit of 2 active projects. "Free projects are paused after 1 week of inactivity."
  - **Pro:** from $25/month with $10 compute credits, which cover one Micro instance. Includes 100,000 MAU (then $0.00325/MAU), 8 GB disk (then $0.125/GB), 100 GB storage (then $0.0213/GB), 250 GB egress (then $0.09/GB) and 250 GB cached egress (then $0.03/GB). Daily backups are kept 7 days, and PITR costs $100/month. Image transformations include 100 origin images, then $5 per 1,000. "Spend caps are on by default on the Pro Plan." Micro compute is $10/month and Small is $15/month.
- **What the spend cap actually does.** "After exceeding the quota for a usage item, further usage of that item is disallowed until the next billing cycle. You don't get charged for over-usage but your services will be restricted according to our Fair Use Policy if you consistently exceed the quota." The cap covers egress, storage size, disk size, MAU and Edge Function invocations, among others. It doesn't cover compute, PITR, custom domains or IPv4 ([Control your costs](https://supabase.com/docs/guides/platform/cost-control)). The cap protects against a bill shock, but it doesn't keep the app running: at the quota, photos stop loading. With the cap off, overage is billed at the rates above.
- **A second project costs extra (estimate).** The $10 credit covers one Micro instance. A separate staging project in the same Pro organization would add about $10/month of compute, based on the Micro price above.
- **Backups.** Pro keeps 7 daily backups. **Storage objects are not in database backups** ([Backups](https://supabase.com/docs/guides/platform/backups)).
- **Regions.** EU regions are Ireland `eu-west-1`, Paris `eu-west-3`, Frankfurt `eu-central-1` and Stockholm `eu-north-1`. London and Zurich are listed too but are outside the EU ([Regions](https://supabase.com/docs/guides/platform/regions)).
- **DPA.** The DPA "supplements and forms part of the Supabase Terms of Service", so you accept it with the ToS. It uses EU SCCs (2021/914) and does not mention the DPF. The contracting party is **Supabase Pte. Ltd., Singapore** ([DPA](https://supabase.com/legal/dpa)). Subprocessors are listed at [subprocessor list](https://supabase.com/legal/customer-resources/subprocessor-list).
- **Sign in with Apple.** Native Swift uses `signInWithIdToken` with the Apple identity token. "Native-only implementations don't require secret key rotation." Apple sends the full name only on the first sign-in, so save it with `update(user:)`. Supabase Auth "does not support Server-to-Server notification endpoints" ([Apple login guide](https://supabase.com/docs/guides/auth/social-login/auth-apple)). Token revocation on deletion is not built in. You write an Edge Function that exchanges an authorization code the client sends at deletion time, then calls `/auth/revoke`.
- **Account deletion.** `auth.admin.deleteUser()` exists. Users are rows in `auth.users`, and your tables cascade only if their FK says `on delete cascade`. **"You cannot delete a user if they are the owner of any objects in Supabase Storage"**, so delete photos first ([Managing user data](https://supabase.com/docs/guides/auth/managing-user-data)).
- **Geo.** PostGIS `geography(POINT)` with a GIST index, ordered by the `<->` KNN operator inside a SQL function called via `rpc()`. Install PostGIS in the `extensions` schema ([PostGIS on Supabase](https://supabase.com/docs/guides/database/extensions/postgis), [PostGIS `<->`](https://postgis.net/docs/geometry_distance_knn.html)).
- **Security model.** "Enable RLS on every table in an exposed schema". A table without RLS "is readable and writable by any role with a grant on it". The secret/service_role key bypasses RLS and must stay server-side ([RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)). The Security Advisor flags `rls_disabled_in_public` as ERROR, and the CLI runs it with `supabase db advisors` ([Database advisors](https://supabase.com/docs/guides/database/database-advisors)). Getting RLS wrong is the typical real-world failure. CVE-2025-48757 describes Lovable-generated apps whose "insufficient database Row-Level Security policy" let unauthenticated attackers "read or write to arbitrary database tables". The supplier disputes it, because each customer is responsible for protecting their own app's data ([NVD](https://nvd.nist.gov/vuln/detail/CVE-2025-48757)). Either way, it shows that RLS is your code, not the vendor's.
- **Rate limiting and anti-abuse.** RLS controls who may write, not how often. Supabase has no built-in per-user write rate limit for the Data API. The documented approach is a `pgrst.db_pre_request` function, which can enforce "per-IP or per-user rate limits" but only on `POST`, `PUT`, `PATCH` and `DELETE` ([Securing your API](https://supabase.com/docs/guides/api/securing-your-api)). I found no first-party counterpart to Firebase App Check. App Attest or StoreKit transaction checks would go in an Edge Function that you write. Third-party helpers exist, such as [supabase-integrity-attest](https://github.com/bradford-tech/supabase-integrity-attest), but I haven't assessed them.
- **Moderator role.** A `user_roles` table plus a Custom Access Token Hook puts a `user_role` claim in the JWT, and an `authorize()` function reads it inside RLS policies ([RBAC guide](https://supabase.com/docs/guides/database/postgres/custom-claims-and-role-based-access-control-rbac)). For a solo owner, Studio's table editor works as the moderation queue: filter `status = 'pending'`.
- **Storage/CDN.** Smart CDN is on for "Pro Plan and above". Public buckets cache best, and invalidation "can take up to 60 seconds" ([Smart CDN](https://supabase.com/docs/guides/storage/cdn/smart-cdn)).
- **Swift SDK.** `supabase-swift` v2.55.6 was released 2026-10-30 ([GitHub API](https://api.github.com/repos/supabase/supabase-swift/releases/latest)). It is MIT-licensed and needs iOS 16+, Swift 6.2+ and Xcode 26+. Modules: Auth, PostgREST, Storage, Realtime, Functions ([repo](https://github.com/supabase/supabase-swift)). It is a third-party SPM dependency, and the app has none today. You could also call the REST APIs directly with `URLSession`.
- **Exit path.** Plain Postgres means you can `pg_dump` and copy the S3 objects. The platform is open source: [supabase/supabase](https://github.com/supabase/supabase) is Apache-2.0 and [supabase/auth](https://github.com/supabase/auth) is MIT. You can move to self-hosting or to any Postgres host.

#### Supabase self-hosted on a Hetzner VPS

- **Requirements.** Minimum 4 GB RAM, 2 cores and 40 GB SSD. Recommended 8 GB+, 4 cores+ and 80 GB+.
- **Services.** Studio, Envoy (default API gateway, with Kong as an optional override), Auth, PostgREST, Realtime, Storage, imgproxy, postgres-meta, Postgres, Edge Runtime and Supavisor, which makes 11 containers. Logflare and Vector are optional: "The default configuration does not include Logs & Analytics."
- **Your responsibilities.** You set every secret ("never start your self-hosted Supabase using these defaults"), put HTTPS in front with a reverse proxy, and run updates with `update.sh` about monthly. Studio is protected only by HTTP basic auth. The guide doesn't cover backups ([Self-hosting with Docker](https://supabase.com/docs/guides/self-hosting/docker)).
- **Hetzner prices in 2026.** Hetzner raised prices for new orders and existing products from 1 April 2026 ([statement](https://www.hetzner.com/pressroom/statement-price-adjustment/)). From 15 June 2026 it raised them again for new orders and rescales, covering "All dedicated servers and cloud plans" ([announcement](https://www.hetzner.com/pressroom/standardization-and-price-adjustment-of-our-server-products/)). Resizing a server later therefore moves it to current prices. Prices on 2026-11-03, excl. VAT ([Cost-Optimized](https://www.hetzner.com/cloud/cost-optimized), [Regular Performance](https://www.hetzner.com/cloud/regular-performance)):
  - **Cost-Optimized:** CX23 (2 vCPU, 4 GB) €5.99/month, but **every Cost-Optimized plan was marked "not available"**. The page warns that "the number of available servers is limited."
  - **Regular Performance** (orderable on 2026-11-03): CPX02 (1 vCPU, 1 GB) €6.49, CPX12 (1 vCPU, 2 GB) €11.99, CPX22 (2 vCPU, 4 GB) €19.99, CPX32 (4 vCPU, 8 GB) €35.99. CPX22 and larger are offered in NBG1 and HEL1 only, not FSN1.
  - **Traffic:** EU cloud servers include at least 20 TB, then €1/TB.
  - **Backups:** 20% of the server price for 7 daily slots ([Billing FAQ](https://docs.hetzner.com/cloud/billing/faq/), [Backups](https://docs.hetzner.com/cloud/servers/backups-snapshots/overview/)).
  - **IPv4:** a primary IPv4 costs €0.50/month excl. VAT ([IP pricing](https://docs.hetzner.com/general/others/ipv4-pricing/)). The plan pages have a "Price incl. IPv4" toggle, so check whether the price you see already includes it.
  - **VAT (estimate):** all Hetzner, Supabase, Google and Cloudflare prices here exclude VAT. If the owner buys as a private person rather than a VAT-registered business, expect Polish VAT, standard rate 23%, on top. This depends on the vendor and the owner's tax status **(unverified)**.
- **Hetzner Object Storage.** €6.49/month including 1 TB storage and 1 TB egress. Locations are FSN1, NBG1 and HEL1 ([Object Storage](https://www.hetzner.com/storage/object-storage/)).
- **Hetzner DPA.** You conclude it in the customer account. Hetzner is the processor, and the data centres are in Germany and Finland ([Data privacy FAQ](https://docs.hetzner.com/general/general-terms-and-conditions/data-privacy-faq/)).

#### Firebase

- **Pricing** ([firebase.google.com/pricing](https://firebase.google.com/pricing)):
  - **Auth (Identity Platform):** free up to 50,000 MAU on both plans, then $0.0055/MAU from 50k to 100k ([Identity Platform pricing](https://cloud.google.com/identity-platform/pricing)).
  - **Firestore Standard free tier:** 50,000 reads/day, 20,000 writes/day, 20,000 deletes/day, 1 GiB stored, 10 GiB/month egress.
  - **Firestore in Warsaw (`europe-central2`):** $0.039 per 100k reads, $0.117 per 100k writes, $0.195/GiB-month ([Firestore pricing](https://cloud.google.com/firestore/pricing)).
  - **Cloud Functions:** Blaze only, 2M invocations/month free.
- **Cloud Storage for Firebase.** A Blaze plan is required to provision a default bucket. Spark projects lost access to all buckets from **3 February 2026**. The no-cost tier applies **only to buckets in `us-central1`, `us-east1` and `us-west1`** ([Storage changes FAQ](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024)). An EU bucket in Warsaw is billed from the first byte: $0.023/GiB-month storage ([Cloud Storage pricing](https://cloud.google.com/storage/pricing)) and **$0.12/GiB** internet egress for 0–10 TiB.
- **Budgets.** Budget alerts "do not pause services". Hard spend caps exist only for Functions, App Hosting, AI Logic and Extensions ([Avoid surprise bills](https://firebase.google.com/docs/projects/billing/avoid-surprise-bills)).
- **Geo.** Firestore Standard uses geohash range queries: "There can be up to 9 pairs of bounds depending on overlap, but in most cases there are 4." You "have to filter out false-positive results on the client side", and "These extra reads add cost and latency to your app" ([Geo queries](https://firebase.google.com/docs/firestore/solutions/geoqueries)). Native `geoDistance` search exists only on a **Firestore Enterprise edition** database, which has different pricing ([Geospatial query](https://firebase.google.com/docs/firestore/enterprise/geospatial-query)).
- **Sign in with Apple.** Firebase uses a nonce and `OAuthProvider.appleCredential`. For deletion, the user re-authenticates and the app calls `Auth.auth().revokeToken(withAuthorizationCode:)`, then deletes the user and their data ([Firebase Apple auth](https://firebase.google.com/docs/auth/ios/apple)). This is the most turnkey revocation flow of all the options. It still needs a Services ID and the OAuth code-flow configuration set up in Firebase first.
- **GDPR.** Google acts as processor under the Data Processing and Security Terms, and Google complies with the DPF. **"The Firebase Authentication service is run only from US data centers."** Firestore, Storage and Functions are "global services" unless a location is selected ([Firebase privacy](https://firebase.google.com/support/privacy)).
- **Security model.** Security Rules plus custom claims for a moderator role ([custom claims](https://firebase.google.com/docs/auth/admin/custom-claims)). App Check with an App Attest provider is built in ([App Attest provider](https://firebase.google.com/docs/app-check/ios/app-attest-provider)), which is the strongest out-of-the-box anti-abuse tool among these options.
- **Swift SDK.** `firebase-ios-sdk` 13.1.1 was released 2026-10-22. Version 13.0.0 (2026-10-07) requires iOS 15+ and Xcode 26.2+. It dropped CocoaPods and now ships "exclusively through Swift Package Manager and binary distributions" ([release notes](https://firebase.google.com/support/release-notes/ios)). It is mature but heavy.
- **Exit path.** Firestore export goes to GCS ([export/import](https://firebase.google.com/docs/firestore/manage-data/export-import)). The data model, rules and SDK calls are proprietary, so leaving means rewriting the client data layer.

#### CloudKit public database

- **Cost.** Apple advertises "up to 1PB of storage for your app's public data" ([CloudKit](https://developer.apple.com/icloud/cloudkit/)) but **publishes no current numeric public-database quotas or overage prices** on a primary page. The figures circulating in forums are user-posted and dated ([example thread, 2020](https://developer.apple.com/forums/thread/660009)). The DPLA says "Apple reserves the right to charge fees for Your use of the Apple Services" (§2.8). Attachment 4 §2.1 adds that there are "storage capacity, transmission, and transactional limits for the iCloud service" ([DPLA](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)).
- **Identity.** CloudKit doesn't use Sign in with Apple. Anyone can read the public database without an iCloud account, but "Saving records to the public database requires an active iCloud account" ([CKContainer](https://developer.apple.com/documentation/cloudkit/ckcontainer)). Your "Account" would effectively become the iCloud identity, which changes the decision "accounts only via Sign in with Apple".
- **Permissions.** Roles are World, Authenticated and Creator, with read/write/create permissions per record type ([Designing with CloudKit](https://developer.apple.com/icloud/cloudkit/designing/)). Users "have write access to the records … they create", and you can "assign roles to users and restrict access" in the developer portal ([publicCloudDatabase](https://developer.apple.com/documentation/cloudkit/ckcontainer/publicclouddatabase)). **No server-side code runs on writes.** Beyond the field types, you can't validate values (for example a rating outside 1–5), rate-limit, verify App Attest, or verify an IAP before a write. Server-to-server keys only let your own scripts access the public database ([CloudKit Web Services](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html)).
- **Geo.** The `distanceToLocation:fromLocation:` predicate does radius queries, and "Location indexes have a resolution of no less than 10 km" ([CKQuery](https://developer.apple.com/documentation/cloudkit/ckquery)). `CKLocationSortDescriptor` sorts by distance ([docs](https://developer.apple.com/documentation/cloudkit/cklocationsortdescriptor)).
- **Contract risks** ([DPLA, Attachment 4](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)):
  - **Paywall conflict (interpretation).** "You may not charge any fees to users for access to or use of the iCloud service through Your Applications" (§2.2). Read literally, that conflicts with charging for the right to post into a CloudKit database. Whether Apple treats a paid in-app feature that happens to store data in CloudKit as "charging for iCloud" is a legal reading I couldn't confirm **(unverified)**. Either way the technical blocker stands: CloudKit runs no server code on writes, so it can't check a StoreKit transaction before accepting a submission.
  - **Data deletion on lapse.** For public containers, "Apple reserves the right to suspend access to or delete such data … upon expiration or termination of Your Agreement" (§1.2).
  - **No DPA.** I found no separate CloudKit data processing agreement. EU-based *organizations* get extra EU Data Act terms ([PDF](https://developer.apple.com/download/files/EU-Data-Act-Terms-CloudKit.pdf)).
  - **No region choice.** You can't pick a data region.
- **Swift.** CloudKit is a first-party framework with zero dependencies, and it is Apple-only.

#### PocketBase on a VPS

- **Maturity.** The latest release is v0.40.6 (2026-10-23) ([GitHub API](https://api.github.com/repos/pocketbase/pocketbase/releases/latest)), and the docs header shows v0.41.1. The README says "full backward compatibility is not guaranteed before reaching v1.0.0", and the license is MIT ([README](https://github.com/pocketbase/pocketbase)).
- **Scaling.** The FAQ says it scales "Only on a single server", uses embedded SQLite in WAL mode, and claims "10 000+ persistent realtime connections on a cheap $4 Hetzner CAX11 VPS". The "$4" is out of date: CAX11 is now €6.49 and marked "not available" (see Hetzner above). The FAQ also says "There are no promises for maintenance and support beyond what is already available" ([FAQ](https://pocketbase.io/faq/)).
- **SDKs.** Official SDKs exist for JavaScript and Dart only. **There is no official Swift SDK.** A few small community packages exist (the largest has about 60 GitHub stars and was last pushed in 2023), so in practice you call the REST API with `URLSession`.
- **Sign in with Apple.** PocketBase supports OAuth2 through an all-in-one popup flow or a manual code exchange with `authWithOAuth2Code` ([Authentication](https://pocketbase.io/docs/authentication/)). **An ID-token flow for native iOS isn't documented.** A native app would need a custom route ([Go](https://pocketbase.io/docs/go-routing/) or [JS](https://pocketbase.io/docs/js-routing/) hooks) that verifies the Apple token and issues a PocketBase token **(needs a prototype)**.
- **Geo.** The `geoPoint` field type works with a `geoDistance(lonA, latA, lonB, latB)` Haversine filter ([API rules and filters](https://pocketbase.io/docs/api-rules-and-filters/)). The docs mention no spatial index. Scanning ≤10,000 Parks is fine **(estimate)**.
- **Security.** API rules are filter expressions using `@request.auth` and `@collection`. A null rule means superuser-only.
- **Operations.** A built-in rate limiter ships from v0.23 and is "highly recommended", and v0.38+ adds a superuser IP whitelist. Built-in backups (ZIP of `pb_data`) can go to S3 ([Going to production](https://pocketbase.io/docs/going-to-production/)). Files live on local disk or in S3, and thumbnails cover jpg/png/gif and "partially webp" ([Files](https://pocketbase.io/docs/files-handling/)). The superuser dashboard works as a ready-made moderation UI for a solo owner.

#### Custom API (Rust/Axum or Swift) + Postgres/PostGIS + S3-compatible storage

- **Building blocks.** [Axum](https://github.com/tokio-rs/axum) (MIT, v0.8.9) and [sqlx](https://github.com/transact-rs/sqlx) (MIT or Apache-2.0, compile-time-checked SQL; the repo moved from `launchbadge/sqlx`), or Swift with [Vapor](https://vapor.codes/) or [Hummingbird](https://hummingbird.codes/). The client can be generated with [swift-openapi-generator](https://github.com/apple/swift-openapi-generator) or hand-written with `URLSession`.
- **Geo.** The same PostGIS KNN `<->` query as Supabase.
- **Photos on Cloudflare R2** ([pricing](https://developers.cloudflare.com/r2/pricing/)):
  - **Price:** $0.015/GB-month, Class A $4.50/M, Class B $0.36/M, **egress free**.
  - **Free tier:** 10 GB-month, 1M Class A and 10M Class B per month.
  - **EU jurisdiction:** jurisdictional restrictions "guarantee objects in a bucket are stored within a specific jurisdiction". The jurisdiction can't be changed after the bucket is created ([data location](https://developers.cloudflare.com/r2/reference/data-location/)). The guarantee covers objects at rest. The page says nothing about the CDN cache.
  - **Serving:** `r2.dev` is rate-limited and "should only be used for development purposes". Production needs a custom domain on a Cloudflare zone, which gets Cloudflare Cache ([public buckets](https://developers.cloudflare.com/r2/buckets/public-buckets/)). Cloudflare Cache serves from its global edge network, so cached copies may sit outside the EU. I found no primary statement limiting R2 caching to the EU **(unverified)**.
  - **DPA:** the contracting party is Cloudflare, Inc. (San Francisco, USA). The DPA (v6.4, effective 3 April 2026) cites the 2021/914 SCCs and says "Cloudflare complies with the Data Privacy Framework" ([DPA](https://www.cloudflare.com/cloudflare-customer-dpa/)). **R2 is therefore not an "EU company" option.**
- **Hetzner Object Storage** (€6.49/month, 1 TB storage and 1 TB egress included) is the all-EU-company alternative to R2.
- **What you build yourself.** Apple token verification, sessions, authorization on every endpoint, input validation, rate limiting, presigned uploads, the moderation queue, reports and blocks, account deletion with Apple revoke, an admin UI, DB migrations, backups ([pgBackRest](https://pgbackrest.org/)), TLS, OS patching and monitoring.

### 3. Comparison against the criteria

| Criterion | Supabase Cloud | Supabase self-host (Hetzner) | Firebase | CloudKit public DB | PocketBase (VPS) | Custom API + PostGIS + R2 |
|---|---|---|---|---|---|---|
| Sign in with Apple | Native `signInWithIdToken`, no secret rotation for native-only | Same | Native, nonce-based | Not used; iCloud identity instead | OAuth2 code flow; native ID-token flow needs custom route | You implement token verification |
| Nearest Parks | PostGIS KNN `<->` + GIST | Same | Geohash ranges + client filtering (Standard); native only on Enterprise edition | Radius predicate, ≥10 km index resolution, distance sort | `geoDistance()` filter, no spatial index documented | PostGIS KNN |
| Photos & egress | 250 GB + 250 GB cached in Pro, then $0.09 / $0.03 per GB with the spend cap off; with the cap on (default), egress stops at quota; Smart CDN | Disk or object storage; 20 TB VPS traffic included | EU bucket: $0.12/GiB egress from byte one | Within Apple's undisclosed quotas | Disk or S3; served via PocketBase | R2: egress $0 |
| Moderation workflow | `status` column + RLS + role claim; Studio as queue | Same (Studio behind basic auth) | Rules + custom claims + Functions; console as queue | Custom roles in console; no server checks on values | API rules + superuser dashboard as queue | Build it, including admin UI |
| Report / block | Tables + RLS | Same | Collections + rules | Record types; filtering only on client | Collections + rules | Build it |
| In-app account deletion | Edge Function: delete Storage objects, rows, Apple revoke, `deleteUser` | Same | `revokeToken(withAuthorizationCode:)` + `delete()` + Function for data | Delete Creator records from client; no SIWA to revoke | Delete record (cascade) + custom revoke hook | Build it |
| EU residency / DPA | EU region; DPA in ToS with SCCs; contract with Supabase Pte. Ltd. (SG); CDN cache is global | Fully EU (Hetzner DE/FI) + Hetzner DPA | Data in Warsaw possible, **Auth only in US**; Google DPA + DPF | No region choice; no separate DPA found | Fully EU (Hetzner) | Fully EU-company only with Hetzner Object Storage; with R2 the photos are stored in the EU, but Cloudflare, Inc. (US) is a processor and the cache is global |
| Swift SDK | Official, active (v2.55.6, Oct 2026) | Same SDK | Official, very mature, heavy (13.1.1) | First-party framework | No official SDK; small community packages; REST via `URLSession` | You write it (or OpenAPI-generated) |
| Security model | Postgres RLS + constraints + functions; Security Advisor; per-user write rate limits via `db_pre_request`, which you write | Same, plus you secure the host | Security Rules + App Check (App Attest) | Role per record type only | API rules + hooks + rate limiter | Whatever you write |
| Ops burden (1 person) | Low | High (11–13 services, updates, backups, TLS) | Low | None | Low–medium (one binary, OS, backups) | High |
| Lock-in / exit | Low: Postgres + S3, open source | Lowest | High (proprietary model) | Highest; data at risk if membership lapses | Low (SQLite file, MIT) | None |

### 4. Cost model

**Assumptions (all estimates).** MAU means people who open Parks in a month.

- 6 Parks sessions per MAU per month.
- Each session runs 1 list/map query (≈15 KB) and opens 2 park details (≈10 KB each, including the first 10 reviews). It loads 8 thumbnails (40 KB) and 2 full photos (300 KB, 1600 px long edge, compressed on device).
- That gives ≈5.5 MB photo egress plus ≈0.2 MB API egress per MAU per month, with no on-device caching (conservative).
- 10% of MAU sign in. 10% of MAU contribute 1 photo (340 KB for two renditions) and 1 review per month.
- Storage is shown after 12 months at a constant MAU.
- Firestore: about 100 document reads per session (geohash over-read included).
- Photo downloads: 10 per session.
- The database stays under 500 MB at every tier (≤10,000 Parks, ≤60,000 reviews).

| Derived usage | 100 MAU | 1,000 MAU | 10,000 MAU | 50,000 MAU |
|---|---|---|---|---|
| Egress per month (photos + API) | 0.57 GB | 5.7 GB | 57 GB | 287 GB |
| Photo storage after 12 months | 0.04 GB | 0.4 GB | 4.1 GB | 20.4 GB |
| Signed-in users (auth MAU) | 10 | 100 | 1,000 | 5,000 |
| Firestore reads per day | 2k | 20k | 200k | 1M |

**Monthly cost (estimate, vendor prices as cited above, excl. VAT).** The Apple Developer Program, 99 USD/year, is the same for every option and isn't included. Neither are domains nor VAT (see the VAT note under Hetzner).

| Option | 100 MAU | 1,000 MAU | 10,000 MAU | 50,000 MAU | Notes |
|---|---|---|---|---|---|
| Supabase Cloud | $0 Free (dev/TestFlight only) or **$25** Pro | **$25** | **$25** | **≈$26–30** | Free pauses after 7 days idle and has no backups, so use Pro once real users post. At 50k, photos exceed the 250 GB cached quota by ≈26 GB (≈$0.8) **only with the spend cap off**. With the default cap on, photo delivery stops for the rest of the month instead, from about 45k MAU. A Small compute upgrade would add ≈$5, and a staging project ≈$10. |
| Supabase self-hosted (Hetzner) | ≈€24 | ≈€24 | ≈€24–43 | ≈€43 | CPX22 €19.99 + 20% backups; CPX32 + backups for the recommended 8 GB. Add €0.50 for IPv4, and €6.49 if you use Hetzner Object Storage. CX23 (€5.99) would cut this in half if it becomes available again. |
| Firebase (Blaze, Warsaw) | ≈$0.1 | ≈$0.7 | ≈$9 | ≈$46 | At 50k: Storage egress ≈$33, Firestore reads ≈$11, plus ops and storage. Moving photos to R2 drops 50k to ≈$13. |
| CloudKit public DB | $0 | $0 | $0 | $0 (unverifiable) | Apple publishes no current quotas or overage prices. |
| PocketBase on Hetzner | ≈€8–15 | ≈€8–15 | ≈€15 | ≈€15 | CPX12 €11.99 + 20% backups + €0.50 IPv4. CPX02 (1 GB, €6.49) is enough for small loads **(estimate)**. Files on disk (20 TB traffic included) or R2 (≈$0.16 at 50k). |
| Custom API + PostGIS + R2 (Hetzner) | ≈€15–31 | ≈€15–31 | ≈€15–31 | ≈€15–31 | CPX12/CPX22 + backups + IPv4, optional Hetzner OS €6.49 for off-site DB backups. **Plus 4–8 weeks of build time (estimate)**. |

**Sensitivity (estimate).** Photo egress drives cost. If people browse 5× more photos (≈1.4 TB/month at 50k MAU):

- Supabase Pro: about $25 + $34 ≈ $59 if the photos are served from cache, or about $25 + $102 ≈ $127 if they aren't (cap off). With the cap on, photos stop loading once the quota is used up.
- Firebase: about $165 for Storage egress alone.
- R2 and Hetzner: still about €0 extra.

Cheap levers that work on every backend: resize and compress on device before upload, serve thumbnails in lists, set long `Cache-Control` headers, and use `URLCache` on device.

**One-off build effort (estimate, solo developer).** Supabase about 1–2 weeks (schema, RLS, 1–2 Edge Functions). Firebase about 1–2 weeks. PocketBase about 1–2 weeks plus the Sign in with Apple route. CloudKit about 1 week, plus moderation tooling inside the app. Custom API about 4–8 weeks, more if Rust is new to the owner.

### 5. Does writing the backend in Rust make it "safer"?

- **Memory safety is real, but it has already been won here.** Memory-safety bugs drove most CVEs in C/C++ codebases: about 70% at Microsoft and in Chromium (CISA/NSA, [The Case for Memory Safe Roadmaps](https://www.cisa.gov/sites/default/files/2023-12/The-Case-for-Memory-Safe-Roadmaps-508c.pdf)). Android cut them from 76% to 24% of its vulnerabilities by writing new code in memory-safe languages ([Google Security Blog, 2024](https://security.googleblog.com/2024/09/eliminating-memory-safety-vulnerabilities-Android.html)). The CISA appendix lists C#, Go, Rust and Swift among memory-safe languages. The application code of every alternative here is already written in memory-safe languages:
  - Supabase Auth is Go, PostgREST is Haskell, Storage is TypeScript, Realtime and Supavisor are Elixir, and Edge Runtime is already Rust (GitHub repo metadata: [auth](https://github.com/supabase/auth), [postgrest](https://github.com/PostgREST/postgrest), [storage](https://github.com/supabase/storage), [realtime](https://github.com/supabase/realtime), [supavisor](https://github.com/supabase/supavisor), [edge-runtime](https://github.com/supabase/edge-runtime)).
  - PocketBase is Go.
  - A Swift server is memory-safe too.

  Memory-unsafe code is still present in every stack, but it sits in shared, heavily scrutinized infrastructure rather than in your code. Postgres is C. The self-hosted Supabase gateway is Envoy (C++). imgproxy wraps libvips (C). Node/Deno run on V8 (C++). Every server option also runs on an OS kernel and a TLS library that are largely C. A Rust API would still sit on Postgres, a reverse proxy and the kernel. **Rust adds essentially no memory-safety margin over the other options.** (The language facts come from repo metadata and upstream projects. The claim that the components are "heavily scrutinized" is my judgement.)
- **The real risks are logic bugs, and no language prevents them.** The OWASP API Security Top 10 (2023) is: Broken Object Level Authorization, Broken Authentication, Broken Object Property Level Authorization, Unrestricted Resource Consumption, Broken Function Level Authorization, Unrestricted Access to Sensitive Business Flows (spam and fake reviews fall here), SSRF, Security Misconfiguration, Improper Inventory Management, and Unsafe Consumption of APIs ([OWASP](https://api-security.owasp.org/editions/2023/en/0x11-t10/)). For CaliPark, the work is:
  - per-row authorization (only the author edits a review, only moderators approve),
  - validation (rating 1–5, text length, image type and size, coordinates inside Poland),
  - rate limits and quotas per account,
  - App Attest or a paywall for submissions,
  - EXIF stripping,
  - correct deletion,
  - secrets handling (`.p8` key, service keys).
- **A custom server can be *less* safe.** Hand-rolled Apple token verification, sessions and authorization checks are exactly the OWASP top items. Supabase Auth and Firebase Auth have had far more scrutiny than a solo weekend project. Supabase's typical failure is a missing RLS policy, which its Security Advisor flags.
- **"Rust as an extra layer" in front of Supabase** adds a second place where authorization can be wrong, plus a second deploy. It's safer to keep the database as the single enforcement point (RLS, `CHECK` constraints, `SECURITY DEFINER` functions for moderation actions) and put the few privileged operations in Edge Functions.
- **When Rust or Swift on the server does help.** It helps if the owner wants full control, all-EU hosting, cheap egress, and custom abuse logic, or simply wants to learn. Choose for those reasons, not for "safety". If a custom server happens, Swift (Vapor/Hummingbird) shares `Codable` models with the app and is equally memory-safe.

### 6. Interplay with training-data sync

This is separate from Community. Training must never need an Account, and the data must survive a phone switch. The CloudKit **private** database fits that need without any app account. Its data "counts toward the user's iCloud storage quota", not the developer's ([CKContainer](https://developer.apple.com/documentation/cloudkit/ckcontainer)). That points to a hybrid regardless of the Community backend: Community on Supabase, PocketBase or custom, and training sync through iCloud. The sibling note [training-sync.md](training-sync.md) covers it.

## Recommendation

Ranked for CaliPark 1.0 as specified (Poland first, Sign in with Apple accounts, pre-moderated Community, solo developer, cost-sensitive). **The owner decides.** Each item says when that option wins.

1. **Supabase Cloud, Pro, Frankfurt `eu-central-1`.** It wins when you want the shortest path to a compliant v1 with the least ops and a database you can take with you.
   - **Coverage.** Native Sign in with Apple, PostGIS, RLS, storage with a CDN, daily backups and a spend cap are all first-party. The owner already knows it.
   - **Cost.** About $25/month up to about 45k MAU under the model above, and about $26 at 50k with the spend cap off.
   - **Conditions.** You accept a non-EU contracting party (Supabase Pte. Ltd.) with SCCs and EU-region hosting. You run Free only for development, because it pauses after 7 days idle. Run the Security Advisor in CI (`supabase db advisors`). Decide the spend-cap policy deliberately. The default cap avoids surprise bills, but it cuts photo delivery at quota, so switch it off with usage alerts once egress nears 250 GB/month. Build submission rate limits yourself (a `db_pre_request` check or a trigger) and keep pending photos out of the public bucket until approved.
   - **Exit.** If the cost worry ever comes true, the exit is `pg_dump`, which leads to option 2 or 5.
2. **Custom API (Swift or Rust) + Postgres/PostGIS on Hetzner + R2 or Hetzner Object Storage.** It wins if all-EU-company hosting becomes a hard requirement (then use Hetzner Object Storage, not R2, because Cloudflare is a US processor), if photo egress grows far beyond the model, or if the owner wants full control (paywall checks, App Attest, custom anti-spam) and accepts 4–8 weeks of build plus ongoing patching and backups. Pick the language for productivity and team fit, not "safety".
3. **PocketBase on Hetzner.** It wins if the goal is the lowest fixed cost (about €8–15/month) with all-EU hosting and a built-in admin UI, and the owner accepts pre-1.0 breaking changes, a single SQLite server, no official Swift SDK, and a custom native Sign in with Apple route that should be prototyped first.
4. **Firebase.** It wins if out-of-the-box App Check (App Attest), the most turnkey Sign in with Apple revocation and Google's SDK maturity outweigh three things: Auth processing only in the US, no hard spend cap, and the highest lock-in among the server options. Native geo also needs the Enterprise edition, or you live with geohash over-reads.
5. **Supabase self-hosted on Hetzner.** It wins only if you want Supabase's developer experience *and* EU-company hosting is mandatory. At 2026 Hetzner prices it costs about the same as Cloud Pro or more, with far more ops.
6. **CloudKit public database.** It wins only if zero cost, zero ops and zero dependencies matter more than everything else, and the owner accepts several trade-offs:
   - iCloud identity replaces Sign in with Apple.
   - There is no server-side validation or rate limiting, so ratings can be manipulated by a modified client.
   - It can't enforce a contribution paywall on the server, and DPLA §2.2 may forbid charging for it anyway (interpretation, unverified).
   - Location index resolution is 10 km or coarser.
   - Apple publishes no quotas.
   - Data is at risk if the membership lapses.

   It is a strong candidate for *training* sync in the private database, not for Community.

App-side advice that holds for any choice: hide the backend behind a repository protocol, matching the project's store-protocol convention, and key users by Apple's team-scoped `sub`. Switching later then becomes a data migration, not a rewrite.

## Open questions for the owner

1. Is "EU region + SCC-based DPA with a non-EU vendor" (Supabase, Google, Cloudflare) acceptable, or must every processor be an EU company? This one answer mostly decides between options 1 and 2.
2. How many hours per month will you spend on ops (OS and security updates, backup restore drills, uptime)? Zero rules out options 2, 3 and 5.
3. Contribution paywall: one-time IAP or subscription, and at launch or later? Either way, the server must verify StoreKit transactions, which also rules out CloudKit.
4. Moderation policy: pre-moderate everything (pending queue) or only first-time contributors and photos? Who moderates besides you, and what response time can you promise under Guideline 1.2? Every rejection or removal also needs a stored reason that can be shown to the user (DSA Art. 17, see section 1).
5. Is Android or web planned within 2 years? Android rules CloudKit out in practice. The web could still reach it through CloudKit JS / Web Services.
6. Where does the initial Park catalog come from (OpenStreetMap is ODbL-licensed, own survey, user submissions)? How many Parks do you expect in Poland? Below about 10k, you could also ship a catalog snapshot and compute "nearest" on device, which works offline.
7. Will you enroll in the Apple Developer Program as an individual or as a company? Sign in with Apple identifiers are team-scoped, so moving teams later needs a user migration, which must run within the 60-day transfer window ([TN3159](https://developer.apple.com/documentation/technotes/tn3159-migrating-sign-in-with-apple-users-for-an-app-transfer)).
8. What monthly budget ceiling are you comfortable with at 50k MAU? Do you want a hard cap that stops the service at quota (Supabase spend cap), a fixed price (VPS), or only alerts while the service keeps running (Supabase with the cap off, Firebase)?
9. Photo rules: how many per user per day, what about faces and people in photos (GDPR for third parties), and do you strip EXIF location on device before upload?

## Sources

Apple
- App Review Guidelines (1.2, 3.1.1, 4.8, 5.1.1(v)): https://developer.apple.com/app-store/review/guidelines/
- Offering account deletion in your app: https://developer.apple.com/support/offering-account-deletion-in-your-app/
- Sign in with Apple REST API, revoke tokens: https://developer.apple.com/documentation/signinwithapplerestapi/revoke-tokens
- Creating a client secret (six-month max): https://developer.apple.com/documentation/accountorganizationaldatasharing/creating-a-client-secret
- Verifying a user: https://developer.apple.com/documentation/signinwithapple/verifying-a-user
- Processing changes for Sign in with Apple accounts: https://developer.apple.com/documentation/signinwithapple/processing-changes-for-sign-in-with-apple-accounts
- TN3159, team-scoped user identifiers: https://developer.apple.com/documentation/technotes/tn3159-migrating-sign-in-with-apple-users-for-an-app-transfer
- realUserStatus: https://developer.apple.com/documentation/authenticationservices/asauthorizationappleidcredential/realuserstatus
- Supported capabilities (iOS): https://developer.apple.com/help/account/reference/supported-capabilities-ios
- Program fee: https://developer.apple.com/support/purchase-activation/
- CloudKit overview: https://developer.apple.com/icloud/cloudkit/
- Designing with CloudKit (roles): https://developer.apple.com/icloud/cloudkit/designing/
- CKContainer: https://developer.apple.com/documentation/cloudkit/ckcontainer
- publicCloudDatabase: https://developer.apple.com/documentation/cloudkit/ckcontainer/publicclouddatabase
- CKQuery: https://developer.apple.com/documentation/cloudkit/ckquery
- CKLocationSortDescriptor: https://developer.apple.com/documentation/cloudkit/cklocationsortdescriptor
- CloudKit Web Services (server-to-server keys): https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html
- Apple Developer Program License Agreement (§2.8 Apple Services fees; Attachment 4, iCloud): https://developer.apple.com/support/terms/apple-developer-program-license-agreement/
- EU Data Act terms for CloudKit: https://developer.apple.com/download/files/EU-Data-Act-Terms-CloudKit.pdf
- Forum thread with user-posted CloudKit quotas (not authoritative): https://developer.apple.com/forums/thread/660009
- App Store Server Library: https://github.com/apple/app-store-server-library-swift, https://github.com/apple/app-store-server-library-node
- App Attest: https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity
- swift-openapi-generator: https://github.com/apple/swift-openapi-generator

Supabase
- Pricing: https://supabase.com/pricing
- Regions: https://supabase.com/docs/guides/platform/regions
- Backups: https://supabase.com/docs/guides/platform/backups
- DPA: https://supabase.com/legal/dpa
- Subprocessors: https://supabase.com/legal/customer-resources/subprocessor-list
- Login with Apple: https://supabase.com/docs/guides/auth/social-login/auth-apple
- Managing user data: https://supabase.com/docs/guides/auth/managing-user-data
- PostGIS: https://supabase.com/docs/guides/database/extensions/postgis
- Row Level Security: https://supabase.com/docs/guides/database/postgres/row-level-security
- Database advisors: https://supabase.com/docs/guides/database/database-advisors
- RBAC with custom claims: https://supabase.com/docs/guides/database/postgres/custom-claims-and-role-based-access-control-rbac
- Smart CDN: https://supabase.com/docs/guides/storage/cdn/smart-cdn
- Control your costs (spend cap behaviour): https://supabase.com/docs/guides/platform/cost-control
- Securing your API (pre-request rate limits): https://supabase.com/docs/guides/api/securing-your-api
- Self-hosting with Docker: https://supabase.com/docs/guides/self-hosting/docker
- supabase-swift: https://github.com/supabase/supabase-swift
- Component repos: https://github.com/supabase/supabase, https://github.com/supabase/auth, https://github.com/supabase/storage, https://github.com/supabase/realtime, https://github.com/PostgREST/postgrest
- CVE-2025-48757: https://nvd.nist.gov/vuln/detail/CVE-2025-48757

Firebase / Google Cloud
- Pricing: https://firebase.google.com/pricing
- Firestore pricing: https://cloud.google.com/firestore/pricing
- Cloud Storage pricing: https://cloud.google.com/storage/pricing
- Identity Platform pricing: https://cloud.google.com/identity-platform/pricing
- Storage changes (Blaze requirement, Feb 2026): https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024
- Avoid surprise bills: https://firebase.google.com/docs/projects/billing/avoid-surprise-bills
- Geo queries: https://firebase.google.com/docs/firestore/solutions/geoqueries
- Enterprise geospatial query: https://firebase.google.com/docs/firestore/enterprise/geospatial-query
- Sign in with Apple on iOS: https://firebase.google.com/docs/auth/ios/apple
- Privacy and data location: https://firebase.google.com/support/privacy
- Data Processing and Security Terms: https://firebase.google.com/terms/data-processing-terms
- Custom claims: https://firebase.google.com/docs/auth/admin/custom-claims
- App Check with App Attest: https://firebase.google.com/docs/app-check/ios/app-attest-provider
- Export/import: https://firebase.google.com/docs/firestore/manage-data/export-import
- iOS SDK release notes: https://firebase.google.com/support/release-notes/ios

PocketBase
- README: https://github.com/pocketbase/pocketbase
- FAQ: https://pocketbase.io/faq/
- Authentication: https://pocketbase.io/docs/authentication/
- API rules and filters: https://pocketbase.io/docs/api-rules-and-filters/
- Files: https://pocketbase.io/docs/files-handling/
- Going to production: https://pocketbase.io/docs/going-to-production/
- Routing: https://pocketbase.io/docs/go-routing/, https://pocketbase.io/docs/js-routing/

Hetzner / Cloudflare
- Cost-Optimized plans: https://www.hetzner.com/cloud/cost-optimized
- Regular Performance plans: https://www.hetzner.com/cloud/regular-performance
- Price adjustment statements: https://www.hetzner.com/pressroom/statement-price-adjustment/, https://www.hetzner.com/pressroom/standardization-and-price-adjustment-of-our-server-products/
- Billing FAQ: https://docs.hetzner.com/cloud/billing/faq/
- Backups: https://docs.hetzner.com/cloud/servers/backups-snapshots/overview/
- Object Storage: https://www.hetzner.com/storage/object-storage/
- Data privacy FAQ (DPA): https://docs.hetzner.com/general/general-terms-and-conditions/data-privacy-faq/
- R2 pricing: https://developers.cloudflare.com/r2/pricing/
- R2 data location: https://developers.cloudflare.com/r2/reference/data-location/
- R2 public buckets: https://developers.cloudflare.com/r2/buckets/public-buckets/
- Cloudflare DPA: https://www.cloudflare.com/cloudflare-customer-dpa/
- Hetzner IP pricing: https://docs.hetzner.com/general/others/ipv4-pricing/

Server stack and security
- Axum: https://github.com/tokio-rs/axum
- sqlx: https://github.com/transact-rs/sqlx
- Vapor: https://vapor.codes/
- Hummingbird: https://hummingbird.codes/
- PostGIS KNN operator: https://postgis.net/docs/geometry_distance_knn.html
- pgBackRest: https://pgbackrest.org/
- OWASP API Security Top 10 2023: https://api-security.owasp.org/editions/2023/en/0x11-t10/
- CISA/NSA, The Case for Memory Safe Roadmaps: https://www.cisa.gov/sites/default/files/2023-12/The-Case-for-Memory-Safe-Roadmaps-508c.pdf
- Google Security Blog, Eliminating memory safety vulnerabilities at the source: https://security.googleblog.com/2024/09/eliminating-memory-safety-vulnerabilities-Android.html

Law
- GDPR (Regulation 2016/679): https://eur-lex.europa.eu/eli/reg/2016/679/oj
- EU-US Data Privacy Framework adequacy decision (2023/1795): https://eur-lex.europa.eu/eli/dec_impl/2023/1795/oj
- Latombe v Commission (T-553/23), secondary summary: https://www.hlc.com/en/publications/transatlantic-data-transfers-eu-general-court-upholds-dat-privacy-framework
- Digital Services Act (Regulation 2022/2065): https://eur-lex.europa.eu/eli/reg/2022/2065/oj (article structure read via https://www.springlex.eu/en/packages/dsa/dsa-regulation/article-19/)

## Fact-check (2026-11-03)

A second pass re-opened the primary sources on 2026-11-03: vendor pricing pages, docs, the GitHub API, Apple's documentation JSON, the DPLA and the App Review Guidelines. It recomputed the cost model.

**Corrected**

- **Supabase spend cap.** The draft presented the default cap as a safety net that still let small overage be billed. In fact, with the cap on, "further usage of that item is disallowed until the next billing cycle" ([cost control](https://supabase.com/docs/guides/platform/cost-control)). Under the model, photo egress passes the 250 GB cached quota at about 45k MAU, so at 50k MAU photos would stop loading unless the cap is off. Answer, Supabase facts, the table, the cost row, sensitivity, Recommendation 1 and open question 8 are updated. "Flat $25 up to about 50k" now reads "up to about 45k, about $26 at 50k with the cap off".
- **Sensitivity.** Uncached 5× photo traffic on Supabase is about $25 + $102 ≈ $127, not "up to about $100".
- **"EU companies" for the custom API.** Cloudflare R2's DPA party is Cloudflare, Inc. (USA). R2's EU jurisdiction guarantees storage at rest only, and Cloudflare Cache serves from a global edge. All-EU-company hosting needs Hetzner Object Storage instead of R2. Answer, R2 facts, the table and Recommendation 2 are fixed.
- **Rust section.** "The only C component is Postgres" was wrong. The self-hosted Supabase gateway is Envoy (C++), imgproxy uses libvips (C), Node/Deno run on V8 (C++), and all options share the kernel and a TLS library. Supabase Edge Runtime is already Rust. The conclusion (Rust adds no meaningful memory-safety margin) is unchanged.
- **Quotes fixed to the source wording:**
  - The Firestore geohash quote now reads "up to 9 pairs of bounds … in most cases there are 4".
  - Supabase's Apple guide says "don't require secret key rotation", not "don't need".
  - The Apple account-deletion page says people *expect* UGC to be deleted. The draft had it as an explicit "must".
- **Citations and counts:**
  - "Reserves the right to charge fees" is DPLA §2.8, not Attachment 4 §2.1.
  - Firebase 13 ships through SPM *and* binary distributions, not SPM only.
  - Self-hosted Supabase runs 11 containers by default (13 with logging), not "about 12".
  - sqlx is MIT or Apache-2.0 and moved to `transact-rs/sqlx`.
  - The OWASP URL moved to `api-security.owasp.org`.
  - CVE-2025-48757 is disputed by the supplier, which is now noted.
  - PocketBase has no *official* Swift SDK, though small community packages exist. The FAQ's "$4 CAX11" is outdated (now €6.49 and not available).
- **Hetzner.** Added CPX02 (€6.49, 1 GB), the €0.50/month primary IPv4, the fact that the June 2026 increase also applies to rescales, and that CPX22+ is offered in NBG1 and HEL1 only. The PocketBase and custom-API rows were recomputed (≈€8–15 and ≈€15–31).
- **Added missing points:**
  - EU Digital Services Act Art. 16–17 (notice-and-action and statement of reasons) apply even to micro enterprises, so the moderation model needs stored reasons.
  - DPF litigation status.
  - Apple's advice to handle Sign in with Apple server-to-server notifications.
  - Supabase has no built-in per-user write rate limit (`db_pre_request` only covers writes) and no App Check counterpart.
  - A staging project on Supabase Pro costs about $10/month extra.
  - Prices exclude VAT.
  - TN3159's 60-day transfer window.
  - Firebase revocation needs a Services ID and OAuth code-flow configuration.
- **CloudKit paywall.** "Forbids a contribution paywall" is softened to an interpretation of DPLA §2.2. The technical blocker, that no server code runs on writes, stays as stated.

**Checked and found correct as written**

- **Supabase:** all Free and Pro figures on the pricing page; regions; DPA (v1, 1 Aug 2026, Supabase Pte. Ltd., 2021/914 SCCs, no DPF); backups (7 days; Storage objects excluded); RLS, advisor and RBAC quotes; Smart CDN; deletion and Storage-owner rule; self-hosting requirements; supabase-swift v2.55.6 (2026-10-30; iOS 16+, Xcode 26+, Swift 6.2+).
- **Hetzner:** CX23 €5.99 and all Cost-Optimized plans "not available"; CPX12/22/32 prices; 20 TB traffic, then €1/TB; backups at 20%; Object Storage €6.49 with 1 TB + 1 TB; DPA concluded in the customer account.
- **Google:**
  - Identity Platform: 50k MAU free, then $0.0055.
  - Firestore Warsaw: $0.039 reads, $0.117 writes, $0.195/GiB.
  - Firestore free tier as stated.
  - GCS Warsaw: $0.023/GiB, internet egress $0.12/GiB for 0–10 TiB.
  - Storage FAQ: Blaze requirement from 3 Feb 2026, and the US-only no-cost regions.
  - Spend caps limited to Functions, App Hosting, AI Logic and Extensions.
  - "Auth … only from US data centers".
  - Firebase iOS SDK 13.1.1 (2026-10-22); 13.0.0 needs iOS 15+ and Xcode 26.2+.
- **Apple:**
  - Guideline 1.2, 3.1.1 and 5.1.1(v) wording (guidelines last updated 16 Oct 2026).
  - The revoke endpoint and its parameters.
  - The 15,777,000-second client-secret limit.
  - The token-verification steps.
  - TN3159 team scoping.
  - `realUserStatus` wording.
  - Sign in with Apple, CloudKit and App Attest are ADP-only in the capabilities table.
  - The 99 USD fee.
  - CloudKit quotes: iCloud account needed to save, 10 km location index resolution, roles, public/private quotas, 1 PB.
  - DPLA Attachment 4 §1.2, §1.6 and §2.2.
- **Cloudflare R2:** $0.015/GB-month, Class A $4.50/M, Class B $0.36/M, free egress, and the free tier.
- **PocketBase:** v0.40.6 (2026-10-23; the docs header shows v0.41.1); FAQ quotes; `geoDistance`; thumbnail formats; rate limiter (v0.23+) and superuser IP whitelist (v0.38+).
- **Other:** Axum v0.8.9 (MIT); CISA's ~70% (Microsoft and Chromium); Android 76% → 24%; the OWASP 2023 list.
- **Cost-model arithmetic:** 5.73 MB per MAU, 287 GB at 50k, 20.4 GB of storage, Firestore reads per day and the Firebase totals all recompute correctly.

**Could not verify**

- Whether Hetzner's displayed plan prices already include the IPv4 address (the page has a toggle).
- VAT treatment for the owner.
- Whether Cloudflare can keep cached R2 objects inside the EU on a non-Enterprise plan.
- How Apple applies DPLA §2.2 to paid features that use CloudKit.
- Current CloudKit public-database quotas (Apple publishes none).
- Whether CaliPark is an "online platform" under the DSA.
- The DPF appeal case number and status: EUR-Lex and CURIA blocked automated access, and the T-553/23 facts come from secondary sources.
- Whether Firebase handles Sign in with Apple server-to-server notifications.
- Firestore Enterprise pricing.
- Whether a Supabase Micro instance carries 50k MAU.
- All build-effort figures and usage assumptions. These are estimates by nature.

**Does the recommendation still follow?** Yes, with conditions. Supabase Cloud Pro in Frankfurt remains the lowest-effort fit, and the cost conclusion holds at this scale. The owner must, however, choose a spend-cap policy before about 45k MAU and build the rate limiting and DSA reason-tracking themselves. The custom API's "all-EU" advantage holds only with Hetzner Object Storage instead of R2. The ranking is unchanged, and the owner decides.
