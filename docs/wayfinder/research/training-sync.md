# Training data: surviving a phone switch and syncing without an Account

Research question: how should CaliPark's training data (workout log, workout plans, skill placement, skill progress) survive a phone switch and sync across one person's devices without a CaliPark Account? The options compared are CKSyncEngine, SwiftData + CloudKit, Core Data + `NSPersistentCloudKitContainer`, iCloud Drive documents, `NSUbiquitousKeyValueStore`, and, for contrast, sync through the Community backend with an Account.

Researched 2026-11-03. All sources were read on that date. Figures marked *(estimate)* are mine. Everything else is cited inline and listed under [Sources](#sources).

## Answer

- **Most phone switches already work today.** The four JSON files sit in `Documents/`, and iOS backs up `Documents/` and `Library/Application Support/` alike ([File System Programming Guide](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html)). iCloud Backup and Quick Start therefore carry them to a new iPhone ([Apple Support 108770](https://support.apple.com/en-us/108770), [102659](https://support.apple.com/en-us/102659)).
- **That safety net has holes.** Data is lost when the user sets up the new phone as new, has iCloud Backup off, has switched off backup for this one app (iOS lets users "stop backing up apps" individually, [108770](https://support.apple.com/en-us/108770)), or has full iCloud storage, where 5 GB is free and a full account stops backups ([108922](https://support.apple.com/en-gb/108922)). It is also lost when the user deletes and reinstalls the app ([108429](https://support.apple.com/en-us/108429)). Backup never syncs two devices.
- **Recommendation: keep the JSON stores as the local source of truth and add a CKSyncEngine layer.** It syncs to the user's CloudKit private database in a custom zone, with one record per log entry and per plan, plus fixed-name records for placement and progress. The payload goes in encrypted fields. CKSyncEngine is iOS 17+ ([docs](https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5)). It needs no Account, and the developer pays nothing, because private-database data counts toward the user's own iCloud quota ([docs](https://developer.apple.com/documentation/cloudkit/ckcontainer/privateclouddatabase)). I estimate about 0.5–3.5 MB per active user per year.
- **Why not SwiftData or Core Data + CloudKit:** both would force a rewrite of the value-type stores into managed classes. Both resolve conflicts last-writer-wins. Neither supports unique constraints, so the placement and progress singletons can duplicate. **iCloud Drive** gives whole-file conflicts on an ever-growing log. **Key-value store** is capped at 1 MB and stored unencrypted on disk, so it suits only tiny flags. **Account sync** contradicts "training never needs an Account", costs money per user, and makes you the holder of users' fitness data.
- **Hard prerequisites.** Every iCloud option needs the paid Apple Developer Program (99 USD/yr) ([capabilities table](https://developer.apple.com/help/account/reference/supported-capabilities-ios)). TestFlight builds use the CloudKit **production** environment, and the production schema can only be added to, never changed ([Deploying the schema](https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema)). An Apple DTS engineer confirmed in August 2026 that the environment can't be changed for TestFlight builds ([forum 842909](https://developer.apple.com/forums/thread/842909)). The record design therefore has to be settled before the first TestFlight build with sync. The one way around this is an Ad Hoc "Release Testing" build, which can use the Development environment, but only on registered devices (up to 100 iPhones per membership year) ([same thread](https://developer.apple.com/forums/thread/842909), [Devices overview](https://developer.apple.com/help/account/devices/devices-overview)).
- **The container belongs to whichever developer team creates it, and it can't be deleted.** An Apple staff forum reply says deleting a container "is currently not supported" (2016). Later community reports say the CloudKit Console can only hide containers ([forum 45251](https://developer.apple.com/forums/thread/45251)). The project is signed with team `2Z64844RK3` under the bundle ID `com.michalbryk.cali-park` (audit G-24). Create the container only after the owner's own paid team and the final bundle ID are in place.
- **Order of work:** first harden the JSON stores (audit C-1, C-4, A-6), move them to Application Support, and add export/import. None of that needs a paid membership. Then build the CKSyncEngine layer once the membership is bought.

## Findings

### 1. What the codebase persists today

| Store (protocol → app implementation) | File (in `Documents/`) | Shape | Mutations used by the app | Conflict profile |
|---|---|---|---|---|
| `WorkoutLogStoring` → `FileWorkoutLogStore` | `workout-log.json` | bare array of `WorkoutLogEntry` (UUID `id`, sets, optional `sessionID`/`planID`) | `append`, `append(contentsOf:)`, `delete(id:)`; entries are never edited | append-mostly, immutable records |
| `WorkoutPlanStoring` → `FileWorkoutPlanStore` | `workout-plans.json` | bare array of `WorkoutPlan` (UUID `id`, `WorkoutSchedule` enum with associated values, `createdAt`, optional `reminderTime`) | upsert `save`, `delete(id:)` | editable on any device |
| `PlacementStoring` → `FileSkillPlacementStore` | `skill-placement.json` | one `SkillPlacement` (`[ProgressionPathID: Int]` rung *indices*, equipment set, `declaredAt`) | whole-value `save` | singleton, user intent |
| `SkillProgressStoring` → `FileSkillProgressStore` | `skill-progress.json` | one `SkillProgress` (`Set<RungReference>` with rung *indices*, `celebratedLevel`) | whole-value `save` | singleton, monotonic bookkeeping |
| `FavoritesStoring` → `UserDefaultsFavoritesStore` | UserDefaults | `Set<UUID>` of park IDs | whole-set save | not training data |

Other facts from the code and the audit that shape the sync design:

- Every store loads and saves the whole file, and each mutation is load → mutate → atomic write. A read or decode failure returns `[]` or `nil`, and the next write then wipes the data (audit **C-1/B-2**). Sync would multiply the ways a bad payload reaches a device, so this must be fixed first.
- There is no schema versioning: bare arrays, synthesized `Codable`, and `[ProgressionPathID: Int]` encoded as an unkeyed alternating array (audit **C-4**). Rungs are identified by array index (audit **A-6**). Once two devices on different app versions exchange records, both of these become cross-device bugs.
- The Core Data stack is an empty scaffold that the audit recommends deleting (**C-10**). There is no export or backup feature (**C-17**). Files live in `Documents/` rather than Application Support (**C-15**).
- `WorkoutLogEntry`, `WorkoutPlan`, `SkillPlacement` and `SkillProgress` are value types consumed by pure engines (`ProgressionEngine`, `RewardEvaluator`). A sync layer that keeps those structs avoids touching the domain layer.
- The app has no `.entitlements` file, and `DEVELOPMENT_TEAM = 2Z64844RK3` is the only team configured. The bundle ID is still `com.michalbryk.cali-park` (audit G-24). The iCloud container identifier is usually derived from the bundle ID and is effectively permanent, so the bundle ID should be settled before any iCloud work. The team matters even more. A container is registered under the team that creates it, and containers can't be deleted (see §4, Developer Program). Confirm that `2Z64844RK3` is the owner's own team, or switch to it, before the first iCloud capability is added.
- `TARGETED_DEVICE_FAMILY = "1,2"`, so the target builds for iPad as well as iPhone, while the 1.0 decision says iPhone-only. That doesn't affect sync, but the "later iPad" row below assumes iPad stays possible.

### 2. What device backup and Quick Start already transfer

**Directories** ([File System Programming Guide](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html), [Optimizing your app's data for iCloud Backup](https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup)):

| Directory | Backed up by iCloud / computer backup? | Intended content (Apple's wording, summarized) |
|---|---|---|
| `Documents/` | Yes | "user-generated content"; "should only contain files that you may wish to expose to the user" |
| `Library/Application Support/` | Yes ("In iOS, the contents of this directory are backed up by iTunes and iCloud") | "app-created data files … managed by the app", hidden from the user, in a subdirectory named after the bundle ID or company |
| `Library/Caches/` | No; also may be purged when disk is low | re-creatable data |
| `tmp/` | No | temporary files |

- For backup purposes, Documents and Application Support behave **the same**. Moving the JSON files to Application Support (audit C-15) is about intent and hygiene, not survivability.
- `isExcludedFromBackup` is only "guidance to the system", not a guarantee ([docs](https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup)). Do not set it on training files.

**What the user-facing flows do:**

- iCloud Backup "includes app data for the apps that you've downloaded on your device". Data an app stores in iCloud Drive is "stored in iCloud instead of your iCloud Backup" ([108770](https://support.apple.com/en-us/108770)).
- The same page says users can "stop backing up apps that you don't use anymore", so backup can be off for CaliPark alone. When iCloud Backup is turned off for a device, existing backups are kept for 180 days ([108770](https://support.apple.com/en-us/108770)).
- Automatic iCloud backups need the phone to be on power, on Wi-Fi, and locked ([108366](https://support.apple.com/en-us/108366)). So a restore can miss the workouts logged since the last overnight backup. I estimate that at up to about a day of data, more if the user rarely charges on Wi-Fi.
- Users get 5 GB of iCloud storage free. When it is full, "your device won't be backed up to iCloud" ([108922](https://support.apple.com/en-gb/108922)).
- Someone buying a new iPhone without enough iCloud storage can get temporary storage: 21 days to restore, extendable by another 21 ([104980](https://support.apple.com/en-us/104980)).
- Quick Start offers "Download from iCloud" ("your apps and data download in the background") or a direct transfer from the old device ([102659](https://support.apple.com/en-us/102659), [119967](https://support.apple.com/en-us/119967)). The direct-transfer text does not list app data explicitly, so verify it on two devices.
- Deleting an app "removes the app and its related data". Offloading "keeps its documents and data" ([108429](https://support.apple.com/en-us/108429)).

**Where today's setup loses or splits training data:**

| Scenario | Today (JSON in container, no sync) | With CloudKit sync |
|---|---|---|
| New iPhone via Quick Start or iCloud restore | Survives, minus anything logged since the last backup | Survives, and catches up to the latest sync |
| New iPhone "set up as new" / no backup / iCloud Backup off, for the device or for CaliPark alone | **Lost** | Restored on first launch |
| iCloud storage full (free tier) | **No new backups**, so a stale restore | Sync also fails with `quotaExceeded` ([docs](https://developer.apple.com/documentation/cloudkit/ckerror/code/quotaexceeded)). Local data stays intact. The app must tell the user. |
| App deleted and reinstalled | **Lost** | Restored |
| Two devices in use (e.g. second iPhone, later iPad/Watch) | Diverge permanently | Merged |
| User has no iCloud account, or has turned iCloud off for CaliPark in Settings | Only a computer backup or manual export helps | Same: the engine "stays dormant" with no account "or if the user disabled sync in settings" ([CKSyncEngine](https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5)), and local data remains |

### 3. Options compared

| | CKSyncEngine + own JSON store | SwiftData + CloudKit | Core Data + `NSPersistentCloudKitContainer` | iCloud Drive documents | `NSUbiquitousKeyValueStore` | Community backend + Account |
|---|---|---|---|---|---|---|
| Min OS | iOS 17 ([docs](https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5)) | iOS 17 ([docs](https://developer.apple.com/documentation/swiftdata)) | iOS 13 ([docs](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)) | iOS 5 ([docs](https://developer.apple.com/documentation/foundation/filemanager/url(forubiquitycontaineridentifier:))) | iOS 5 ([docs](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore)) | any |
| Works on iOS 18.4 target | Yes | Yes | Yes | Yes | Yes | Yes |
| Needs paid Developer Program | Yes (CloudKit + push) | Yes | Yes | Yes | Yes, and App Store distribution | Yes for Sign in with Apple ([table](https://developer.apple.com/help/account/reference/supported-capabilities-ios)) |
| Who pays for storage | User's iCloud quota | User's iCloud quota | User's iCloud quota | User's iCloud quota | Neither: 1 MB per app, and values don't count against the user's quota, though key strings do, according to the archived 2015 guide ([design guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html), [KVS chapter](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForKey-ValueDataIniCloud.html)) | **Developer**, per user |
| Needs an Account | No (Apple ID only) | No | No | No | No | **Yes** |
| Conflict resolution | **App-defined, per record** (`serverRecordChanged` is yours to handle) | Last writer wins (inherited from NSPCKC) | Last writer wins ([WWDC19 202](https://developer.apple.com/videos/play/wwdc2019/202/)) | Whole-file versions; app picks a winner ([sample](https://developer.apple.com/documentation/uikit/synchronizing-documents-in-the-icloud-environment)) | Server value wins on recent changes ([design guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForKey-ValueDataIniCloud.html)) | Whatever you build |
| Unique IDs / singletons | Record name = UUID or a fixed name, which the server enforces | No unique constraints with CloudKit, so manual dedup is needed | No unique constraints, so manual dedup is needed | n/a (files) | Keys are unique | Yes |
| Schema evolution | CloudKit schema is additive-only. A JSON payload field keeps the CloudKit schema frozen while `Codable` versions evolve. | Additive-only after production. All attributes need to be optional or have defaults; all relationships optional. | Same as SwiftData | Your file format, your problem | Your format, your problem | Your migrations |
| Offline-first | Yes: local store is the truth and the engine queues sends | Yes | Yes | Partly: on iOS, file content may not be downloaded until requested | Yes, with small values | Only if you build a local cache plus outbox |
| Fit with current code | **High**: keeps structs, protocols, `AppEnvironment` wiring | Low: rewrite 4 stores and models as `@Model` classes, map back to structs for the engines | Low: same, plus NSManagedObject | Medium: same JSON, but whole-file merges | Only for flags | Medium: needs Account, API, server |
| Effort *(estimate)* | 7–12 dev days, plus 3–5 days of prerequisite hardening | 5–8 days, plus open-ended debugging of opaque sync | 6–10 days | 4–6 days, with ongoing conflict bugs | 1–2 days (flags only) | weeks, plus running costs |
| Verdict | **Recommended** | Viable, worse fit | Not recommended (scaffold slated for deletion) | Not for the log; fine as an export target | Only for tiny preferences | Contrast only; contradicts product decision |

#### 3.1 CKSyncEngine (CloudKit private database)

- **What it does:** you bring your own local persistence. The engine "periodically pushes and pulls database and record zone changes on the app's behalf" and creates a database subscription for silent pushes. It retries transient errors itself (`networkFailure`, `requestRateLimited`, `zoneBusy`, `notAuthenticated` and others). It "does not handle errors that require application-specific logic", for example `serverRecordChanged` ([CKSyncEngine](https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5)). Apple positions it as the choice when you are not using `NSPersistentCloudKitContainer`. It powers Freeform, and `NSUbiquitousKeyValueStore` "was rewritten on top of the sync engine" ([WWDC23 10188](https://developer.apple.com/videos/play/wwdc2023/10188/)).
- **Your responsibilities:**
  - Persist the engine's opaque state from `stateUpdate` events.
  - Register pending changes with `state.add(pendingRecordZoneChanges:)`.
  - Build batches in `nextRecordZoneChangeBatch`. There are at most 250 records per request, and `RecordZoneChangeBatch(pendingChanges:recordProvider:)` respects the limit ([CKSyncEngine](https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5), [RecordZoneChangeBatch](https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5/recordzonechangebatch)).
  - Store each record's system fields (`encodeSystemFields(with:)`) so later saves carry the change tag ([CKRecord](https://developer.apple.com/documentation/cloudkit/ckrecord)).
- **Entitlements:** CloudKit plus Remote notifications ([CKSyncEngine](https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5)). Enabling CloudKit in Xcode adds Push Notifications automatically ([Configuring iCloud services](https://developer.apple.com/documentation/xcode/configuring-icloud-services)).
- **Concurrency:** `CKSyncEngineDelegate` is `AnyObject, Sendable`. Events arrive serially, and you must not call `fetchChanges`/`sendChanges` from inside `handleEvent` ([delegate](https://developer.apple.com/documentation/cloudkit/cksyncenginedelegate-1q7g8)). Apple's sample uses an `actor` ([sample](https://github.com/apple/sample-cloudkit-sync-engine)).
- **Accounts:** the engine "only syncs if there's an account signed in" and stays dormant otherwise. On sign-in, sign-out, or account switch it sends `accountChange` and **resets its internal state, including unsaved pending changes** ([AccountChange](https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5/event/accountchange)).
- **Record limits:** non-asset data per record must not exceed 1 MB ([CKRecord](https://developer.apple.com/documentation/cloudkit/ckrecord)). A CaliPark log entry is about 270 bytes of JSON *(measured on a representative entry)*.
- **Encryption:** `encryptedValues` (iOS 15+) encrypts fields on-device. With Advanced Data Protection on, only the owner holds the keys. Encrypted fields cannot be indexed, and existing unencrypted fields cannot be converted later ([encryptedValues](https://developer.apple.com/documentation/cloudkit/ckrecord/encryptedvalues)). If the user resets their iCloud Keychain, encrypted data is "permanently lost". This surfaces as `zoneNotFound` with `CKErrorUserDidResetEncryptedDataKey` in `userInfo`, and the app must delete the zone, recreate it, and re-upload its local copy. A user can also delete the app's zone from Settings, which surfaces as `userDeletedZone`. For that case Apple says to "prompt for the user's confirmation to purge the associated local records" ([Encrypting user data](https://developer.apple.com/documentation/cloudkit/encrypting-user-data)). Both cases favour keeping a full local copy as the source of truth.
- **Reference implementation:** Apple's MIT-licensed sample ([apple/sample-cloudkit-sync-engine](https://github.com/apple/sample-cloudkit-sync-engine), last commit 2023-12-07) is very close to CaliPark's design:
  - A Codable JSON file holds both the data and `stateSerialization`.
  - Each model stores `lastKnownRecordData`.
  - Conflicts are resolved by a user modification date rather than by upload order.
  - Its tests simulate two devices with two engines.

#### 3.2 SwiftData + CloudKit

- SwiftData sync is implemented on top of `NSPersistentCloudKitContainer`. It needs the iCloud and Background Modes (remote notifications) capabilities, and "The iCloud capability requires an active Apple Developer account with admin permissions" ([Syncing model data](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)).
- **Schema constraints:**
  - CloudKit "is unable to enforce the unique property option", and the same page lists "unique constraints" among the features CloudKit doesn't support ([Syncing model data](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)). That covers `@Attribute(.unique)` and, by the same rule, the iOS 18 `#Unique` macro. The [#Unique](https://developer.apple.com/documentation/swiftdata/unique(_:)) page itself doesn't mention CloudKit.
  - All relationships must be optional, and the `.deny` delete rule is not supported ([Syncing model data](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)).
  - Non-optional attributes without default values fail with the error "CloudKit integration requires that all attributes be optional, or have a default value set". That error text is the title of [forum thread 739351](https://developer.apple.com/forums/thread/739351), where an Apple Frameworks Engineer replies with the two fixes, an optional type or a default value. No Apple documentation page states this rule *(the requirement is well attested, but the primary source is a forum thread)*.
- **Schema evolution:** "CloudKit schemas are additive only … unable to delete model types or change existing model attributes after you promote a schema to production" ([same doc](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)).
- **Database scope:** `ModelConfiguration.CloudKitDatabase` offers only `.automatic`, `.private(_:)` and `.none` ([docs](https://developer.apple.com/documentation/swiftdata/modelconfiguration/cloudkitdatabase-swift.struct)).
- **Codebase cost:** `WorkoutLogEntry`, `WorkoutPlan` and the rest would become `@Model` classes, and the pure engines would need to be fed structs mapped back from them. `SkillPlacement` and `SkillProgress` are singletons. Without unique constraints, two devices that each create one before their first sync end up with two rows, and you must write the dedup logic yourself. Conflict policy is last-writer-wins, so a stale offline device can overwrite a newer edit. Apple's own CKSyncEngine sample comments describe that exact failure mode ([DataModel.swift in the sample](https://github.com/apple/sample-cloudkit-sync-engine)).
- **Lock-in:** a container that Core Data/SwiftData has managed cannot later be shared with a hand-written CloudKit schema. "Apps using CloudKit cannot use Core Data with CloudKit with existing CloudKit containers", and Core Data "owns the CloudKit schema" ([Mirroring a Core Data store](https://developer.apple.com/documentation/coredata/mirroring-a-core-data-store-with-cloudkit)). Switching later would mean a new container and a client-side migration.

#### 3.3 Core Data + `NSPersistentCloudKitContainer`

- Mature: iOS 13+, and it mirrors a SQLite store to the private database ([docs](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)).
- Same limitations as SwiftData: no unique constraints, optional relationships with inverses, no Deny rule ([Creating a Core Data model for CloudKit](https://developer.apple.com/documentation/coredata/creating-a-core-data-model-for-cloudkit)).
- Production schema "record types and their fields are immutable and exist for all time". Apple suggests a `version` attribute from the start ([same doc](https://developer.apple.com/documentation/coredata/creating-a-core-data-model-for-cloudkit)).
- Conflicts are "implemented automatically … using a last writer wins merge policy" ([WWDC19 202](https://developer.apple.com/videos/play/wwdc2019/202/)).
- Apple says to expect sync "within about a minute of the change" ([Syncing a Core Data store](https://developer.apple.com/documentation/coredata/syncing-a-core-data-store-with-cloudkit)).
- For CaliPark it means reviving the empty scaffold the audit wants deleted (C-10) and moving every model to `NSManagedObject`. It has no advantage over SwiftData here.

#### 3.4 iCloud Drive (ubiquity container documents)

- On iOS, "iCloud doesn't synchronize the document data until an app asks". Discovery goes through `NSMetadataQuery` and access through `NSFileCoordinator`. Conflicts appear as file versions that the app must resolve. Apple's sample keeps the most recent `modificationDate` and deletes the rest ([sample](https://developer.apple.com/documentation/uikit/synchronizing-documents-in-the-icloud-environment)).
- Storage is limited only by the user's iCloud space ([design guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html)).
- Apple's (archived) guidance says not to mirror documents between the iCloud container and the local container ([same](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html)). That clashes with an offline-first local store.
- For an append-heavy `workout-log.json` written on two devices, whole-file conflicts are routine and the merge logic still has to be per-entry. It is a good **destination for a manual export**, not a sync engine.

#### 3.5 `NSUbiquitousKeyValueStore`

- **Limits:** at most 1024 keys, 1 MB total, 1 MB per value ([docs](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore)).
- **Not for personal data:** Apple's docs say "Don't store personal or sensitive information in the key-value store. The system stores the information on disk in an unencrypted format." ([docs](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore)).
- **Requirements:** App Store distribution and the KVS entitlement ([docs](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore)).
- **Conflicts:** recent server changes win and the app gets `didChangeExternallyNotification`. Apple says to avoid it "for data essential to your app's behavior when offline" ([design guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForKey-ValueDataIniCloud.html)).
- **Too small for the log:** about 270 B × ~1,500 entries/year is roughly 0.4 MB/year of raw payload *(estimate: 5 sessions/week × ~6 exercises)*. The 1 MB cap would be hit within about 2–3 years.
- **Fine for:** `hasCompletedOnboarding`, hint flags, maybe favorites.

#### 3.6 Sync through the Community backend with an Account (contrast)

- **Conflicts with product decisions:** it breaks "training never needs an Account" for the sync feature. Account creation also obliges in-app account deletion (App Review [5.1.1(v)](https://developer.apple.com/app-store/review/guidelines/)). Sign in with Apple needs the paid program ([table](https://developer.apple.com/help/account/reference/supported-capabilities-ios)).
- **Privacy:** training data would be "collected" in Apple's sense: transmitted off-device and accessible to you ([App privacy details](https://developer.apple.com/app-store/app-privacy-details/)). It would be Fitness data linked to identity, with GDPR duties on your side ([GDPR](https://eur-lex.europa.eu/eli/reg/2016/679/oj)). This is not legal advice.
- **Cost scales with users.** Example: Supabase Pro is "from $25/month", including $10/month in compute credits, with 8 GB disk and 100,000 MAU included, then $0.125/GB and $0.00325/MAU. Free projects "are paused after 1 week of inactivity" ([pricing](https://supabase.com/pricing)).
- **Upside:** cross-platform later (Android/web) and server-side visibility. It is the only option where a "Rust layer" would matter. With CloudKit there is no server code of yours to secure or operate.

### 4. Cross-cutting facts

**Cost and quota**

- **Developer:** 0 for private-database storage. "Data in the private database counts toward the user's iCloud storage quota", and the data "isn't visible in the developer portal" ([privateCloudDatabase](https://developer.apple.com/documentation/cloudkit/ckcontainer/privateclouddatabase)). Apple markets private storage as "limitless scale as your user base grows" ([CloudKit](https://developer.apple.com/icloud/cloudkit/)).
- **User:** about 0.4 MB/year of payload, plus record overhead of unknown size *(estimate ≤ 2 KB/record)*, so roughly 0.5–3.5 MB per active user per year *(estimate: 1,500 records × up to ~2.3 KB ≈ 3.4 MB at the top end)*. That is still under 0.1% of the free 5 GB.
- **Double storage:** with sync on, the JSON files are still in the device backup, so the data is stored twice. That is negligible.

**Developer Program**

- iCloud (CloudKit, Documents, KVS), Push Notifications and Sign in with Apple are available only with the paid Apple Developer Program, not with a free Apple Developer account ([supported capabilities, iOS](https://developer.apple.com/help/account/reference/supported-capabilities-ios)).
- The fee is "99 USD … in local currency where available" ([enrollment](https://developer.apple.com/support/enrollment/)).
- Without the membership you cannot create a container, enable the entitlement, or run sync on a device or simulator. You can still write and unit-test the merge and codec logic.
- **Container ownership is permanent.** A container is registered to the developer team that creates it. Apple staff said in 2016 that deleting containers "is currently not supported", and later community posts say the CloudKit Console can only hide them ([forum 45251](https://developer.apple.com/forums/thread/45251)). I found no Apple documentation page on deleting or renaming containers *(unverified beyond the forum)*. Create the container from the owner's own paid team. Today's `DEVELOPMENT_TEAM 2Z64844RK3` / `com.michalbryk.*` setup may not be that team (audit G-24).
- If the owner enrolls as an individual, Apple lists the personal legal name as the seller on the App Store ([enrollment](https://developer.apple.com/support/enrollment/)). That matters for the Community launch, not for sync.

**CloudKit environments and schema**

- Apps in the App Store can access only the production environment. You must deploy the development schema before publishing. Deployed record types and fields cannot be deleted, and later deploys merge additively ([Deploying the schema](https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema)).
- "Apps distributed via TestFlight or the store can't use the development environment" ([Testing your CloudKit app, archive, 2017](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/TestingYourApp/TestingYourApp.html)). This is still current. In August 2026 an Apple DTS engineer wrote, "I don't see any way to change the iCloud environment for TestFlight distribution", adding that the `com.apple.developer.icloud-container-environment` entitlement is no longer respected ([forum 842909](https://developer.apple.com/forums/thread/842909)). **Consequence:** the schema becomes permanent at the first TestFlight build with sync, not at App Store launch.
- **Escape hatch for the winter test round:** the same DTS reply says Xcode's Custom → "Release Testing" (Ad Hoc) distribution lets you pick the iCloud environment, Production by default or Development ([forum 842909](https://developer.apple.com/forums/thread/842909)). Ad Hoc builds install only on registered devices, up to 100 iPhones per membership year ([Devices overview](https://developer.apple.com/help/account/devices/devices-overview)). Friends could test sync against a still-changeable development schema, as long as their UDIDs are registered. Data in the development environment does not carry over to production. With a local source of truth, though, the first production build can simply re-upload each tester's local data. That only works if `SyncMetadataStore` is keyed by environment, so that a development-environment engine state and system fields are never reused against production *(design note, not from an Apple source)*.
- Encrypted fields must be new fields, and you cannot encrypt an existing field later ([encryptedValues](https://developer.apple.com/documentation/cloudkit/ckrecord/encryptedvalues)). Decide encryption up front.

**Users without iCloud, and account states**

- Without an iCloud account the private database errors on every operation ([privateCloudDatabase](https://developer.apple.com/documentation/cloudkit/ckcontainer/privateclouddatabase)), and CKSyncEngine stays dormant ([CKSyncEngine](https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5)). With a local source of truth the app keeps working unchanged.
- On `temporarilyUnavailable`: "Don't delete any cached data and don't enqueue any CloudKit operations" ([CKAccountStatus](https://developer.apple.com/documentation/cloudkit/ckaccountstatus/temporarilyunavailable)).
- On `quotaExceeded` in the private database: "Prompt the user to go to iCloud settings to manage their storage" ([docs](https://developer.apple.com/documentation/cloudkit/ckerror/code/quotaexceeded)).
- These users still have device backup, and should get a manual export/import (audit C-17).

**App Review and privacy**

- **Guideline 4.10:** "You may not monetize built-in capabilities provided by the hardware or operating system … or Apple services and technologies, such as Apple Music access, iCloud storage, or Screen Time APIs" ([guidelines, last updated 2026-10-16](https://developer.apple.com/app-store/review/guidelines/)). The rule is about charging for iCloud storage itself. It does not clearly forbid a paid tier that includes iCloud *sync*, and approved apps do exactly that: Bear Pro sells "iCloud sync for all your notes … across all devices" ([Bear FAQ](https://bear.app/faq/features-and-price-of-bear-pro/)). So 4.10 is a review risk, not a hard ban *(my reading)*. **Keep iCloud sync free anyway.** The product decision says training is always free, and sync is what protects that data. Don't put it behind the planned contributor paywall.
- **Guideline 5.1.3(ii):** apps "may not store personal health information in iCloud" ([guidelines](https://developer.apple.com/app-store/review/guidelines/)). The 5.1.3 preamble, however, says "Health, fitness, and medical data are especially sensitive", so fitness data is in the section's scope, even though (ii) names only "personal health information". Apple's privacy labels list "Fitness" ("Fitness and exercise data") separately from "Health" ("Health and medical data … or any other user provided health or medical data") ([App privacy details](https://developer.apple.com/app-store/app-privacy-details/)). My reading is that sets and reps are fitness data and do not fall under 5.1.3(ii). I could not verify that against any App Review statement *(unverified)*. If CaliPark ever stores body weight, injuries, or HealthKit-derived values, keep those out of CloudKit or get clarity from App Review first.
- **Privacy label:** "Collect" means transmitting data off the device "in a way that allows you and/or your third-party partners to access it" ([App privacy details](https://developer.apple.com/app-store/app-privacy-details/)). Private-database data is not visible to the developer, so training data synced this way should not count as collected by you. That is my interpretation, so confirm it when filling in the label.

**Exit path**

- Apple's EU Data Act terms for CloudKit apply only to developers "enrolled in the Apple Developer Program as an organization based in the European Union", so an individual enrollment wouldn't qualify. Under them, the data a developer can port excludes "end-user data stored in private or shared databases" ([EU Data Act Terms – CloudKit](https://developer.apple.com/download/files/EU-Data-Act-Terms-CloudKit.pdf)).
- Any future move of training data to your own backend would therefore have to go **through the app**. A local JSON source of truth makes that easy.

**Testing support**

- Setting `automaticallySync = false` lets tests drive `fetchChanges()`/`sendChanges()` "to deterministically simulate certain conditions in your unit tests" ([automaticallySync](https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5/configuration/automaticallysync)).
- Apple recommends simulating "device-to-device user flows using multiple CKSyncEngine instances" ([WWDC23 10188](https://developer.apple.com/videos/play/wwdc2023/10188/)).
- Apple's 2023 sample README says simulators cannot register for remote pushes. The Xcode 14 release notes say the iOS 16+ Simulator supports remote notifications on Apple silicon or T2 Macs running macOS 13+ ([Xcode 14 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-14-release-notes)). Treat push-driven fetch in the simulator as "probably works" and verify it.
- Core Data's CloudKit doc says you can test with the simulator and with multiple devices on the same account ([Mirroring](https://developer.apple.com/documentation/coredata/mirroring-a-core-data-store-with-cloudkit)).

**File protection**

- The default protection class is "complete until first user authentication", which keeps files readable in the background after the first unlock ([Encrypting your app's files](https://developer.apple.com/documentation/uikit/encrypting-your-app-s-files)).
- CKSyncEngine applies pushes in the background, so **do not** raise the training files to `.complete` protection when doing audit C-15.

## Recommendation

**Adopt CKSyncEngine on the CloudKit private database, with the existing JSON stores staying the local source of truth.** It is the only option that keeps CaliPark's value-type domain and protocol stores, lets you merge per type, and enforces singleton uniqueness through fixed record names. It also costs you nothing per user and needs no Account. Ship it in 1.0, behind the prerequisites below.

### Record design (decide once: it becomes permanent at the first TestFlight build)

- **Zone:** one custom zone in the private database, e.g. `Training`.
- **Fields:** every record type has the same three fields, all written through `encryptedValues`:
  - `schemaVersion`: Int64
  - `payload`: Bytes, the existing `Codable` JSON of the struct, using the stores' ISO 8601 encoder
  - `modifiedAt`: Date, the user modification time

  Keeping the CloudKit schema at three fields that never change pushes all evolution into the `Codable` envelope you need anyway for audit C-4. This is my design choice, not an Apple pattern. Apple's sample uses one encrypted field per property.

| Record type | `recordName` | Merge policy (pure function, unit-tested) |
|---|---|---|
| `WorkoutLogEntry` | `entry.id.uuidString` | Union by id. Entries are append/delete only today, so the same id on both sides means the same content. Delete wins. |
| `WorkoutPlan` | `plan.id.uuidString` | Last-writer-wins per plan by `modifiedAt`, a new field on `WorkoutPlan`, like the sample's `userModificationDate`. Delete wins. Afterwards, reschedule local reminders for changed plans (ties into the audit's `WorkoutPlanService`, B-6/F-5). |
| `SkillPlacement` | fixed `"placement"` | Last-writer-wins by the existing `declaredAt`. |
| `SkillProgress` | fixed `"progress"` | Merge: union `celebratedRungs`, max `celebratedLevel`. This is commutative and idempotent, so a second device never re-celebrates. |

- **Tie-break:** dates are stored as whole seconds (CLAUDE.md), so last-writer-wins needs a deterministic tie-break, e.g. prefer the server record.
- **Newer versions:** if `schemaVersion` is higher than the app understands, keep the raw record. Don't decode it, edit it, or re-upload it, and show "update the app". This is adapted from Apple's "version attribute" strategy, in which older app versions simply don't fetch newer records ([Creating a Core Data model for CloudKit](https://developer.apple.com/documentation/coredata/creating-a-core-data-model-for-cloudkit)). It prevents an older iPhone from downgrading data written by a newer one.

### Components (fits the CLAUDE.md conventions)

- **`TrainingSyncMerge` and `TrainingRecordCodec`:** caseless enums of static pure functions. They handle struct ⇄ `(recordType, recordName, schemaVersion, payload, modifiedAt)` and the merge policies above. They have no CloudKit dependency apart from a thin `CKRecord` adapter.
- **`SyncMetadataStore`:** a JSON file in Application Support with `CKSyncEngine.State.Serialization` (it is `Codable`, as the sample shows) and `[recordName: systemFieldsData]`. Leave it **in** the device backup. Then a restored phone's records with system fields are known to have been on the server, so deletions made elsewhere are applied rather than resurrected. *(Unverified: Apple documents nothing about restoring a sync engine state from a device backup. If an old change token is rejected and the engine refetches everything, deletions are not reported as deletions. Records that have system fields but don't come back from a full fetch then have to be treated as deleted. Cover this in the two-device fake-server tests and the device matrix.)* Key the store by container environment (see §4).
- **`TrainingSyncCoordinator`:** the `CKSyncEngineDelegate`. It owns the engine, applies fetched changes to the stores through "apply remote" methods that don't re-enqueue, and answers `nextRecordZoneChangeBatch` from the stores. Make it `@MainActor final class` to match the synchronous main-actor stores, or an `actor` as in Apple's sample. Either way, never call `fetchChanges`/`sendChanges` inside `handleEvent`.
- **Store decorators:** `SyncingWorkoutLogStore(base: FileWorkoutLogStore, sink:)` and its siblings forward each mutation and register `.saveRecord`/`.deleteRecord` pending changes. They are wired **only** in `AppEnvironment`. Tests keep the `InMemory…` stores untouched.
- **Account events:**
  - `signIn`: enqueue all local records, as in Apple's sample.
  - `signOut`: **keep** local data, because training works without iCloud, and clear the sync metadata. This deliberately differs from the sample, which deletes local data.
  - `switchAccounts`: ask the user (see open questions).
- **First launch on a new phone:** if the account is available and there is no saved engine state, call `fetchChanges()` before deciding on onboarding or calibration. Show "Przywracanie treningów z iCloud…" with a skip button. Suppress `RewardEvaluator` celebrations until the initial fetch finishes, so restored logs don't fire "+100 XP" before the `progress` record arrives. Skip onboarding if a synced `placement` exists, because `hasCompletedOnboarding` lives in UserDefaults and is not synced.
- **Status row in Profile:** "Synchronizacja iCloud: aktywna / brak konta iCloud / brak miejsca w iCloud". Optionally add a "Usuń dane z iCloud" action that deletes the zone.
- **Zone deleted by the user (`userDeletedZone`):** Apple says to ask the user to confirm before purging local records ([Encrypting user data](https://developer.apple.com/documentation/cloudkit/encrypting-user-data)). Default to keeping local data and pausing sync until the user chooses. **Keychain reset** (`zoneNotFound` + `CKErrorUserDidResetEncryptedDataKey`): recreate the zone and re-upload, with no prompt needed.

### Migration outline

**Phase 0: before TestFlight #1. No paid membership needed. Est. 3–5 days.**

1. Replace the four load/save copies with one `JSONFileStore<Value>`, as the audit proposes. It writes a versioned envelope `{ "schemaVersion": 1, "data": … }`, throws instead of returning empty, quarantines an undecodable file (`*.corrupt-<date>.json`), and logs (audit #1, C-1, C-4, G-10).
2. One-time, idempotent move from `Documents/` to `Library/Application Support/<bundle-id>/` (audit C-15):
   - Read the legacy bare-array file.
   - Write the new envelope atomically.
   - Re-read and verify it.
   - Only then delete the legacy file, or rename it to `*.migrated`.

   Test this with fixtures in the *real* on-disk format (audit G-13), using whole-second dates.
3. Stabilize identities that will cross devices:
   - Use stable rung IDs instead of indices in `SkillPlacement`/`RungReference` (A-6).
   - Encode `ProgressionPathID` dictionary keys as strings (C-4).
   - Add `modifiedAt` to `WorkoutPlan`.
4. Add export/import (C-17): `fileExporter`/`ShareLink` of a versioned bundle, plus an import that merges by id through the **same** `TrainingSyncMerge` functions. This is the fallback for users without iCloud, and a free test bed for the merge code.
5. Delete the Core Data scaffold (C-10). Add one change signal, e.g. the audit's `TrainingJournal` revision, so that data arriving from sync refreshes Home, History and Skills without a tab switch.

**Phase 1: after buying the Developer Program, before the first TestFlight build with sync. Est. 7–12 days.**

1. Settle the final bundle ID and the owning developer team (G-24). Create the container `iCloud.<bundle-id>` from that team. Add iCloud (CloudKit) and Background Modes → Remote notifications.
2. Implement the codec, merge, metadata store, coordinator and decorators described above. Wire them in `AppEnvironment`.
3. Existing data: on the first sync-enabled launch the engine state is `nil`, so it fetches everything (empty for a new user). Every local record lacks system fields and is enqueued as a save. Uploads go in batches of ≤ 250. Record names are UUIDs or fixed names, so re-running is idempotent, and a record already on the server comes back as `serverRecordChanged` and goes through merge. A tester with separate data on two devices ends up with a union of logs and plans, last-writer-wins placement, and unioned progress.
4. Test against the development environment on two devices. Optionally run a friends round as Ad Hoc "Release Testing" builds on the Development environment, with registered UDIDs, while the schema can still change (§4). Then **deploy the schema to production** and only then upload to TestFlight.

**Phase 2: polish, before App Store. Est. 2–3 days.**

- Quota and "delete iCloud data" UI.
- Optionally sync favorites and onboarding flags (KVS, or the same zone).
- Keep a remote-free kill switch: sync off just means the coordinator isn't started. Local JSON is untouched, so turning sync off never loses data.

### Testing strategy

1. **Default suite** (`-only-testing:cali-parkTests`, Swift Testing, deterministic, no CloudKit):
   - Codec round trips. Use whole-second dates and a gregorian UTC calendar per CLAUDE.md.
   - Merge laws: commutative, idempotent, delete-wins, tie-break.
   - Envelope and legacy-file migration from fixtures.
   - Decorators enqueue the right pending changes (fake sink).
   - Initial-sync gating, and no celebrations before the first fetch.
   - Account-change policy.
2. **Two-device simulation with a fake transport:** an `InMemorySyncServer` that hands out change tokens, returns `serverRecordChanged` on stale change tags, and records deletions. Two coordinator instances exercise:
   - offline edits on both devices
   - delete vs. stale edit
   - restore from an old backup (no resurrection)
   - account switch
   - a newer `schemaVersion` arriving at an older client
3. **Real CloudKit integration, opt-in test plan:** two `CKSyncEngine` instances with `automaticallySync = false` in one process, following Apple's sample and WWDC23. Use a dedicated test zone in the development environment. Gate the tests with Swift Testing's `.enabled(if:)` on the account status, and keep them out of the CLAUDE.md default command, which must stay green offline.
4. **Manual device matrix before every TestFlight build:**
   - two devices on one Apple ID
   - airplane-mode edits on both
   - fresh install with existing iCloud data
   - Quick Start transfer, which also verifies the direct-transfer behavior noted in §2
   - iCloud sign-out and sign-in
   - Settings → delete the app's iCloud data (`userDeletedZone`)
   - one TestFlight build against the **production** schema

### What not to do

- Don't use NSUbiquitousKeyValueStore or iCloud Drive for the log.
- Don't revive Core Data for this.
- Don't mark training files `isExcludedFromBackup`, and don't give them `.complete` file protection.
- Don't paywall sync. The main reason is the "training is always free" decision. Guideline 4.10 is only a possible review risk (see §4).
- Don't create the CloudKit container under a bundle ID you may still rename, or under a developer team that isn't the owner's. Containers can't be deleted.

## Open questions for the owner

1. **Timing:** sync in 1.0, as recommended, or Phase 0 only for the first TestFlight round with sync in a later round? Phase 0 is the part that protects testers' data either way.
2. **Buy the Developer Program now** rather than just before TestFlight? CloudKit work and device testing cannot start without it, and TestFlight forces the production schema.
3. **Final bundle ID, developer team and container ID:** `com.michalbryk.cali-park` looks like a placeholder, and team `2Z64844RK3` may not be yours. The container identifier, the team that owns it, and the production schema are effectively permanent, because containers can't be deleted.
4. **Account switch and sign-out:** when the iPhone's Apple ID changes, should CaliPark keep the local training data (and upload it into the new account) or ask? The recommendation is to keep data on sign-out and ask on switch.
5. **In-app sync toggle**, or rely on iOS Settings → iCloud → apps? A toggle adds UI but helps testers and support.
6. **Do favorites and onboarding/hint flags need to follow the user?** Favorites reference Community park IDs, so this may belong with the Community design instead.
7. **Future health-type data:** will CaliPark ever store body weight, injuries, or HealthKit data? If so, it needs a separate decision under guideline 5.1.3(ii).
8. **Future Account-based backup:** do Account holders later get a server copy of training data, for example for Android? If yes, treat the export bundle format from Phase 0 as a stable, versioned contract.
9. **TestFlight vs Ad Hoc for the winter round:** TestFlight forces the production schema. Ad Hoc "Release Testing" builds can stay on the Development environment, at the cost of collecting friends' UDIDs (100 iPhones per year). Which one do you want for the first sync-enabled round?

## Sources

Apple developer documentation (all read 2026-11-03):

- CKSyncEngine: https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5
- CKSyncEngine.Configuration.automaticallySync: https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5/configuration/automaticallysync
- CKSyncEngine.Configuration.stateSerialization: https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5/configuration/stateserialization
- CKSyncEngine.Event.AccountChange: https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5/event/accountchange
- CKSyncEngine.RecordZoneChangeBatch: https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5/recordzonechangebatch
- CKSyncEngineDelegate: https://developer.apple.com/documentation/cloudkit/cksyncenginedelegate-1q7g8
- CKContainer.privateCloudDatabase: https://developer.apple.com/documentation/cloudkit/ckcontainer/privateclouddatabase
- CKRecord: https://developer.apple.com/documentation/cloudkit/ckrecord
- CKRecord.encryptedValues: https://developer.apple.com/documentation/cloudkit/ckrecord/encryptedvalues
- Encrypting user data (CloudKit): https://developer.apple.com/documentation/cloudkit/encrypting-user-data
- CKAccountStatus.temporarilyUnavailable: https://developer.apple.com/documentation/cloudkit/ckaccountstatus/temporarilyunavailable
- CKError.Code.quotaExceeded: https://developer.apple.com/documentation/cloudkit/ckerror/code/quotaexceeded
- CKError.Code.userDeletedZone: https://developer.apple.com/documentation/cloudkit/ckerror/code/userdeletedzone
- Deploying an iCloud container's schema: https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema
- Testing your CloudKit app (archive): https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/TestingYourApp/TestingYourApp.html
- Configuring iCloud services: https://developer.apple.com/documentation/xcode/configuring-icloud-services
- Syncing model data across a person's devices (SwiftData): https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
- SwiftData framework: https://developer.apple.com/documentation/swiftdata
- ModelConfiguration.CloudKitDatabase: https://developer.apple.com/documentation/swiftdata/modelconfiguration/cloudkitdatabase-swift.struct
- `#Unique` macro: https://developer.apple.com/documentation/swiftdata/unique(_:)
- NSPersistentCloudKitContainer: https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer
- Creating a Core Data model for CloudKit: https://developer.apple.com/documentation/coredata/creating-a-core-data-model-for-cloudkit
- Mirroring a Core Data store with CloudKit: https://developer.apple.com/documentation/coredata/mirroring-a-core-data-store-with-cloudkit
- Syncing a Core Data store with CloudKit: https://developer.apple.com/documentation/coredata/syncing-a-core-data-store-with-cloudkit
- Synchronizing documents in the iCloud environment: https://developer.apple.com/documentation/uikit/synchronizing-documents-in-the-icloud-environment
- NSUbiquitousKeyValueStore: https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore
- iCloud Design Guide, iCloud fundamentals (archive): https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html
- iCloud Design Guide, Designing for key-value data (archive): https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForKey-ValueDataIniCloud.html
- Optimizing your app's data for iCloud Backup: https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup
- File System Programming Guide, File System Basics (archive): https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html
- Encrypting your app's files: https://developer.apple.com/documentation/uikit/encrypting-your-app-s-files
- Xcode 14 release notes (Simulator remote notifications): https://developer.apple.com/documentation/xcode-release-notes/xcode-14-release-notes

Apple videos and sample code:

- WWDC23 "Sync to iCloud with CKSyncEngine" (10188): https://developer.apple.com/videos/play/wwdc2023/10188/
- WWDC19 "Using Core Data with CloudKit" (202): https://developer.apple.com/videos/play/wwdc2019/202/
- apple/sample-cloudkit-sync-engine (MIT, commit 63d9d16, 2023-12-07): https://github.com/apple/sample-cloudkit-sync-engine
- Apple Developer Forums thread 739351 (error text in the thread title; Frameworks Engineer reply with the optional/default fix, Oct 2023): https://developer.apple.com/forums/thread/739351
- Apple Developer Forums thread 842909 (DTS: TestFlight is forced to Production; Ad Hoc "Release Testing" can pick Development, Aug 2026): https://developer.apple.com/forums/thread/842909
- Apple Developer Forums thread 45251 (Apple staff: deleting CloudKit containers "is currently not supported", Jun 2016): https://developer.apple.com/forums/thread/45251

Apple program, policy and marketing pages:

- Supported capabilities (iOS), membership matrix: https://developer.apple.com/help/account/reference/supported-capabilities-ios
- Apple Developer Program enrollment (fee): https://developer.apple.com/support/enrollment/
- Devices overview (100 registered devices per product family per membership year): https://developer.apple.com/help/account/devices/devices-overview
- App Review Guidelines (4.10, 5.1.1(v), 5.1.3(ii); last updated 2026-10-16): https://developer.apple.com/app-store/review/guidelines/
- App privacy details on the App Store: https://developer.apple.com/app-store/app-privacy-details/
- CloudKit overview: https://developer.apple.com/icloud/cloudkit/
- EU Data Act Terms – CloudKit (PDF, created 2025-09-12): https://developer.apple.com/download/files/EU-Data-Act-Terms-CloudKit.pdf

Apple Support (user-facing behavior):

- What does iCloud back up? (published 2025-05-01): https://support.apple.com/en-us/108770
- How to back up your iPhone or iPad with iCloud (published 2026-09-24): https://support.apple.com/en-us/108366
- Manage your iCloud storage (published 2026-09-16): https://support.apple.com/en-gb/108922
- Get temporary iCloud storage when you buy a new iPhone or iPad (published 2026-09-23): https://support.apple.com/en-us/104980
- Transfer data from your previous iOS or iPadOS device (published 2025-12-05): https://support.apple.com/en-us/119967
- Use Quick Start to transfer data (published 2026-09-14): https://support.apple.com/en-us/102659
- How to check the storage on your iPhone and iPad (offload vs delete; published 2026-10-13): https://support.apple.com/en-us/108429

Third party and legal:

- Supabase pricing: https://supabase.com/pricing
- Bear Pro features (paid "iCloud sync"), as evidence on guideline 4.10: https://bear.app/faq/features-and-price-of-bear-pro/
- GDPR, Regulation (EU) 2016/679: https://eur-lex.europa.eu/eli/reg/2016/679/oj

Codebase (read 2026-11-03): `cali-park/Features/Exercises/Services/WorkoutLogStore.swift`, `cali-park/Features/Planner/Services/WorkoutPlanStore.swift`, `cali-park/Features/Skills/Services/SkillPlacementStore.swift`, `cali-park/Features/Skills/Services/SkillProgressStore.swift`, `cali-park/Core/Services/FavoritesStore.swift`, `cali-park/Core/Services/Persistence.swift`, `cali-park/Core/AppEnvironment.swift`, the models under `Features/*/Models/`, and `docs/audit/README.md` / `docs/audit/findings.md` (C-1, C-4, C-10, C-15, C-17, A-6, B-6, F-5, G-13, G-24).

## Fact-check (2026-11-03)

A second pass re-read every cited primary source on 2026-11-03. Apple documentation was read through its JSON endpoints. The repo's build settings and store code were checked as well.

**Confirmed as written:**

- **iOS availability:** CKSyncEngine iOS 17.0, SwiftData 17.0, `NSPersistentCloudKitContainer` 13.0, `url(forUbiquityContainerIdentifier:)` and `NSUbiquitousKeyValueStore` 5.0, `encryptedValues` 15.0, `#Unique` 18.0.
- **CKSyncEngine:** the 250-records-per-request batch limit, the list of auto-retried errors, the `serverRecordChanged` responsibility, the reset of pending changes on account change, the serial-delegate rule, and the `automaticallySync` test wording. `State.Serialization` is Codable.
- **CloudKit records:** the 1 MB per-record limit, private-database data counting toward the user's quota, encrypted fields being unindexable and new-only, and the `quotaExceeded` and `temporarilyUnavailable` guidance.
- **Schema:** schema deployment is additive-only. SwiftData's relationship and unique-constraint limits hold, as do the Core Data CloudKit model limits, "within about a minute", and the WWDC19 last-writer-wins quote. WWDC23 confirms Freeform, the KVS rewrite, and the multiple-engine testing advice.
- **KVS:** 1024 keys, 1 MB total, 1 MB per value, the "unencrypted" warning, and the App Store distribution requirement.
- **Capabilities table:** CloudKit, iCloud documents, KVS and Push are available with ADP and ADEP but not the free tier. Sign in with Apple is ADP only. Background modes are available on all tiers. The fee is 99 USD.
- **Apple Support pages:** 5 GB free, a full account stops backups, the backup conditions (power, Wi-Fi, locked), 21+21 days of temporary storage, delete vs offload, Quick Start wording, and all publish dates.
- **Other sources:** the File System Programming Guide's backup rules, the default file protection class, the Xcode 14 Simulator push note, and the sample repo (MIT, commit 63d9d16, 2023-12-07, the actor, deleting local data on signOut and switchAccounts, `userModificationDate`). The EU Data Act terms match the quote and apply to organizations only. Supabase Pro and Free figures match the pricing page today.
- **Codebase:** the `Documents/` file names, whole-file load and save, `[ProgressionPathID: Int]` with a String-enum key (so an unkeyed array), index-based `RungReference`, no `.entitlements` file, team `2Z64844RK3`, bundle `com.michalbryk.cali-park`, and the audit IDs cited.

**Corrected:**

- **Guideline 4.10:** it was presented as forbidding a paid iCloud sync. The guideline bans monetizing "iCloud storage", and Bear Pro sells "iCloud sync" on the App Store, so this is now framed as a review risk. The advice to keep sync free stands, on product grounds.
- **Guideline 5.1.3:** added that the 5.1.3 preamble names "fitness" data as especially sensitive. The "sets and reps are not health info" reading is marked unverified.
- **Forum 739351:** the error text was attributed to an Apple Frameworks Engineer. It is the thread title, and the engineer only replied with the fix.
- **`#Unique`:** the CloudKit claim was cited to the `#Unique` page, which doesn't mention CloudKit. It is now cited to the SwiftData sync article.
- **SwiftData quote:** completed with "…with admin permissions".
- **KVS quota claim:** marked as coming from the archived 2015 guide. Key strings do count against the user's quota.
- **Storage estimate:** the upper bound was raised from 3 to 3.5 MB/user/year, because 1,500 × ~2.3 KB ≈ 3.4 MB.
- **Version-attribute strategy:** relabeled as *adapted from* Apple's. Apple's version hides newer records rather than keeping raw ones.
- **Keychain reset:** added the actual error, `zoneNotFound` + `CKErrorUserDidResetEncryptedDataKey`, and Apple's guidance to ask before purging local data on `userDeletedZone`.

**Added (missing for the decision):**

- **Per-app backup:** users can switch off iCloud Backup for one app, which is one more way to lose data today.
- **Per-app iCloud toggle:** with iCloud off for CaliPark in Settings, CKSyncEngine stays dormant.
- **TestFlight environment:** current confirmation that TestFlight is forced to Production (DTS, Aug 2026). Added the Ad Hoc "Release Testing" escape hatch on the Development environment (100 devices per year) as a new phase step and open question 9.
- **Container ownership:** containers belong to the team that creates them and can't be deleted (forum only). The project's team and bundle ID may not be the owner's (G-24), so the right team is now a precondition for creating the container.
- **Sync metadata:** `SyncMetadataStore` must be keyed by environment. Restoring engine state from a device backup is an untested assumption.
- **Device family:** `TARGETED_DEVICE_FAMILY = "1,2"` (iPad included) vs the iPhone-only decision.

**Could not verify:**

- Whether Quick Start's direct device-to-device transfer always includes app data. Apple's page doesn't say, so test it on two devices.
- An Apple documentation page, rather than a forum post, saying containers can't be deleted or renamed.
- Whether App Review treats workout logs as "personal health information" under 5.1.3(ii).
- How CKSyncEngine behaves when its state comes from an old backup and the server rejects the change token.
- The size of a log entry, given as "≈270 B, measured". I did not re-measure it, though the fields make it plausible.
- The size of CloudKit's per-record overhead.
- All effort figures, which are the researcher's estimates.

**Bottom line:** the recommendation stands. Harden the JSON stores now (Phase 0, no membership needed), then add CKSyncEngine on the private database with the JSON files kept as the source of truth. Fix the team and bundle ID before the container exists, and decide whether the first sync-enabled test round goes out on TestFlight (schema frozen) or Ad Hoc (schema still flexible).
