# Google Play Data Safety draft

Updated from repository: 18 October 2026 (not a production or Play Console verification)

This file is a release-preparation worksheet for UniSpace. It is not a substitute for the final answers in Play Console. Re-check it against the exact release build and the current Google Play wording before submission.

## Current release scope

Android package: `dz.fachub.fachub`

Current app services include:

- Firebase Authentication
- Cloud Firestore
- Cloud Storage for Firebase
- Cloud Functions for Firebase
- Firebase Cloud Messaging
- Google Sign-In
- image_picker for system-selected photos/videos
- photo_manager for the inline chat gallery, including Android limited access
- geolocator for user-requested chat location sharing
- Android contact picker for a single user-selected contact
- external Google translation requests for text the user chooses to translate
- file_picker for user-selected files
- microphone recording for voice messages

The current Android manifest requests foreground coarse/fine location, `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED`, and legacy `READ_EXTERNAL_STORAGE` limited to API 32. The inline chat gallery uses `photo_manager`; other selection flows also use `image_picker`. It does not request background location, broad contacts access, external storage write access, or all-files access. Reading thumbnails locally is distinct from collecting media: selected content leaves the device when the user sends/uploads it. These permissions require a Play review of the actual use case; this worksheet does not establish eligibility.

## Play Console high-level answers

### Does the app collect or share required user data?

**Collection: Yes.**

UniSpace stores account/profile information, social/community content, chat content and attachments, notification/session identifiers, and other user-provided data needed for app functionality.

### Is all collected user data encrypted in transit?

Firebase documents HTTPS encryption in transit for the Firebase SDK data it handles.

Before selecting **Yes** in Play Console, verify every non-Firebase network path in the release build as well. In particular, review any translation/network helper that can send user text to an external service.

### Can users request deletion of their data?

**Yes.**

In-app path:
`Settings -> Privacy -> Delete account and data`

External deletion resource:
`https://fachub-c631c.web.app/delete-account`

Privacy policy:
`https://fachub-c631c.web.app/privacy-policy`

Terms:
`https://fachub-c631c.web.app/terms-of-use`

The repository contains the account-deletion client flow, deletion Cloud Functions, hosting page, tests, and verification workflows. The three published URLs above were checked on 18 September 2026 and returned HTTP 200 with the expected public content. Re-check them immediately before final Play submission.

## Data-type mapping draft

The rows below describe the current code/privacy-policy model. “Collected” means the data may leave the device and be stored or processed to provide the feature.

| Google Play data type | Current UniSpace use | Collected? | Typical purpose(s) | Notes before submission |
| --- | --- | --- | --- | --- |
| Name | Profile/account | Yes | App functionality, account management | May be user-provided/optional depending on flow. |
| Email address | Authentication/account/support | Yes | Account management, security, app functionality | Google Sign-In/Firebase Auth are used. |
| User IDs | Firebase UID, username/account identifiers | Yes | Account management, app functionality, security | Firebase Auth UID accompanies authenticated Firebase requests. |
| Other personal info | Profile fields such as date of birth, gender, university/department/specialty/level when provided | Yes | App functionality, account management | Verify which fields are optional in the release build. |
| User messages | Private/direct chat text and message metadata | Yes | App functionality | Includes content, delivery/read state, and optional text sent to an external Google translation service. |
| Photos | Profile/community/chat images selected by the user | Yes | App functionality | Inline gallery reads permitted media locally; selected uploaded photos and chat wallpapers are collected. |
| Videos | Chat/community video selected by the user | Yes | App functionality | Same distinction as photos. |
| Audio files | Voice messages/recordings submitted by the user | Yes | App functionality | Microphone permission is declared for recording. |
| Files and docs | User-selected chat/file attachments | Yes | App functionality | Only user-selected files should be included. |
| App interactions | Reactions, follows, saves, blocks and similar social actions | Yes | App functionality, account management/safety | Confirm final feature set. |
| Other user-generated content | Posts, comments, profile/community content | Yes | App functionality | Content is stored in Firebase services when posted. |
| Device or other IDs | FCM token / Firebase installation identifier and security/session identifiers | Yes | Notifications, security, app functionality | Firebase documents automatic Firebase Installation ID collection for relevant SDKs. |
| Diagnostics | No dedicated Crashlytics dependency found in the current pubspec | Not confirmed as app-defined collection | — | Do not mark “No” solely from this row; check every SDK in the final dependency graph. |
| Approximate/precise location | User confirms a chat location attachment obtained from foreground geolocation or entered coordinates | Yes, when sent | App functionality | Coarse/fine permissions are declared; no background location. Check precision of the final payload and map provider in release testing. |
| Contacts | User selects a contact through the Android picker or enters contact details and sends a contact card | Yes, when sent | App functionality | Name/phone are shared as chat content. No READ_CONTACTS permission or address-book upload. |
| Financial info | No current feature confirmed | No | — | Revisit if payments/monetization are added. |
| Health and fitness | No current feature confirmed | No | — | — |
| Calendar | User-created event attachments; optional system intent to add an event to a calendar | User-entered event content when sent | App functionality | No broad calendar read permission; the app does not import the device calendar. |
| Web browsing history | No current feature confirmed | No | — | — |

## Data sharing draft

Do not automatically mark Firebase hosting/storage/auth processing as “shared” solely because Google/Firebase processes it. Google Play provides a service-provider exception when a provider processes data on behalf of the developer.

Likewise, a user-initiated transfer that the user reasonably expects can fall under Play’s user-initiated sharing exception.

Before selecting the final “shared” answers, verify:

1. every third-party SDK in the exact release dependency graph;
2. whether any SDK uses collected data for its own independent purposes;
3. whether any external translation/API feature sends user content outside Firebase;
4. whether any advertising, analytics, attribution, or profiling SDK is added later.

No Firebase Analytics or Firebase Crashlytics direct dependency is present in the current `pubspec.yaml`, but the final release dependency graph must still be checked.

## Firebase-specific disclosure notes

Firebase’s current Android disclosure guidance states, among other things:

- Firebase Authentication automatically processes Firebase user-agent information and IP addresses for authentication/security.
- Cloud Functions client requests can include function name, caller IP address, FCM token, and authenticated Firebase user ID.
- Firebase Cloud Messaging uses app version information and depends on Firebase Installations.
- Firebase Installations generates/collects a per-installation Firebase Installation ID.
- Firebase documents encryption in transit for the end-user data described in its disclosure guidance.

These SDK-level facts must be combined with UniSpace’s own developer-defined data stored in Firestore/Storage.

## Important release checks

Before submitting the Data Safety form:

- [ ] Run `flutter pub get` using the exact release branch.
- [ ] Export/review the final dependency graph and check every third-party SDK.
- [ ] Confirm no Firebase Analytics or Crashlytics SDK was added indirectly by a new feature/configuration.
- [ ] Review the `translator` package usage and its external network behavior if message/content translation remains enabled.
- [ ] Confirm the privacy policy describes all data categories actually present in the release.
- [x] Confirm the external account-deletion URL is publicly reachable without login — verified 18 September 2026 (HTTP 200).
- [x] Confirm the privacy-policy URL is publicly reachable without login and is non-editable by visitors — verified 18 September 2026 (HTTP 200).
- [ ] Confirm account deletion can be initiated from inside the app.
- [ ] Confirm the Data Safety answers remain consistent with the privacy policy.
- [ ] Update this file whenever a new SDK, permission, account field, payment feature, analytics SDK, ads SDK, location feature, or contacts feature is added.

## Current open items

1. Upload keystore creation and signed AAB generation were intentionally deferred.
2. Photo/video broad read permissions remain for the requested inline gallery. Complete Play photo/video permission declarations and demonstrate that a system picker is insufficient for the core functionality; eligibility/approval is not yet verified. CI only checks the repository permission contract.
3. Hosted deletion/privacy/terms URLs were verified reachable on 18 September 2026; re-check immediately before the final Play submission.
4. Final “shared” selections require verification of all non-Firebase SDK network behavior.

## Translation disclosure and release gate

`lib/services/chat_translation.dart` sends selected message text, source/target language parameters and the network request (including IP address) to Google translation endpoints over HTTPS. The text is processed outside the Firebase chat backend. This is not on-device translation or end-to-end encrypted processing. Review the provider terms, retention and Play sharing classification before submission; do not assume the Firebase service-provider exception covers this path. Ensure both manual and automatic translation are explained before activation and can be disabled. Verify the shipped consent flow and hosted policy against the final build.

Photo/video policy: https://support.google.com/googleplay/android-developer/answer/14115180
