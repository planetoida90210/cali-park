# CaliPark 1.0: App Review and Polish/EU compliance

Research date: 2026-11-03. Scope: what CaliPark 1.0 must satisfy for App Review, TestFlight external testing, GDPR/RODO and the EU Digital Services Act (DSA), given the decided scope: Sign in with Apple only, public Park reviews with ratings and photos, a map with the user's location, local notifications, iPhone only, free.

This is a research summary, not legal advice. Where a point is my own reading of a rule rather than the rule's text, it says "judgment" or "estimate". Apple changes its rules often (the App Review Guidelines were last updated 2026-10-16), so re-check the linked pages before each submission.

## Answer

1. **Apple's hard gates** are a `PrivacyInfo.xcprivacy` declaring `UserDefaults` (reason `CA92.1`), since App Store Connect rejects uploads without it ([Apple](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)). Then accurate purpose strings, a privacy policy linked in App Store Connect and inside the app, and nutrition labels.
2. **Community** must meet guideline 1.2 before it reaches any reviewer, TestFlight included: a pre-publication filter, a report button, user blocking, published contact info, and in practice a ToS with "zero tolerance" wording plus action on reports within 24 hours. The October 2026 update also requires you to proactively stop nonconsensual intimate imagery ([1.2](https://developer.apple.com/app-store/review/guidelines/#user-generated-content), [news](https://developer.apple.com/news/?id=vvzx6cul)).
3. **In-app account deletion** must delete the account and its reviews and photos, and revoke the Sign in with Apple token ([Apple](https://developer.apple.com/support/offering-account-deletion-in-your-app/)). Guideline 4.8 adds nothing when Sign in with Apple is the only login.
4. **Buy the Apple Developer Program (99 USD/yr) now, not just before TestFlight.** Sign in with Apple, WeatherKit, CloudKit and push notifications don't work on a free personal team ([capabilities table](https://developer.apple.com/help/account/reference/supported-capabilities-ios)). As an individual, your legal name is shown as the seller ([enroll](https://developer.apple.com/programs/enroll/)).
5. **EU listing** requires a DSA trader or non-trader declaration in App Store Connect. A trader's address, phone and email appear on the product page ([Apple](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements)).
6. **GDPR:** you are the controller. Base the Community on contract and legitimate interest, publish an Art. 13 privacy policy in Polish, and sign an Art. 28 DPA with each backend vendor. Handle access, export and deletion requests within one month. An Account minimum age of 16 matches the Polish default ([GDPR](https://eur-lex.europa.eu/eli/reg/2016/679/oj)), **but** Apple says that if your EULA sets a minimum age above the computed rating, you "must override to a rating that adheres to the requirements" ([set an app age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating)). A 16+ Account age therefore means a 16+ App Store rating for the whole app, training included. This is a decision for the owner (section 2.7).
7. **DSA:** as a micro enterprise you are exempt from transparency reports and from the Section 3 online-platform duties. You still need a notice-and-action form open to anyone, statements of reasons when you remove content, points of contact, and moderation rules in the terms ([DSA](https://eur-lex.europa.eu/eli/reg/2022/2065/oj)). Poland's implementing amendment to UŚUDE (Dz.U. 2026 poz. 1296) **takes effect on 2026-11-06**. It names the Prezes UKE as Digital Services Coordinator and sets administrative fines for hosting providers that breach DSA Arts. 16, 17 and 18 ([Sejm ELI](https://api.sejm.gov.pl/eli/acts/DU/2026/1296)). Polish law requires a *regulamin* ([UŚUDE art. 8](https://api.sejm.gov.pl/eli/acts/DU/2024/1513/text.html)) from a provider who acts "prowadząc, chociażby ubocznie, działalność zarobkową lub zawodową". Whether a zero-revenue hobby app falls under that is arguable (judgment). Write one anyway, because Apple's EULA, DSA Art. 14 and the GDPR contract basis all need terms.
8. **Cheapest safe path (judgment):** ship the first external TestFlight build without Community. Then add Community, with all the items above, in a build that goes through review, and never switch it on with a server flag after approval (guideline 2.5.19).
9. **Added by fact-check: Apple Maps terms limit the Park database.** The DPLA's Apple Maps terms (Attachment 6) forbid using Map Data, which includes POIs and coordinates from MapKit search and geocoding, "as part of any secondary or derived database". They also forbid caching it "other than on a temporary and limited basis" ([DPLA](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)). Judgment: store only coordinates and names that users enter themselves (pin drops, typed names) or that come from OSM under ODbL. Never store MapKit search or geocoding results on the server.
10. **Added by fact-check: iPhone Duo.** iPhone-only apps now also run on Apple's foldable iPhone Duo, on sale since 2026-10-23. "Starting April 2027, any apps or games submitted will need to include screenshots for iPhone Duo" ([Apple news 2026-10-05](https://developer.apple.com/news/?id=kkphp5qo)). Test the layout on the iPhone Duo simulator, which the installed Xcode 27.2 includes.

## Findings

### 1. Current repo state relevant to compliance

Findings from reading `cali-park.xcodeproj/project.pbxproj` and `docs/audit/README.md` on 2026-11-03:

| Item | Current value | Problem |
|---|---|---|
| `TARGETED_DEVICE_FAMILY` | `"1,2"` (Universal) | The decided scope is iPhone-only. Set it to `1` (audit G-11). |
| `NSLocationWhenInUseUsageDescription` | "…aby pokazać najbliższe **siłownie** na mapie." | It uses a word GLOSSARY.md says to avoid and doesn't match the Park definition. Reword it. |
| `NSPhotoLibraryAddUsageDescription` | present | Nothing uses it (audit G-6). Remove it, per data minimization in 5.1.1(iii). |
| `NSCameraUsageDescription` | present | The camera flow sits behind Premium, which can't be reached, and doesn't check availability (audit E-27). |
| `PrivacyInfo.xcprivacy` | missing | This blocks uploads (audit G-1, C-2). `UserDefaults` is used in 8 Swift files. A grep found no file-timestamp, boot-time or disk-space APIs. |
| Mocks (fake reviews, weather, "Michał", Unsplash hotlinks) | in production code | Review risk under 2.1/2.3 (audit #8). |
| Dormant Community/Premium code | in the binary | Risk under 2.5.19 (hidden or dormant features). |
| Photo input | `PhotosPicker` + `UIImagePickerController` (camera) | No metadata stripping before upload. |

### 2. Apple App Review Guidelines (last updated 2026-10-16)

Source for all quotes: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

#### 2.1 Guideline 1.2: user-generated content

The guideline text says apps that let users "create, generate, upload, share, or otherwise contribute content … must include:
- A method for filtering objectionable material from being posted to the app
- A mechanism to report offensive content and timely responses to concerns
- The ability to block abusive users from the service
- Published contact information so users can easily reach you."

The 2026-10-16 update added that content moderation "now explicitly cover[s] nonconsensual intimate imagery — including imagery generated using AI tools — as content that apps must proactively prevent and remove". Developers who don't remedy violations after notice risk removal ([Apple news, 2026-10-16](https://developer.apple.com/news/?id=vvzx6cul)).

**What reviewers actually ask for** (from App Review's own rejection text, quoted by a developer on Apple's forums in Nov 2025; this is secondary evidence, not the guideline itself) ([forum thread](https://developer.apple.com/forums/thread/807358)):
- "Require that users agree to terms (EULA) and these terms must make it clear that there is no tolerance for objectionable content or abusive users"
- "A method for filtering objectionable content"
- "A mechanism for users to flag objectionable content"
- "A mechanism for users to block abusive users"
- "The developer must act on objectionable content reports within 24 hours by removing the content and ejecting the user who provided the offending content"

In the same thread, a second rejection asked a feed-style app to set its age rating to 18+ and to add contact information inside the app.

Guideline 1.2.1 (creator content: age-restricting content above the app's rating) targets "creator" apps. Judgment: Park reviews aren't creator content, so 1.2.1 likely doesn't apply.

**How CaliPark can meet 1.2 cheaply (judgment):**

| Requirement | Minimal v1 design |
|---|---|
| Filter before posting | **Photos:** hold every photo in a pre-moderation queue until you approve it. At friends-and-TestFlight scale this costs nothing, and it is the strongest defense against NCII and spam. **Text:** Polish/English profanity and slur wordlist, link blocking, rate limits per Account. |
| Report | A "Zgłoś" action on every review and photo. It should work **without an Account**, because DSA Art. 16 says "any individual or entity" (section 4). |
| Timely response | Commit to 24 hours in the ToS and in the review notes. Set up push or email alerts to yourself for every new report. |
| Block | A "Zablokuj użytkownika" action that hides all of that Account's content for the blocker, plus an admin-side ban ("ejecting the user"). |
| Contact info | An email address inside the app (Settings > Kontakt) and on the Support URL page. |
| EULA acceptance | A checkbox the first time someone publishes: accept the *regulamin*, with explicit zero-tolerance wording. |

Apple's `SensitiveContentAnalysis` framework is **not** a moderation tool. It only returns results when the user has turned on Sensitive Content Warning or Communication Safety, it needs the paid-program entitlement, and Apple says to use it "to prevent people from viewing unwanted content, not as a way for an app to report on someone's behavior", without sending results off the device ([Apple](https://developer.apple.com/documentation/sensitivecontentanalysis/detecting-nudity-in-media-and-providing-intervention-options)). At most, use it to blur incoming photos for viewers who opted in.

#### 2.2 Guideline 4.8 and Sign in with Apple

- 4.8 applies to apps that use "a third-party or social login service (such as Facebook Login, Google Sign-In, …)". Those apps must also offer an equivalent privacy-preserving option. With Sign in with Apple as the **only** login, 4.8 adds no obligation ([4.8](https://developer.apple.com/app-store/review/guidelines/#login-services)).
- 5.1.1(v): "If your app doesn't include significant account-based features, let people use it without a login." Training without an Account already matches this.
- **The Sign in with Apple capability needs paid membership.** Apple's capabilities table marks it ADP-only, with no free "Apple Developer" column. WeatherKit is the same, and iCloud/CloudKit and push notifications also need membership ([supported capabilities](https://developer.apple.com/help/account/reference/supported-capabilities-ios)).
- **New private relay domain.** New Sign in with Apple relay addresses are issued on `private.icloud.com` "later this year". `privaterelay.appleid.com` addresses keep working ([Apple news, 2026-08-24](https://developer.apple.com/news/?id=1ptvdtcm)). Apple's relay documentation lists **three** domains: relay addresses "end in @private.icloud.com, @privaterelay.appleid.com, or @icloud.com" ([Apple](https://developer.apple.com/documentation/signinwithapple/communicating-using-the-private-email-relay-service)). Accept all three in validation and allowlists, and don't treat `@icloud.com` as proof of a real address.
- **Emailing users with hidden addresses** (for example DSA statements of reasons) requires registering your outbound domain and using SPF. Each relay address has a limit of 100 emails per day ([Apple](https://developer.apple.com/documentation/signinwithapple/communicating-using-the-private-email-relay-service)).
- **Server-to-server notifications** tell your backend when a user disables Sign in with Apple for your app (`consent-revoked`), deletes their Apple Account (`account-deleted`), or changes email forwarding ([Apple](https://developer.apple.com/documentation/signinwithapple/processing-changes-for-sign-in-with-apple-accounts)).

#### 2.3 Guideline 5.1.1(v): account deletion in the app

From [Offering account deletion in your app](https://developer.apple.com/support/offering-account-deletion-in-your-app/):
- "Apps … that support account creation must also let people initiate deletion of their account within the app."
- "Offer to delete the entire account record, along with associated personal data … only offering to temporarily deactivate or disable an account is insufficient."
- **This explicitly covers UGC:** "This includes user-generated content that's shared with others, such as photos, videos, text posts, and reviews."
- If deletion finishes on a website, link "directly to the page". Apps outside highly regulated industries must not require a call, an email or a support chat.
- Deletion may be manual or take time. If it does, tell the user how long it will take and confirm when it's done.
- "Apps that support Sign in with Apple should use the Sign in with Apple REST API to revoke user tokens." The revoke endpoint needs a refresh or access token, so keep the refresh token you get when you validate the authorization code ([revoke tokens](https://developer.apple.com/documentation/signinwithapplerestapi/revoke-tokens)).
- If you must keep some data by law, for example DSA moderation records, tell the user what you keep.

#### 2.4 Guidelines 5.1.1 and 5.1.2: privacy policy, consent and data use

- **5.1.1(i):** "All apps must include a link to their privacy policy in the App Store Connect metadata field and within the app in an easily accessible manner." The policy must say what data is collected, how, and all its uses. It must confirm that third parties give equal protection, and explain retention and deletion and how to revoke consent or request deletion.
- **5.1.1(ii):** "Ensure your purpose strings clearly and completely describe your use of the data." If you rely on GDPR legitimate interest instead of consent, you "must comply with all terms of that law".
- **5.1.1(iii):** "Where possible, use the out-of-process picker." `PhotosPicker` already does this, so you don't need Photos permission.
- **5.1.1(iv):** "if a user declines to share Location, offer the ability to manually enter an address." In CaliPark, the map and park search must work without location permission.
- **5.1.2(i):** don't share personal data without permission. "You must clearly disclose where personal data will be shared with third parties, including with third-party AI, **and obtain explicit permission before doing so**." This matters if you ever send uploaded photos or review text to an AI moderation API: you would need an explicit opt-in. Judgment: that makes a third-party AI filter on Community content awkward for v1. The guideline also says "Your app may not require users to enable system functionalities (such as push notifications, location services, tracking) in order to access functionality".
- **DPLA 3.3.3(F)(ii):** location-based apps "must notify and obtain consent from a user before a user's location data is collected, transmitted or otherwise used by the Application" ([DPLA](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)). The system location prompt covers on-device use. If you ever send coordinates to the server, say so in the purpose string and the privacy policy.
- **5.1.5:** use location only when directly relevant, and explain the purpose.
- **4.5.4:** notifications must not be required for the app to work, and marketing notifications need explicit opt-in. Local workout reminders are fine.
- **Apple Developer Program License Agreement:** "You must provide a privacy policy in Your Application, on the App Store, and/or on Your website…". You must also notify users of a data breach "in accordance with applicable law" ([DPLA](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)).

#### 2.5 Privacy nutrition labels (App Store Connect > App Privacy)

Key definitions, from [App privacy details](https://developer.apple.com/app-store/app-privacy-details/):
- "'Collect' refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time."
- "Data that is processed only on device is not 'collected' and does not need to be disclosed."
- "You are not responsible for disclosing data collected by Apple." This covers, for example, crash reports that Apple collects through its own opt-in analytics.
- A Privacy Policy URL is **required**. A Privacy Choices URL is optional.

**Likely CaliPark 1.0 answers.** This is a judgment that depends on the backend design:

| Apple data type | Collected? | Linked to user | Tracking | Purpose |
|---|---|---|---|---|
| Email Address (Sign in with Apple, possibly a relay address) | Yes, if stored | Yes | No | App Functionality |
| Name | Only if you store the name Sign in with Apple returns. A self-chosen display name counts as User ID/content instead. | Yes | No | App Functionality |
| User ID (Account ID, Sign in with Apple `sub`) | Yes | Yes | No | App Functionality |
| Photos or Videos (Park photos) | Yes | Yes | No | App Functionality |
| Other User Content (reviews, ratings, reports) | Yes | Yes | No | App Functionality |
| Precise or Coarse Location | **No**, if the location stays on the device or is only sent for a real-time "nearby" query and not kept. **Yes (Precise)** if you keep it, for example when the add-Park form pre-fills the user's GPS position. | n/a or Yes | No | App Functionality |
| Crash Data, Performance Data | No, unless you add a third-party crash SDK | | | |
| Training logs | No, while they stay on the device. If you sync them through your own backend, declare **Fitness** ("Fitness and exercise data"), linked to the user, for App Functionality. Judgment: data in the user's private CloudKit database isn't readable by you, so it is probably not "collected". That is unverified, so re-assess when you choose the sync design (see open questions). | | | |

Judgment: real-time "nearby" queries count as not collected only if server, proxy and CDN logs don't keep the coordinates. Apple's test is access "for a period longer than what is necessary to service the transmitted request in real time".

#### 2.6 Privacy manifest (`PrivacyInfo.xcprivacy`) and required-reason APIs

- App Store Connect enforcement: "Starting May 1, 2024, apps that don't describe their use of required reason API in their privacy manifest file aren't accepted by App Store Connect." TestFlight builds are uploaded to App Store Connect too ([Apple](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)).
- The file holds `NSPrivacyTracking`, `NSPrivacyTrackingDomains`, `NSPrivacyCollectedDataTypes` and `NSPrivacyAccessedAPITypes` ([privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)).
- Reasons that apply to CaliPark ([NSPrivacyAccessedAPIType](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)):

| Category | Reason | Text (abridged) | Needed? |
|---|---|---|---|
| `NSPrivacyAccessedAPICategoryUserDefaults` | `CA92.1` | "read and write information that is only accessible to the app itself" | **Yes** (8 files use `UserDefaults`/`@AppStorage`) |
| `NSPrivacyAccessedAPICategoryUserDefaults` | `1C8F.1` | same, but shared within an App Group | Only if a widget or extension shares defaults |
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `C617.1` | timestamps, size or metadata of files inside the app container | Only if the file stores read `modificationDate`, `attributesOfItem` or `stat` (none found) |
| `NSPrivacyAccessedAPICategorySystemBootTime` | `35F9.1` | measure elapsed time between in-app events | Only if `systemUptime` or `mach_absolute_time` is used |
| `NSPrivacyAccessedAPICategoryDiskSpace` | `E174.1` | check for enough space before writing | Only if photo caching checks free space |

- Set `NSPrivacyTracking` to `false`. Mirror the nutrition-label rows in `NSPrivacyCollectedDataTypes`.
- If you add a backend SDK (for example `supabase-swift`), check whether it uses required-reason APIs. An SDK needs its own manifest if it is on Apple's "SDKs that require a privacy manifest and signature" list, or if it uses required-reason APIs ([privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)).

#### 2.7 Age rating questionnaire

- The system now has **4+, 9+, 13+, 16+ and 18+** ratings. An "Unrated" app can't be published. If your policy requires an older minimum age, you can choose a higher rating ([values and definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions), [news 2025-07-24](https://developer.apple.com/news/?id=ks775ehf)).
- Capability definitions ([same page](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions)):
  - **User-Generated Content**: "broad distribution of content created by users". Listed in the 4+ table.
  - **Social Media**: "Redistribution, amplification, or interaction with user-generated content through a social feed or similar discovery method". Listed in the 13+ table and adds a "Social Media" content descriptor. These answers are required for new apps and updates from September 2026 ([news 2026-07-09](https://developer.apple.com/news/?id=tlur8uvi)).
  - **Messaging and Chat** includes "public posting". Listed in the 4+ table.
- **New declarations from 2026-11-16:** "Shared Location" ("shares real-world location with another person or group") and "Dating and Relationships". They are required on every update from 2026-11-16 and for all apps by **2027-01-12** ([news 2026-11-02](https://developer.apple.com/news/?id=yxkh08us)).
- **Suggested CaliPark answers (judgment):** User-Generated Content: Yes. Social Media: No, because v1 has no feed, likes or comments; revisit this for the v1.1 feed. Messaging and Chat: likely Yes, since the definition's "May include" list names "public posting". Shared Location: No, because reviews and photos never reveal the user's own location, which also depends on stripping EXIF. Unrestricted Web Access: No. The computed rating will probably be 4+ (UGC and Messaging and Chat are listed at 4+).
  - **Correction (fact-check): the rating is not optional once the *regulamin* sets an age.** Apple: "If your app has a EULA with minimum age requirements that exceed the rating that Apple calculated, you must override to a rating that adheres to the requirements." The override "will apply in all regions" ([set an app age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating)). A *regulamin* that says Accounts are 16+ therefore means a 16+ App Store rating. Judgment: that hides the whole app, training included, from teens whose Screen Time age limits are on, and teens are a core calisthenics audience. The alternatives are a lower Account age (13+, which needs a legal check under Polish civil-law capacity rules and GDPR Art. 8 if any processing rests on consent), or accepting 16+. Decide this before writing the *regulamin*.
  - Be ready for a reviewer to push the rating up. The forum case above shows that happens.

#### 2.8 Location permission purpose string

- `NSLocationWhenInUseUsageDescription` "is required if your iOS app uses APIs that access the user's location information while the app is in use" ([Apple](https://developer.apple.com/documentation/bundleresources/information-property-list/nslocationwheninuseusagedescription)).
- Request only When-In-Use authorization. Better, use `LocationButton` from CoreLocationUI, "a SwiftUI button that grants one-time location authorization", so you never show a standing permission prompt ([Apple](https://developer.apple.com/documentation/corelocationui/locationbutton)).
- Suggested string (Polish UI): „CaliPark używa Twojej lokalizacji tylko po to, by pokazać najbliższe parki do treningu na mapie. Lokalizacja nie jest zapisywana na naszych serwerach.” Only keep the second sentence if it is true.

#### 2.9 Stripping EXIF/GPS from uploaded photos

- ImageIO keeps GPS by default. For `kCGImageMetadataShouldExcludeGPS`, the docs say "The default value is kCFBooleanFalse, which includes GPS information in the metadata. This flag doesn't filter any proprietary location data in the manufacturer's EXIF MakerNote or in custom XMP properties" ([Apple](https://developer.apple.com/documentation/imageio/kcgimagemetadatashouldexcludegps)).
- Implication (judgment): `PhotosPicker` data is the original file and can contain GPS, Make/Model, timestamps and MakerNote. Safest is to **re-encode pixels only**: decode, then encode a fresh JPEG/HEIC with no metadata dictionary, scaled to something like 2048 px. Do this on the device before upload, and **again on the server** as defense in depth.
- Why it matters:
  - GDPR data minimization: Art. 5(1)(c) says personal data must be "limited to what is necessary" ([GDPR](https://eur-lex.europa.eu/eli/reg/2016/679/oj)).
  - A park photo taken at home, then uploaded, would leak a home address.
  - Left in, GPS would also make the "Shared Location" age-rating answer and the "Precise Location" label inaccurate.

#### 2.10 iPhone-only (`TARGETED_DEVICE_FAMILY = 1`) and other devices

- 2.4.1: "iPhone apps should run on iPad whenever possible" ([2.4.1](https://developer.apple.com/app-store/review/guidelines/#hardware-compatibility)). An iPhone-only app is still offered on iPad and runs in iPhone compatibility mode, so reviewers may install it on an iPad. It must not crash or lay out badly at iPad compatibility scaling.
  - I could not find a current Apple page that describes iPadOS 26/27 windowing for iPhone apps, so treat the exact on-iPad presentation as unverified. Test on an iPad simulator before submission.
- Screenshots: an iPhone-only app needs "at least one screenshot for iPhone with Dynamic Island (medium display)" (1179×2556 or 1206×2622 portrait). iPad screenshots are "Required if app runs on iPad" ([screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)).
- **iPhone Duo (added by fact-check).** "iPhone Duo will be available to customers starting October 23, 2026". It is a foldable iPhone with a compact outer display and a large inner one, so `TARGETED_DEVICE_FAMILY = 1` still means the app has to resize ([Apple news 2026-10-05](https://developer.apple.com/news/?id=kkphp5qo), [Preparing your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo)).
  - Apple: "Starting April 2027, any apps or games submitted will need to include screenshots for iPhone Duo." The screenshot page words it as "required for any app using the iOS 27.1 SDK or later" (outer 1398×2034, inner 2007×2853). The installed Xcode is 27.2, so this applies to any submission from April 2027.
  - Apple's guidance: "Size your views relative to their container rather than to fixed iPhone dimensions", and check every view "in each supported orientation and pose". Judgment: a portrait-only lock (audit G-11) may still be fine. How an orientation lock behaves on the Duo's inner display is unverified, so test it on the iPhone Duo simulator (present in the installed Xcode 27.2).
- **Mac and Vision Pro are on by default.**
  - Apple-silicon Macs: available "provided no edits are made to the app availability". Opt out under Pricing and Availability ([Apple](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-of-iphone-and-ipad-apps-on-macs-with-apple-silicon)).
  - Vision Pro: "Your iPhone and iPad apps will be available to users on Apple Vision Pro unless you edit their availability" ([Apple](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-of-iphone-and-ipad-apps-on-apple-vision-pro)).
  - Judgment: opt out of both for a GPS and outdoor app until tested.
- Also lock iPhone to portrait if you don't design for landscape (audit G-11).

#### 2.11 Other submission items

- **Export compliance:** set `ITSAppUsesNonExemptEncryption = NO` if the app only uses HTTPS through the OS. Encryption "built into the operating system—for example, when your app makes HTTPS connections using URLSession—is exempt from export documentation upload requirements". Same page, caveat: "If your app uses exempt forms of encryption, you might alternatively be required to submit a year-end self-classification report to the U.S. government" ([Apple](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations)). Judgment: for OS-provided HTTPS only, this is commonly treated as not required, but that is unverified.
- **Regulated medical device declaration (added by fact-check).** Apps available in the EU/EEA, UK or US "that ... Have a primary or secondary category of Health & Fitness or Medical" must say whether they are a regulated medical device. A training app answers "No" ("If your app doesn't provide any health or medical features ... you should select No") ([Apple](https://developer.apple.com/help/app-store-connect/manage-app-information/declare-regulated-medical-device-status)). CaliPark will most likely be in Health & Fitness.
- **Apple Maps Service terms (DPLA Attachment 6, added by fact-check)** ([DPLA](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)):
  - "Map Data" means "any content, data or information provided through the Apple Maps Service including, but not limited to, imagery, terrain data, latitude and longitude coordinates, transit data, points of interest and traffic data".
  - 2.2: you may not "use or make available the Map Data, or any portion thereof, as part of any secondary or derived database".
  - 2.4: Map Data may only be shown on an Apple map ("if You surface an address result through the Apple Maps Service, You must display the corresponding map").
  - 2.5: Map Data "may not be cached, pre-fetched, or stored ... other than on a temporary and limited basis".
  - 2.6: "You may not charge any fees to end users solely for access to or use of the Apple Maps Service".
  - Judgment for the Park database: don't copy `MKLocalSearch` POIs or `CLGeocoder`/MapKit geocoding results (addresses, coordinates) into the backend. Store the user's own pin drop and typed name and address, or OSM data under ODbL. A paid contribution tier is fine. Charging for the map itself is not.
- **SDK minimum:** "Starting April 2027 … iOS and iPadOS apps must be built with the iOS 27 & iPadOS 27 SDK or later". The repo's Xcode 27 already meets this ([news 2026-09-09](https://developer.apple.com/news/?id=k1mtkt1k)).
- **2.1 completeness:** no "placeholder text, empty websites, and other temporary content". Include demo account details "if your app includes a login". For Sign in with Apple, a shareable demo account is impractical.
  - Judgment: explain in Notes that training works without login, and that the reviewer can sign in with their own Apple Account to test Community. That is common practice for apps that only use Sign in with Apple, but no Apple page confirms it (unverified).
  - The demo-account field is required only "If your app requires a login to use it" ([platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)). The guidelines' "Before You Submit" section also says: "If your app includes account-based features, provide either an active demo account or fully-featured demo mode". Be ready to supply a test Apple Account if a reviewer asks.
  - Also enable the backend for review. "Before You Submit" says "Enable backend services so that they're live and accessible during review." That includes the moderation path.
- **2.5.19 hidden or dormant features:** "Don't include any hidden, dormant, or undocumented features." The Oct 2026 clarification forbids "adding features or functionality that weren't included in the version of the app that was submitted to App Review" ([news](https://developer.apple.com/news/?id=vvzx6cul)). Two consequences:
  - Remove the mock Premium, Community and events code from the binary, or make it reachable.
  - Don't ship Community dark and switch it on with a server flag after approval.
- **Required metadata:**
  - The Support URL "must lead to actual contact information (legal address, email address, telephone number), as may be required by local law".
  - Copyright is required ([platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)).
- **US age-assurance laws.** Texas SB 2420 has applied to new Texas Apple Accounts since 2026-06-04. It requires the Declared Age Range and PermissionKit significant-change handling ([news 2026-06-03](https://developer.apple.com/news/?id=sg176nne)). Judgment: limit 1.0 storefronts to Poland (or the EU) and you avoid this until you expand.
- **OpenStreetMap data.** If you seed Parks from OpenStreetMap, the ODbL requires credit ("displaying our attribution notice"). Share-alike also applies: "If you alter or build upon our data, you may distribute the result only under the same license" ([OSM copyright](https://www.openstreetmap.org/copyright)). This affects whether the Park database can stay proprietary.

#### 2.12 WeatherKit (only if Home keeps a weather module)

- It needs paid membership. "up to 500,000 API calls a month per Apple Developer Program membership" are included. Paid tiers start at US$49.99/month for 1M calls ([WeatherKit](https://developer.apple.com/weatherkit/get-started/)).
- Attribution: "you must clearly display the Apple Weather trademark (Weather), as well as the legal link to other data sources" ([same](https://developer.apple.com/weatherkit/get-started/)).
- DPLA Attachment 8 ([DPLA](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)):
  - no fees "for access to or use of the Apple Weather Data presented in its original form", which matters for any future paywall
  - not "designed or marketed for emergency or life-saving purposes"
  - no caching "other than on a temporary and limited basis"
  - no bulk downloads or derived databases
- The audit found the current weather module is fake (audit #8). Either remove it for 1.0 or replace it with WeatherKit plus attribution.

### 3. TestFlight external testing

From the [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview), [Invite external testers](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/) and [TestFlight](https://developer.apple.com/testflight/):

| Item | Rule |
|---|---|
| Testers | Up to 100 internal testers, who must be App Store Connect users on your team. Up to 10,000 external testers, invited by email or public link (the link can be capped at 1 to 10,000). |
| Review | "When you add the first build of your app to a group, the build gets sent to App Review to make sure it follows the App Review Guidelines. A review is required only for the first build. Subsequent builds may not require a full review." |
| Required info | "your beta app description and beta app review information are required in order to share your beta with external testers". The Beta App Description field is explicitly required ([test information](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information)). Also needed: Feedback Email and Contact Information, and What to Test. |
| Privacy policy URL | Unverified for TestFlight. Apple's help pages (TestFlight overview, Invite external testers, Provide test information) don't mention a TestFlight privacy policy at all. Fill it in anyway, because Community testers' data is real personal data under GDPR. |
| DSA trader status | Not needed for TestFlight. Apple: "If you don't distribute apps on the App Store in the EU (for example you only distribute apps through alternative distribution, or TestFlight ...), you're not acting as a trader on the App Store" ([Apple](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements)). |
| Limits | Builds expire after 90 days. You can submit up to 6 builds for TestFlight review in 24 hours. External groups require an internal group to exist first. |
| Role | Account Holder, Admin or App Manager. |

Judgment: "follows the App Review Guidelines" means 1.2 (UGC), 5.1.1(v) (deletion) and the privacy items apply to any build that contains Community, even in beta.

### 4. Apple Developer Program enrollment (individual in Poland)

From [Enroll](https://developer.apple.com/programs/enroll/) and [Purchase and activation](https://developer.apple.com/support/purchase-activation/):

| Topic | Individual | Organization |
|---|---|---|
| Who | "an individual or sole proprietor/single person business". A Polish JDG enrolls this way. | A legal entity that "can enter into contracts with Apple". "We do not accept DBAs, fictitious business names, trade names, or branches." |
| Seller name on the store | "Your name will be displayed as the seller name" | "Your organization's name" |
| D-U-N-S | Not required | Required |
| Verification | Legal name, plus email, phone and address ("P.O. boxes are not accepted"). An Apple Account with 2FA. Age of majority. | Legal binding authority, a website, and an email on the organization's domain |
| Fee | "99 USD per membership year … listed in local currency during the enrollment process" | same |
| Payment | When paying by card as an individual, "you must use your own credit card". | |

- The PLN price isn't on the pages above. Apple says prices "are listed in local currency during the enrollment process". Whether Apple publishes it anywhere else is unverified.
- Fee waivers exist only for nonprofits, accredited educational institutions and government entities.
- Switching from individual to organization later means the seller name changes. Judgment: for a solo developer without a company, individual is the only route.

**DSA trader status** ([Apple](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements), [news 2025-01-16](https://developer.apple.com/news/?id=einwn76m)):
- "Starting February 17, 2025 … apps without trader status will be removed from the App Store in the European Union until trader status is provided and verified."
- A trader is anyone "acting … for purposes relating to his or her trade, business, craft or profession". "Apple can't determine whether you're a trader." "if you have a legal status associated with a business activity, that would suggest you may be a trader."
- **Individual traders** must enter an "Address or P.O. Box", a phone and an email. These are verified and **shown on the EU product page**. A P.O. box needs supporting documentation.
- **Non-traders:** EU consumers are told "consumer rights stemming from applicable consumer protection laws won't apply".
- Judgment: a free 1.0 with no business activity can plausibly declare non-trader. If you add a paid contribution tier, you would almost certainly be a trader and your contact details become public. The Support URL also has to lead to contact information "as may be required by local law".
- **Polish law points the same way (added by fact-check).** UŚUDE art. 5(2) requires a service provider to show "imię, nazwisko, miejsce zamieszkania i adres", or a business name and registered seat, "w sposób wyraźny, jednoznaczny i bezpośrednio dostępny". It applies to a "usługodawca", meaning someone who provides the service "prowadząc, chociażby ubocznie, działalność zarobkową lub zawodową" (art. 2 pkt 6) ([UŚUDE](https://api.sejm.gov.pl/eli/acts/DU/2024/1513/text.html)). Judgment: once CaliPark earns money (a paid tier), you must publish your name and an address under Polish law as well as on Apple's trader label. With a JDG this can be the business address. That is a real cost of the paywall idea and belongs in the monetization decision.

### 5. GDPR / RODO

Text from the [GDPR (EUR-Lex)](https://eur-lex.europa.eu/eli/reg/2016/679/oj).

#### 5.1 Role and scope
- You are the **controller** for Account, Community and moderation data. The household exemption (Art. 2(2)(c), "purely personal or household activity") doesn't cover running a public app.
- Training data that never leaves the device isn't processed by you. Judgment: if you later sync training data through your own backend, it becomes your processing. Apple-hosted iCloud/CloudKit private data is a separate case, and you should re-check it when you choose the sync design.
- Judgment (added by fact-check): today's training logs (exercise, sets, reps, optional external weight) are probably not "data concerning health" (Art. 4(15)). Adding body weight, injuries, pain notes or HealthKit data could change that and bring in Art. 9, which in practice means explicit consent. Keep synced training data free of health fields unless you plan for Art. 9.

#### 5.2 Legal bases (Art. 6(1)), suggested mapping (judgment)

| Processing | Basis |
|---|---|
| Creating an Account, publishing reviews and photos, showing them publicly | (b) contract: the *regulamin* |
| Moderation, spam and abuse prevention, security logs (IP addresses, rate limits), blocking | (f) legitimate interest. State the interest in the policy. |
| Keeping notices and statements of reasons, answering authorities' orders | (c) legal obligation: DSA Arts. 9, 16-18 |
| Optional analytics or crash SDKs, marketing email | (a) consent. Not planned for v1. |

#### 5.3 Privacy policy contents (Art. 13), plus Apple's extra points
- **Art. 13(1):** controller identity and contact; DPO (not applicable); purposes **and** legal basis; the legitimate interests pursued; recipients (each processor category); third-country transfers and safeguards.
- **Art. 13(2):** retention periods; the rights of access, rectification, erasure, restriction, objection and portability; withdrawal of consent; the right to complain to a supervisory authority (in Poland, the Prezes UODO); whether the data is required by contract; automated decision-making (state that there is none, or describe the automatic filter).
- **Apple 5.1.1(i) adds:** a statement that third parties give "the same or equal protection", and how to revoke consent and request deletion.
- Judgment: write it in Polish first, because Art. 12(1) asks for "intelligible and easily accessible form, using clear and plain language". Host it at a public URL and link it in the app and in App Store Connect.

#### 5.4 Processors and DPAs (Art. 28)
- Art. 28(3): processing by a processor "shall be governed by a contract or other legal act … binding on the processor". You need one for every vendor that stores or handles personal data: the database/auth host, photo storage/CDN, email sending, crash reporting, and any AI moderation API.
- Examples of how vendors provide one:
  - **Supabase:** the DPA "supplements and forms part of the Supabase Terms of Service" and includes EU SCCs (Modules 2 and 3), with a published sub-processor list. Version 1 is dated 2026-08-01 ([Supabase DPA](https://supabase.com/legal/dpa)).
  - **Hetzner:** you conclude the DPA in the customer account at accounts.hetzner.com ([Hetzner docs](https://docs.hetzner.com/general/company-and-policy/data-protection-at-hetzner)).
- **Transfers outside the EEA:** the EU-US Data Privacy Framework adequacy decision (2023/1795, adopted 10 July 2023) covers US companies that "participate in the Data Privacy Framework". Otherwise use SCCs ([European Commission](https://commission.europa.eu/law/law-topic/data-protection/international-dimension-data-protection/eu-us-data-transfers_en)).
- Judgment: an EU-hosted backend keeps the policy simpler.

#### 5.5 Data subject rights
- Answer "without undue delay and in any event within one month", extendable by two months for complex requests (Art. 12(3)).
- **Erasure (Art. 17):** the in-app deletion that Apple requires also covers this, if it deletes reviews, photos and the Sign in with Apple link.
- **Access and portability (Arts. 15, 20):** portability applies when the basis is contract or consent and processing is automated. That covers Account data, reviews and photos.
  - Judgment: for v1, an "export my data" request by email, answered with a JSON or ZIP file within one month, is enough.
  - An in-app export is a should-have.
  - A local training-data export also helps the "survive a new phone" goal.

#### 5.6 Records, security, breaches
- **Records of processing (Art. 30):** the exemption for fewer than 250 employees does not apply when "the processing is not occasional" (Art. 30(5)). Judgment: a permanently running backend is not occasional, so keep a one-page record of processing activities.
- **Breaches (Art. 33):** notify the supervisory authority (UODO) "not later than 72 hours after having become aware". The DPLA also requires notifying users ([DPLA](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)).

#### 5.7 Minimum age and parental consent
- Art. 8(1): when **consent** is the basis for an information society service offered directly to a child, the child must be "at least 16 years old". Below 16, a parent must give or authorise consent. "Member States may provide by law for a lower age … not below 13 years."
- **Poland has not lowered it.** The consolidated Polish Data Protection Act (Dz.U. 2019 poz. 1781) has no provision on this ([Sejm ELI text](https://api.sejm.gov.pl/eli/acts/DU/2019/1781/text.html); I searched the text for "13 lat", "16 lat" and art. 8 references and found none). Commentary agrees that the age is 16 in Poland ([Bird & Bird](https://childreninthedigitalworld.twobirds.com/home/poland)).
- Judgment: Art. 8 strictly bites only on consent-based processing, and CaliPark uses contract for the Community. A **minimum Account age of 16** in the *regulamin*, with a self-declaration checkbox at sign-up, is still the conservative and common choice. Training without an Account needs no age gate. **Trade-off (added by fact-check):** Apple then requires a 16+ App Store rating for the whole app (section 2.7).
- Optional: on iOS 26 and later, the Declared Age Range API can inform the gate, behind `#available`.

#### 5.8 Storing data on the device (Polish PKE art. 399, the ePrivacy rule)
- Storing or reading information on a user's device needs prior information and consent (art. 399(1)). The exception is when it is "konieczne do … dostarczania … usługi świadczonej drogą elektroniczną, żądanej przez abonenta lub użytkownika końcowego" (art. 399(3)(2)) ([PKE, Dz.U. 2024 poz. 1221](https://api.sejm.gov.pl/eli/acts/DU/2024/1221/text.html)).
- Judgment: local training logs, settings and the Account token are strictly necessary. A third-party analytics SDK would need consent.

#### 5.9 Photos of people (Polish image rights)
- Art. 81(1) of the Copyright Act: „Rozpowszechnianie wizerunku wymaga zezwolenia osoby na nim przedstawionej” ([Dz.U. 2025 poz. 24](https://api.sejm.gov.pl/eli/acts/DU/2025/24/text.pdf)). Art. 81(2) pkt 2 (exact wording, verified by the fact-check): permission isn't needed for the image of „osoby stanowiącej jedynie szczegół całości takiej jak zgromadzenie, krajobraz, publiczna impreza”.
- Judgment: the *regulamin* should ban photos where identifiable people are the subject, and moderation should reject them. This also fits Park photos, which should show equipment.
- **Licence to user photos and texts (added by fact-check).** Users own the copyright in their photos and reviews. Art. 67(1) says a licence covers "wymienionych w umowie polach eksploatacji", and only an exclusive licence needs written form (art. 67(5)). Judgment: a click-through *regulamin* can grant you a non-exclusive licence, but it should list the fields of exploitation: storing, reproducing, resizing, public display in the app and on the web. Without that clause your right to show and keep the photos is unclear.

### 6. EU Digital Services Act (Regulation (EU) 2022/2065)

Text: [DSA (EUR-Lex)](https://eur-lex.europa.eu/eli/reg/2022/2065/oj). Official XHTML from the Publications Office was used for the quotes.

#### 6.1 Is CaliPark covered?
- **Hosting service:** "the storage of information provided by, and at the request of, a recipient of the service" (Art. 3(g)(iii)).
- **Online platform:** "a hosting service that, at the request of a recipient of the service, stores and disseminates information to the public" (Art. 3(i)). Public Park reviews and photos fit this.
- **Information society service** means a service "normally provided for remuneration" ([Directive 2015/1535 Art. 1(1)(b)](https://eur-lex.europa.eu/eli/dir/2015/1535/oj)). Judgment: whether a completely free hobby app qualifies is arguable. Plan for compliance anyway, because the remaining obligations are cheap and Apple's 1.2 already needs most of them.

#### 6.2 The micro-enterprise exemptions
- Recommendation 2003/361/EC: "An enterprise is considered to be any entity engaged in an economic activity, irrespective of its legal form. This includes, in particular, self-employed persons". A microenterprise "employs fewer than 10 persons" and has turnover or balance sheet total "not exceed[ing] EUR 2 million" ([Recommendation 2003/361/EC](https://eur-lex.europa.eu/eli/reco/2003/361/oj)).
- **Art. 15(2):** annual transparency reports "shall not apply to providers of intermediary services that qualify as micro or small enterprises".
- **Art. 19(1):** Section 3 (Arts. 20-28: internal complaint system, out-of-court dispute settlement, trusted flaggers, dark patterns, ad transparency, Art. 28 protection of minors, and submissions to the transparency database) "shall not apply to providers of online platforms that qualify as micro or small enterprises", "with the exception of Article 24(3)". That exception means you supply user-number information when the coordinator or the Commission asks.

#### 6.3 What still applies

| Article | Obligation | CaliPark implementation (judgment) |
|---|---|---|
| 11 | A single electronic point of contact for authorities, published, with the languages it accepts (including Polish) | A contact email on the website: „Kontakt dla organów” (contact for authorities). |
| 12 | A single point of contact for users, "directly and rapidly", electronic, and "not solely rely on automated tools" | The same email as Apple 1.2 and the Support URL. |
| 14 | The terms must describe content restrictions, "policies, procedures, measures and tools used for the purpose of content moderation, including algorithmic decision-making and human review", in clear language and machine-readable. Apply them in a "diligent, objective and proportionate manner". | A moderation section in the *regulamin*: the wordlist filter, photo pre-moderation, the human review, and how to appeal by email. |
| 16 | A notice mechanism for "any individual or entity", "exclusively by electronic means". It must make it easy to give reasons, the exact location (URL/ID), name and email (except for CSAM reports), and a good-faith statement. Confirm receipt "without undue delay", notify the decision with redress options, and decide "in a timely, diligent, non-arbitrary and objective manner". | The "Zgłoś" form in the app and on the web (for people without an Account). It pre-fills the item ID and has a reason, an optional name and email, and a good-faith checkbox. Send an automatic acknowledgement email and a decision email. |
| 17 | A statement of reasons to the uploader when you remove or limit content or suspend an Account, where you know their email. It must cover: the measure and its scope; the facts, including whether it followed a notice; any automated means; the legal or contractual ground; and redress (complaints, out-of-court settlement, courts). | Template emails sent through the Sign in with Apple relay, which needs the registered domain from section 2.2. Keep a log. |
| 18 | Promptly tell police or prosecutors about information suggesting a crime that threatens life or safety | A written one-paragraph procedure. |

#### 6.4 Polish implementation (rewritten by fact-check from the Dziennik Ustaw entry)
- **In force from 2026-11-06.** The law is *Ustawa z dnia 4 września 2026 r. o zmianie ustawy o świadczeniu usług drogą elektroniczną oraz niektórych innych ustaw*, Dz.U. 2026 poz. 1296. It was published 2026-10-06 and takes effect 2026-11-06 ("po upływie 30 dni od dnia ogłoszenia") ([Sejm ELI metadata](https://api.sejm.gov.pl/eli/acts/DU/2026/1296), [text PDF](https://api.sejm.gov.pl/eli/acts/DU/2026/1296/text.pdf)). UODO reported the signature on 2026-09-28 ([UODO](https://uodo.gov.pl/pl/138/4587)).
- **Authorities.** "Koordynatorem do spraw usług cyfrowych jest Prezes UKE" (new art. 15b). The Prezes UOKiK is the competent authority for consumer-interest breaches and for the Section 4 marketplace duties (art. 15a).
- **Fines.** New art. 22zzn(2): a "dostawca usługi hostingu" that breaches DSA "art. 16 ust. 1, 2 i 4–6", "art. 17 ust. 1, 3 i 4" or "art. 18" "podlega administracyjnej karze pieniężnej". Art. 22zzn(1) does the same for intermediary services that breach Arts. 11, 12, 14 and 15(1). The ceiling is "6 % światowego obrotu" (art. 22zzn(5)).
- **Complaints and damages.** Users can complain to the coordinator about a provider (art. 22zh). Damages claims under DSA Art. 54 go to the *sąd okręgowy* (art. 22zzi).
- **Scope caveat (judgment).** The new definition is "dostawca usługi pośredniej – usługodawcę świadczącego usługę pośrednią", and UŚUDE's "usługodawca" requires economic or professional activity "chociażby ubocznie". A zero-revenue hobby app may sit outside the Polish fine regime. That changes once you monetize. The DSA's own obligations apply directly in any case, and Apple 1.2 requires most of them anyway.
- History: on 2026-01-26 the ministry said Poland hadn't yet implemented the DSA ([gov.pl](https://www.gov.pl/web/cyfryzacja/polska-potrzebuje-wdrozenia-dsa--ministerstwo-cyfryzacji-przygotowalo-nowe-przepisy)). An earlier bill was vetoed in January 2026; EDRi's article is dated 2026-01-21, and the exact veto date is unverified ([EDRi](https://edri.org/our-work/presidents-veto-further-delays-the-implementation-of-the-dsa-in-poland/)). A second law on content blocking passed the Sejm, and its status is unverified. It targets orders from the Prezes UKE and KRRiT, not small hosts' day-to-day duties.

#### 6.5 Terrorist content online, Regulation (EU) 2021/784 (added by fact-check)
- This applies to hosting service providers "offering services in the Union ... insofar as they disseminate information to the public", whatever their size. When an authority issues a removal order, content must come down "in any event within one hour of receipt" (Art. 3(3)). Each provider must "designate or establish a contact point for the receipt of removal orders by electronic means" (Art. 15(1)) ([EUR-Lex](https://eur-lex.europa.eu/eli/reg/2021/784/oj)). EUR-Lex didn't load during the fact-check. The quotes match secondary summaries ([eumonitor](https://eumonitor.eu/9353000/1/j4nvhdfcs8bljza_j9vvik7m1c3gyxp/vkrpfdcsi7yp), [Bundesnetzagentur](https://bundesnetzagentur.de/EN/Areas/Digitalisation/Internet/TerrorOnlIn/start.html)), so treat the exact wording as unverified.
- Judgment: the chance of this happening is tiny, but the cost is too. Name the same contact email as the TCO contact point and give admin tools a "remove now" path. Note the one-hour window next to the 24-hour Apple target.

### 7. Polish *regulamin* (UŚUDE art. 8)

[UŚUDE, consolidated Dz.U. 2024 poz. 1513](https://api.sejm.gov.pl/eli/acts/DU/2024/1513/text.html), art. 8:
- The provider "określa regulamin" and "nieodpłatnie udostępnia usługobiorcy regulamin przed zawarciem umowy".
- Users aren't bound by terms they weren't given that way (art. 8(2)).
- Required content (art. 8(3)):
  - types and scope of services
  - technical requirements
  - „zakaz dostarczania przez usługobiorcę treści o charakterze bezprawnym”
  - how contracts are concluded and terminated
  - „tryb postępowania reklamacyjnego”

Judgment: one Polish *regulamin* can also serve as Apple's EULA with zero-tolerance wording, the DSA Art. 14 terms, and the GDPR contract basis. Show it with a checkbox before the first publication.

Scope caveat (added by fact-check): art. 8 binds a "usługodawca", meaning someone acting "prowadząc, chociażby ubocznie, działalność zarobkową lub zawodową" (art. 2 pkt 6). The same definition triggers the art. 5 duty to publish your name and address (section 4). Judgment: for a zero-revenue 1.0 it is arguable whether UŚUDE applies at all. Write the *regulamin* anyway for Apple and the DSA, and treat art. 5 and art. 8 as binding from the moment any revenue appears. Two more clauses belong in it: the minimum Account age, which drives the App Store rating (section 2.7), and the licence to user photos and texts (section 5.9).

## Recommendation

### Checklist A: must-have for external TestFlight

Items marked **[C]** apply only if the build contains Community features.

1. Enroll in the Apple Developer Program as an individual (99 USD/yr). Do it **before** building Sign in with Apple, because the capability is ADP-only.
2. Settle the bundle ID, app name and seller (legal) name before the first upload.
3. Add `PrivacyInfo.xcprivacy`: `NSPrivacyTracking=false`, `UserDefaults` → `CA92.1`, plus collected data types. Without it, App Store Connect rejects the upload.
4. Add `ITSAppUsesNonExemptEncryption = NO`.
5. Set `TARGETED_DEVICE_FAMILY = 1`, iPhone portrait-only unless designed otherwise. Smoke-test on an iPad simulator **and on the iPhone Duo simulator** (outer and inner display), because iPhone-only apps run natively on the foldable.
6. Purpose strings:
   - Fix the location string (Parks, not "siłownie").
   - Remove `NSPhotoLibraryAddUsageDescription` unless it's used.
   - Keep the camera string only if the camera is reachable, and guard camera availability.
   - The map must work when location is denied, with search or a manual area.
7. Remove the review-visible mocks: fake reviews, weather, "Michał", Unsplash hotlinks, dead Profile rows, unreachable Premium and events. Guidelines 2.1, 2.3 and 2.5.19.
8. TestFlight test information: Beta App Description, Feedback Email, contact information, What to Test, and review notes explaining that no login is needed for training and that Sign in with Apple uses the reviewer's own Apple Account.
9. Privacy policy (Polish) at a public URL, linked in the app.
10. **[C]** Sign in with Apple:
    - Accept all three relay domains (`private.icloud.com`, `privaterelay.appleid.com`, `icloud.com`).
    - Store the refresh token server-side for revocation.
    - Handle `getCredentialState`.
11. **[C]** In-app account deletion that removes the Account, reviews and photos, revokes the Sign in with Apple token, and tells the user the timing.
12. **[C]** Guideline 1.2 set:
    - accept the *regulamin* (zero tolerance) before the first post
    - text filter
    - photo pre-moderation
    - a Report action on every item, working without an Account too
    - Block user
    - in-app contact email
    - an admin path to remove content and ban an Account within 24 hours
13. **[C]** EXIF/GPS stripping by re-encoding on the device before upload, and again on the server.
14. **[C]** An Art. 28 DPA accepted with every backend vendor **before** real testers' data is stored. Prefer EU hosting.
15. **[C]** *Regulamin* published: UŚUDE art. 8 content, DSA Art. 14 moderation rules, a non-exclusive licence to user photos and texts with the fields of exploitation listed, and the minimum Account age with a self-declaration checkbox. The age must match the App Store age rating (B4).
16. **[C]** Park data model: never store MapKit search or geocoding results (POIs, addresses, coordinates) on the server (DPLA Attachment 6, 2.2 and 2.5). Store only user-placed pins and user-typed text, or ODbL data.

### Checklist B: must-have for App Store release (in addition to A, with all [C] items now mandatory)

1. App Privacy (nutrition label) answers that match the privacy manifest and the real backend behaviour.
2. Privacy Policy URL in App Store Connect and in the app.
3. Support URL with real contact information, and the Copyright field.
4. Age rating questionnaire, including the Social Media questions (required since September 2026) and the Shared Location and Dating declarations (required on submissions from 2026-11-16). **If the *regulamin* sets a minimum age above the computed rating, Apple requires overriding to that age** (for example 16+ for a 16+ Account age).
5. DSA trader or non-trader declaration in App Store Connect. Without it, the app isn't listed in Poland or the rest of the EU.
6. iPhone screenshots: the Dynamic Island medium display size is required. **From April 2027, iPhone Duo screenshots are also required** (outer 1398×2034, inner 2007×2853). That covers any 1.0 submitted in April 2027 or later.
7. Decide availability: opt out of Apple-silicon Mac and Vision Pro. Limit storefronts to Poland or the EU for 1.0.
8. DSA basics live:
   - notice form for anyone (in the app and on the web)
   - acknowledgement and decision emails with redress information
   - statement-of-reasons template
   - points of contact (Arts. 11 and 12) published
   - Art. 18 procedure written down
9. GDPR basics:
   - Art. 13 privacy policy
   - record of processing activities
   - a process for access, export and deletion requests within one month
   - a 72-hour breach procedure (UODO plus user notice)
10. No dormant or remote-switched features (2.5.19). Every Community feature must be in the reviewed build.
11. If weather stays: WeatherKit with Apple Weather attribution, no long-term caching, and no fee for raw weather data. Otherwise remove it.
12. If Parks are seeded from OpenStreetMap: ODbL attribution in the app, and a decision on share-alike for the Park database.
13. Regulated Medical Device declaration: answer "No" if the category is Health & Fitness (required for EU/EEA, UK and US availability).
14. Backend live during review, including the moderation tools ("Before You Submit"). Add Notes on how to reach Community and how reports are handled.

### Checklist C: should-have

1. Use `LocationButton` (one-time authorization) instead of a standing When-In-Use prompt.
2. Sign in with Apple server-to-server notifications endpoint (`consent-revoked`, `account-deleted`), and register the email domain with SPF so DSA and moderation emails reach relay addresses.
3. An in-app "export my data" for Community data, and a local training-data export (this also helps with phone migration).
4. Blur incoming photos for viewers who turned on Sensitive Content Warning, using `SensitiveContentAnalysis`. This is for viewers only, not a moderation signal.
5. Rate limits and simple reputation for contributors. This covers spam resistance before any paywall, and stays free.
6. A moderation log that stores notice, decision, statement of reasons and timestamps. It serves DSA, Apple and Art. 24(3) requests.
7. Polish legal documents first, with English and Ukrainian translations when those localizations ship.
8. Declared Age Range API gating for Account creation on iOS 26+, before you expand to US storefronts.
9. A short internal moderation policy: what is removed, response targets, and ban criteria.
10. TCO Regulation contact point: name the authorities' contact email as the point for removal orders, and keep a way to remove content within one hour (section 6.5).
11. Keep server, proxy and CDN logs free of user coordinates, so "nearby" queries stay "not collected" for the nutrition label.
12. Don't send Community content to a third-party AI moderation API without explicit user permission (guideline 5.1.2(i)).

### Sequencing advice (judgment)
- **Winter TestFlight:** a training-only build, so items A1-A9 apply. Get the review approved early to flush out issues with metadata, the manifest and mocks.
- **Community beta:** add Community in a new version that goes through TestFlight review, with all [C] items in place.
- **App Store 1.0:** complete checklist B.
- Sending each Community feature through review keeps you clear of 2.5.19 and lets reviewers see the moderation tools.

## Open questions for the owner

1. Will the winter TestFlight include Community, or training only? This decides how many [C] items have to be ready this winter.
2. Trader or non-trader for 1.0? If you plan a paid contribution tier, you will likely become a trader. Your address (or a documented P.O. box), phone and email would then be public on the EU product page. Do you want a JDG or a virtual-office address for that?
3. Whose legal name will be the seller? The bundle ID is currently `com.michalbryk.cali-park`. Change it before the first upload if it shouldn't carry that name.
4. Moderation model: pre-moderate all photos manually (recommended for v1), and post-moderate reviews with a wordlist? Can you personally commit to acting on reports within 24 hours, including weekends?
5. On account deletion, delete the user's reviews and photos (Apple's guidance names reviews and photos explicitly), or keep fully anonymized ratings only? Anonymizing is a gray area for Apple; deleting is the safe path.
6. Keep a weather module in 1.0 (WeatherKit plus attribution), or drop it?
7. Park data source: OpenStreetMap import (ODbL attribution and share-alike) or your own and user submissions only?
8. Training-data migration to a new phone: iCloud/CloudKit, your own backend, or file export? This changes the nutrition label and the GDPR scope.
9. Minimum Account age: 16 (the GDPR default in Poland), 13, or 18? Whatever the *regulamin* says, Apple requires the App Store rating to be overridden to at least that age, for the whole app. Is a 16+ rating acceptable for a training app that teenagers would use?
10. Any analytics or crash SDK planned? It would need consent under PKE art. 399 and must appear in the labels and the manifest.
11. Storefronts for 1.0: Poland only, the EU, or worldwide? Worldwide adds US state age-assurance duties (Texas SB 2420).
12. Do you want a lawyer to review the *regulamin* and privacy policy before 1.0? Estimate: a one-off review of two short documents by a Polish practitioner typically costs a few hundred to low thousands of PLN. This is not sourced; ask for quotes.
13. The contribution paywall: any revenue likely makes you a DSA trader on the App Store (address, phone and email public on EU product pages), a UŚUDE "usługodawca" (name and address published under art. 5), and subject to the Polish DSA fine regime. Is the spam-resistance benefit worth that, compared with free rate limits, reputation and photo pre-moderation?
14. Will the Park map use only user-placed pins and OSM data, or MapKit search and geocoding? The latter can't be stored server-side under the Apple Maps terms.

## Sources

Apple:
- App Review Guidelines (last updated 2026-10-16): https://developer.apple.com/app-store/review/guidelines/
- Strengthening App Review Guidelines (2026-10-16): https://developer.apple.com/news/?id=vvzx6cul
- Guideline 1.2 rejection text (forum, Nov 2025): https://developer.apple.com/forums/thread/807358
- Offering account deletion in your app: https://developer.apple.com/support/offering-account-deletion-in-your-app/
- Sign in with Apple REST API, revoke tokens: https://developer.apple.com/documentation/signinwithapplerestapi/revoke-tokens
- Processing changes for Sign in with Apple accounts: https://developer.apple.com/documentation/signinwithapple/processing-changes-for-sign-in-with-apple-accounts
- Private email relay service: https://developer.apple.com/documentation/signinwithapple/communicating-using-the-private-email-relay-service
- New Sign in with Apple domain (2026-08-24): https://developer.apple.com/news/?id=1ptvdtcm
- App privacy details: https://developer.apple.com/app-store/app-privacy-details/
- Privacy manifest files: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- Describing use of required reason API: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- NSPrivacyAccessedAPIType reason codes: https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype
- Age ratings values and definitions: https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions
- Updated age ratings (2025-07-24): https://developer.apple.com/news/?id=ks775ehf
- Social media age rating questions (2026-07-09): https://developer.apple.com/news/?id=tlur8uvi
- New age rating content descriptors (2026-11-02): https://developer.apple.com/news/?id=yxkh08us
- Texas SB 2420 update (2026-06-03): https://developer.apple.com/news/?id=sg176nne
- SDK minimum requirements, April 2027 (2026-09-09): https://developer.apple.com/news/?id=k1mtkt1k
- NSLocationWhenInUseUsageDescription: https://developer.apple.com/documentation/bundleresources/information-property-list/nslocationwheninuseusagedescription
- LocationButton: https://developer.apple.com/documentation/corelocationui/locationbutton
- kCGImageMetadataShouldExcludeGPS: https://developer.apple.com/documentation/imageio/kcgimagemetadatashouldexcludegps
- Sensitive Content Analysis: https://developer.apple.com/documentation/sensitivecontentanalysis/detecting-nudity-in-media-and-providing-intervention-options
- Screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- Mac availability of iPhone apps: https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-of-iphone-and-ipad-apps-on-macs-with-apple-silicon
- Vision Pro availability of iPhone apps: https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-of-iphone-and-ipad-apps-on-apple-vision-pro
- Platform version information (Support URL, demo account): https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
- Encryption export compliance: https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations
- TestFlight overview: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview
- Invite external testers: https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/
- Provide test information: https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information
- TestFlight: https://developer.apple.com/testflight/
- Enroll: https://developer.apple.com/programs/enroll/
- Purchase and activation: https://developer.apple.com/support/purchase-activation/
- Supported capabilities (iOS): https://developer.apple.com/help/account/reference/supported-capabilities-ios
- DSA trader requirements: https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements
- Apps without trader status removed (2025-01-16): https://developer.apple.com/news/?id=einwn76m
- WeatherKit, get started: https://developer.apple.com/weatherkit/get-started/
- Apple Developer Program License Agreement (Attachment 8, WeatherKit; Attachment 6, Apple Maps Service; 3.3.3(F) location consent; privacy policy and breach clauses): https://developer.apple.com/support/terms/apple-developer-program-license-agreement/
- Set an app age rating (EULA minimum age override): https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating
- Declare Regulated Medical Device Status: https://developer.apple.com/help/app-store-connect/manage-app-information/declare-regulated-medical-device-status
- Prepare and submit your apps for iPhone Duo (2026-10-05): https://developer.apple.com/news/?id=kkphp5qo
- Preparing your app for iPhone Duo: https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo
- Updated App Review Guidelines (2026-10-16, change list): https://developer.apple.com/news/?id=92th7e5i

EU and Polish law:
- GDPR, Regulation (EU) 2016/679: https://eur-lex.europa.eu/eli/reg/2016/679/oj
- DSA, Regulation (EU) 2022/2065: https://eur-lex.europa.eu/eli/reg/2022/2065/oj
- Directive (EU) 2015/1535 (definition of information society service): https://eur-lex.europa.eu/eli/dir/2015/1535/oj
- Commission Recommendation 2003/361/EC (micro and small enterprises): https://eur-lex.europa.eu/eli/reco/2003/361/oj
- EU-US Data Privacy Framework: https://commission.europa.eu/law/law-topic/data-protection/international-dimension-data-protection/eu-us-data-transfers_en
- Polish Data Protection Act, consolidated Dz.U. 2019 poz. 1781: https://api.sejm.gov.pl/eli/acts/DU/2019/1781/text.html
- UŚUDE, consolidated Dz.U. 2024 poz. 1513: https://api.sejm.gov.pl/eli/acts/DU/2024/1513/text.html
- Prawo komunikacji elektronicznej, Dz.U. 2024 poz. 1221 (art. 399): https://api.sejm.gov.pl/eli/acts/DU/2024/1221/text.html
- Copyright Act, consolidated Dz.U. 2025 poz. 24 (art. 81): https://api.sejm.gov.pl/eli/acts/DU/2025/24/text.pdf
- Ministry of Digital Affairs on DSA implementation (2026-01-26): https://www.gov.pl/web/cyfryzacja/polska-potrzebuje-wdrozenia-dsa--ministerstwo-cyfryzacji-przygotowalo-nowe-przepisy
- Polish DSA implementing act, Dz.U. 2026 poz. 1296 (in force 2026-11-06): https://api.sejm.gov.pl/eli/acts/DU/2026/1296 (text: https://api.sejm.gov.pl/eli/acts/DU/2026/1296/text.pdf)
- UODO on the signature of the first DSA implementing law (2026-09-28): https://uodo.gov.pl/pl/138/4587
- Regulation (EU) 2021/784 (terrorist content online): https://eur-lex.europa.eu/eli/reg/2021/784/oj

Vendors and other:
- Supabase DPA: https://supabase.com/legal/dpa
- Hetzner data protection and DPA: https://docs.hetzner.com/general/company-and-policy/data-protection-at-hetzner
- OpenStreetMap copyright and licence: https://www.openstreetmap.org/copyright

Secondary (used only where no primary source was found):
- Bird & Bird, children's data in Poland: https://childreninthedigitalworld.twobirds.com/home/poland
- Interia, President signs DSA implementing law (2026), superseded by the Dziennik Ustaw entry above: https://biznes.interia.pl/gospodarka/news-nawrocki-podpisal-ustawe-polska-bedzie-mogla-karac-platformy,nId,23549252
- EDRi, presidential veto of the DSA bill (2026-01-21): https://edri.org/our-work/presidents-veto-further-delays-the-implementation-of-the-dsa-in-poland/
- TCO Regulation summaries (used because EUR-Lex didn't load): https://eumonitor.eu/9353000/1/j4nvhdfcs8bljza_j9vvik7m1c3gyxp/vkrpfdcsi7yp, https://bundesnetzagentur.de/EN/Areas/Digitalisation/Internet/TerrorOnlIn/start.html

## Fact-check (2026-11-03)

I re-opened the primary sources: Apple doc JSON and help pages, the live App Review Guidelines, the DPLA HTML, Sejm ELI texts and metadata, and the vendor pages. I also re-checked the repo (`project.pbxproj`, sources).

**Confirmed as written:**
- Guidelines last updated 2026-10-16. The quotes from 1.2, 2.4.1, 2.5.19, 4.5.4, 4.8, 5.1.1(i)–(v) and 5.1.5 match.
- The 2026-10-16 NCII and bait-and-switch news. The forum rejection text (thread 807358, Nov 2025).
- Privacy manifest: the 2024-05-01 enforcement sentence, and reason codes CA92.1, 1C8F.1, C617.1, 35F9.1, E174.1 with their texts.
- Account-deletion page quotes, including UGC and reviews. Revoke-token requirements. Sign in with Apple server notifications. The relay limit of 100 emails per day and the SPF and domain registration.
- Capabilities table: Sign in with Apple and WeatherKit are ADP-only. CloudKit and push are ADP and ADEP, not free.
- Age ratings: 4+, 9+, 13+, 16+, 18+, the definitions, the Social Media questions required from September 2026, and the Shared Location and Dating descriptors (2026-11-16, all apps by 2027-01-12).
- Texas SB 2420 effective 2026-06-04 for new Texas accounts. iOS 27 SDK required from April 2027.
- Screenshot sizes. Mac and Vision Pro default availability. ITSAppUsesNonExemptEncryption.
- TestFlight: 100 internal and 10,000 external testers, 90 days, 6 builds per 24 hours, an internal group before an external one, and the roles.
- Enrollment: 99 USD, seller name, D-U-N-S only for organizations, own credit card, fee waivers.
- DSA trader rules (2025-02-17). WeatherKit: 500k calls included, US$49.99 for 1M, attribution, Attachment 8 clauses.
- Supabase DPA v1 dated 2026-08-01 with SCC Modules 2 and 3. Hetzner DPA in accounts.hetzner.com.
- UŚUDE art. 8. PKE art. 399. Copyright Act art. 81. Repo state: `"1,2"`, the "siłownie" string, no privacy manifest, `UserDefaults` in 8 files, bundle ID `com.michalbryk.cali-park`.

**Corrected:**
- **Age rating (section 2.7, B4, open question 9).** The file said a higher rating was optional and that the Account age is "enforced in the regulamin, not by the rating". Apple's help page says that if a EULA's minimum age exceeds the computed rating, you "must override" to match. A 16+ Account age means a 16+ rating for the whole app.
- **Relay domains.** Apple lists three: `@private.icloud.com`, `@privaterelay.appleid.com` and `@icloud.com`. The file said "both".
- **5.1.2(i).** Sharing data with third-party AI needs explicit permission, not only disclosure.
- **Polish DSA implementation (section 6.4).** This was based on press reports and was rewritten from Dz.U. 2026 poz. 1296. It takes effect 2026-11-06, the Prezes UKE is the coordinator, and hosting providers face fines for breaching DSA Arts. 16, 17 and 18. The 2026-01-09 veto date is now marked unverified.
- ***Regulamin* applicability.** UŚUDE binds a "usługodawca" engaged in economic or professional activity, so its application to a zero-revenue app is arguable. The file had stated it as an unconditional requirement.
- **Copyright Act art. 81(2).** The exact wording was extracted and replaces the paraphrase.
- **Export compliance.** Added Apple's caveat about a possible US year-end self-classification report.
- **PLN price.** The claim "Apple doesn't publish it" is now marked unverified.

**Added (missing and relevant to the owner's decisions):**
- Apple Maps Service terms: no derived database and no caching of Map Data. This constrains how Parks are stored (Answer 9, A16, open question 14).
- iPhone Duo: sold since 2026-10-23, screenshots required from April 2027, and iPhone-only apps must resize. The simulator is in the installed Xcode 27.2.
- Regulated Medical Device declaration for Health & Fitness apps.
- UŚUDE art. 5 duty to publish name and address once the service is commercial. This matters for the paywall decision (open question 13).
- TestFlight-only distribution needs no DSA trader status.
- The "Before You Submit" demo-account and live-backend wording.
- The "Fitness" nutrition-label type if training data syncs. A GDPR Art. 9 caution on health fields. Server logs and the "not collected" test for location.
- A licence to user content in the *regulamin* (Copyright Act art. 67).
- The TCO Regulation's one-hour removal orders and contact point.

**Could not verify:**
- Whether TestFlight external testing requires a Privacy Policy URL. No Apple page mentions it either way.
- How iPhone-only apps are presented on iPadOS 26/27, and how a portrait lock behaves on the iPhone Duo inner display. Only community sources exist.
- That App Review accepts "sign in with your own Apple Account" instead of a demo account for Sign in with Apple–only apps.
- Whether CloudKit private-database sync counts as "collected" for labels.
- The exact TCO Regulation wording, because EUR-Lex didn't load and secondary summaries were used.
- The status of Poland's second DSA law on content blocking. The 2026-01-09 veto date.
- Whether a free hobby app is an "information society service" or a "usługodawca" at all. This is a legal judgment.
- The lawyer cost estimate in open question 12.

**Bottom line:** the recommendation holds. Ship a training-only external TestFlight first, with the privacy manifest, fixed purpose strings, iPhone-only and the mocks removed. Then put Community through review with every 1.2, deletion, DSA and GDPR item in place. Before writing the *regulamin*, decide three new things: the Account minimum age, which now sets the App Store rating; whether Park locations avoid Apple Map Data; and whether the paywall is worth publishing your name and address. Plan iPhone Duo screenshots and layout if 1.0 is submitted in April 2027 or later.
