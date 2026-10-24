# Google Play release readiness

Current Android package: `dz.fachub.fachub`

The Firebase Android client uses the same package name. Do not change it casually after a Play release has been created.

## Completed in this branch

- Target/compile SDK remain API 36.
- Release builds no longer use the debug signing key.
- Release signing is loaded from private `android/key.properties`.
- Signing secrets and keystore files are excluded from Git.
- Duplicate Android manifest permissions are removed.

## Required before the first Play upload

1. Create a private upload keystore.
2. Copy `android/key.properties.example` to `android/key.properties` and fill in the real values.
3. Build a signed Android App Bundle with `flutter build appbundle`.
4. Enable/configure Play App Signing when creating the Play release.
5. Register the Google Play app-signing SHA fingerprints with Firebase/Google Sign-In after Play provides them.
6. Complete Play Console declarations, including Data safety and account deletion/privacy links.

Use `android/GOOGLE_PLAY_DATA_SAFETY.md` as the working checklist for the Data Safety form. Re-check it against the exact release build before submission.

Repository-side legal/account deletion resources are implemented and verified by CI. On 18 September 2026, the published deletion, privacy-policy, and terms URLs were independently checked and each returned HTTP 200 with the expected public content. Re-check them once more immediately before the final Play submission.

## Photo/video access

The current inline chat attachment gallery uses photo_manager to display local thumbnails before selection. It retains READ_MEDIA_IMAGES, READ_MEDIA_VIDEO, Android 14+ READ_MEDIA_VISUAL_USER_SELECTED, and READ_EXTERNAL_STORAGE capped at API 32. Other flows use the system-backed image_picker. Permission denial and limited access must remain usable; only chosen attachments should be uploaded.

The source CI checks this explicit permission contract and rejects unnecessary write/all-files, background-location, media-location and broad contacts permissions. Passing that check is not Google Play policy approval.

Before uploading publicly, complete the Play photo/video access declaration and show why system pickers are insufficient for the app's core functionality. An inline gallery alone is not evidence of eligibility. If the use case is rejected, migrate the gallery to a system-picker implementation through a separately reviewed change; do not silently remove permissions while leaving dependent features broken.

Policy: https://support.google.com/googleplay/android-developer/answer/14115180

## Other data and release validation

- Foreground coarse/fine location supports confirmed location messages; no background location is requested.
- Contact cards use a user-selected system contact or manually entered details; no broad contacts permission is requested.
- Translation sends text outside Firebase to Google translation endpoints. Validate the opt-in disclosure, disable control, privacy policy, and Data Safety classification.
- CI pins Flutter 3.44.8 to match the SDK used for local verification. This is a reproducible toolchain pin, not a claim that it is the latest release.
- Build a new signed release AAB and test the Play-delivered build on real devices with the app-signing SHA fingerprints and production App Check configuration. Debug build success does not verify these boundaries.
- Recheck the hosted deletion/privacy/terms URLs and complete account deletion end to end using a test account.
- Verify gallery full/limited/denied permissions, foreground location consent, contact sharing, login recovery, and chat delivery with at least two accounts before public rollout.
