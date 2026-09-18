# Google Play Data Safety draft

Updated: 18 September 2026

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
- image_picker for user-selected photos/videos
- file_picker for user-selected files
- microphone recording for voice messages

The current Android manifest does not request location or contacts permissions. Broad Android 13+ photo/video permissions (`READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO`) have been removed and chat media selection uses the system-backed picker through `image_picker`.

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

The repository contains the account-deletion client flow, deletion Cloud Functions, hosting page, tests, and verification workflows. Confirm the production URLs are reachable from a normal browser immediately before Play submission.

## Data-type mapping draft

The rows below describe the current code/privacy-policy model. “Collected” means the data may leave the device and be stored or processed to provide the feature.

| Google Play data type | Current UniSpace use | Collected? | Typical purpose(s) | Notes before submission |
| --- | --- | --- | --- | --- |
| Name | Profile/account | Yes | App functionality, account management | May be user-provided/optional depending on flow. |
| Email address | Authentication/account/support | Yes | Account management, security, app functionality | Google Sign-In/Firebase Auth are used. |
| User IDs | Firebase UID, username/account identifiers | Yes | Account management, app functionality, security | Firebase Auth UID accompanies authenticated Firebase requests. |
| Other personal info | Profile fields such as date of birth, gender, university/department/specialty/level when provided | Yes | App functionality, account management | Verify which fields are optional in the release build. |
| User messages | Private/direct chat text and message metadata | Yes | App functionality | Includes message content and related delivery/read state used by chat. |
| Photos | Profile/community/chat images selected by the user | Yes | App functionality | System picker access itself is not broad library collection; uploaded selected media is collected. |
| Videos | Chat/community video selected by the user | Yes | App functionality | Same distinction as photos. |
| Audio files | Voice messages/recordings submitted by the user | Yes | App functionality | Microphone permission is declared for recording. |
| Files and docs | User-selected chat/file attachments | Yes | App functionality | Only user-selected files should be included. |
| App interactions | Reactions, follows, saves, blocks and similar social actions | Yes | App functionality, account management/safety | Confirm final feature set. |
| Other user-generated content | Posts, comments, profile/community content | Yes | App functionality | Content is stored in Firebase services when posted. |
| Device or other IDs | FCM token / Firebase installation identifier and security/session identifiers | Yes | Notifications, security, app functionality | Firebase documents automatic Firebase Installation ID collection for relevant SDKs. |
| Diagnostics | No dedicated Crashlytics dependency found in the current pubspec | Not confirmed as app-defined collection | — | Do not mark “No” solely from this row; check every SDK in the final dependency graph. |
| Approximate/precise location | No Android location permission currently declared | No current app feature confirmed | — | Update if a real location feature is enabled later. |
| Contacts | No Android contacts permission currently declared | No current app feature confirmed | — | If contacts are enabled later, prefer Android Contact Picker instead of broad contacts access. |
| Financial info | No current feature confirmed | No | — | Revisit if payments/monetization are added. |
| Health and fitness | No current feature confirmed | No | — | — |
| Calendar | No current feature confirmed | No | — | — |
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
- [ ] Confirm the external account-deletion URL is publicly reachable without login.
- [ ] Confirm the privacy-policy URL is publicly reachable without login and is non-editable by visitors.
- [ ] Confirm account deletion can be initiated from inside the app.
- [ ] Confirm the Data Safety answers remain consistent with the privacy policy.
- [ ] Update this file whenever a new SDK, permission, account field, payment feature, analytics SDK, ads SDK, location feature, or contacts feature is added.

## Current open items

1. Upload keystore creation and signed AAB generation were intentionally deferred.
2. Legacy `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` declarations are still under separate review for older Android versions; do not remove them until their remaining runtime use is confirmed.
3. Production availability of the hosted legal/deletion URLs should be checked from Play submission environment/browser.
4. Final “shared” selections require verification of all non-Firebase SDK network behavior.
