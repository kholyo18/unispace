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

## Open policy item: photo/video access

The current chat gallery uses `photo_manager` and requests broad device photo/video access through:

- `READ_MEDIA_IMAGES`
- `READ_MEDIA_VIDEO`

Before Play submission, either:

- migrate chat media selection to the Android system photo picker and remove broad permissions; or
- retain broad access only if the app can legitimately satisfy Google Play's restricted Photo & Video Permissions policy and declaration.

Do not remove these permissions without changing the custom chat gallery code first, because the current `PhotoManager` flow depends on them.
