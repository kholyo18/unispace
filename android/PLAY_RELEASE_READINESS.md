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

Repository-side legal/account deletion resources are implemented and verified by CI. The hosted production URLs still need a final reachability check from a normal browser before Play submission.

## Photo/video access

Completed:

- Chat media selection no longer reads the device library through `photo_manager`.
- Gallery selection now uses `image_picker` mixed-media selection. On Android 13+ this uses the Android system Photo Picker.
- `READ_MEDIA_IMAGES` and `READ_MEDIA_VIDEO` were removed from the main Android manifest.
- CI rejects either broad media permission if it is reintroduced.

Legacy `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` entries remain limited to Android 12L/API 32 and lower. They were not changed in this migration because other legacy save/download flows must be reviewed separately before removing them.
