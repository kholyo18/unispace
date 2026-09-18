# Google Play Console submission checklist

Updated: 18 September 2026

This checklist complements:
- `android/PLAY_RELEASE_READINESS.md`
- `android/GOOGLE_PLAY_DATA_SAFETY.md`

Current Android package: `dz.fachub.fachub`

## 1. Technical release

- [x] Target/compile SDK are API 36.
- [x] Debug signing is not used for release builds.
- [x] Android 13+ broad photo/video permissions are removed.
- [x] Legacy broad external-storage permissions are removed.
- [x] Chat media selection uses the system-backed picker.
- [x] Gradle/AGP/Kotlin are aligned with the current Flutter toolchain used by CI.
- [x] Android compile verification exists in GitHub Actions.
- [ ] Create the private Upload Keystore.
- [ ] Create local `android/key.properties` with the private upload-key values.
- [ ] Build the signed release AAB.
- [ ] Upload the first AAB to Play Console.
- [ ] Enable/configure Play App Signing.
- [ ] Add the Google Play app-signing SHA-1 and SHA-256 fingerprints to Firebase/Google Sign-In after Play provides them.

## 2. Store listing

Before review, complete the main store listing with the exact production app:
- [ ] App name.
- [ ] Short description.
- [ ] Full description.
- [ ] App icon.
- [ ] Feature graphic.
- [ ] Phone screenshots.
- [ ] Support/contact email.
- [ ] App category.
- [ ] Countries/regions and pricing/distribution settings.

Do not describe planned features as if they are already available in the submitted build.

## 3. Privacy policy and account deletion

Public pages verified reachable on 18 September 2026:
- [x] Privacy policy: `https://fachub-c631c.web.app/privacy-policy`
- [x] Account deletion: `https://fachub-c631c.web.app/delete-account`
- [x] Terms: `https://fachub-c631c.web.app/terms-of-use`

The in-app account-deletion flow is implemented.

Before final submission:
- [ ] Re-check the public URLs from a normal browser without authentication.
- [ ] Enter the privacy-policy URL in Play Console.
- [ ] Enter the external account-deletion URL where Play Console requests it.
- [ ] Confirm the in-app privacy/deletion screens remain reachable in the submitted build.

## 4. App access for reviewers

UniSpace contains account-authenticated features. Play Console may need reviewer access instructions.

Prepare:
- [ ] A stable review/test account that will remain valid during review, if login is required to reach core features.
- [ ] Exact sign-in steps.
- [ ] Any special Google Sign-In, OTP, two-factor, or other authentication instructions.
- [ ] Instructions for reaching important restricted features such as chat, profile/privacy settings, and account deletion.

Never provide a reviewer with a personal developer account or unrelated private credentials.

## 5. Ads declaration

- [ ] Verify the exact release build for ads, sponsored placements, ad SDKs, and ad-like content.
- [ ] Answer Play Console's “Contains ads” declaration to match the submitted build.

Do not answer based only on future monetization plans; the declaration must match what the release actually contains.

## 6. Target audience and content

Current UniSpace legal documents state that account/community use is intended for users aged 18+.

Before submission:
- [ ] Ensure the actual onboarding/product behavior is consistent with that stated audience.
- [ ] Select the target age group(s) in Play Console accurately.
- [ ] If the intended release is genuinely 18+ only, review Play Console's minor-access restriction option.
- [ ] Revisit this section if the product later targets younger users.

Any selection that includes children triggers additional Families-policy requirements.

## 7. Content rating

Google Play requires an IARC content rating.

- [ ] Complete the Content rating questionnaire using the actual release features.
- [ ] Account for user-generated posts/comments.
- [ ] Account for direct messaging/chat.
- [ ] Account for any content reporting/moderation features.
- [ ] Keep the rating questionnaire updated if app content/features change.

Do not guess or choose a desired rating; answer the questionnaire factually.

## 8. Data Safety

Use `android/GOOGLE_PLAY_DATA_SAFETY.md` as the working source.

Before submission:
- [ ] Re-check all current dependencies/SDKs.
- [ ] Re-check data collected by account/profile/community/chat features.
- [ ] Re-check Firebase Authentication, Firestore, Storage, Functions, Messaging and installation/device identifiers.
- [ ] Review any non-Firebase network path still present in the release.
- [ ] Confirm Data Safety answers match the public privacy policy.
- [ ] Confirm deletion/retention statements match the production deletion flow.

## 9. Permissions and sensitive APIs

The current main manifest should not contain:
- `READ_MEDIA_IMAGES`
- `READ_MEDIA_VIDEO`
- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`

- [ ] Review the merged manifest from the final release AAB after upload.
- [ ] Check Play Console for any Permissions Declaration alerts.
- [ ] If a future feature adds a sensitive/high-risk permission, complete any required declaration before review.

## 10. Testing tracks

- [ ] Use Internal testing for an early Play-distributed build.
- [ ] Test sign-in, profile, feed/community, chat, media picking, notifications, privacy settings, account deletion, and logout on real devices.
- [ ] Confirm the Photo Picker works without broad media/storage access.

Conditional account requirement:
- [ ] If the Play Console developer account is a personal account created after 13 November 2023, complete the required closed test: at least 12 testers continuously opted in for at least 14 days before applying for production access.
- [ ] Keep useful tester feedback and fixes documented for the production-access application.

## 11. Final pre-review pass

Immediately before sending the app for review:
- [ ] Pull the exact final `main`.
- [ ] Ensure only intended source changes are present.
- [ ] Run `flutter pub get`.
- [ ] Generate localization files.
- [ ] Run analyzer and verify there are no compile errors.
- [ ] Build the signed release AAB.
- [ ] Verify version name/version code.
- [ ] Verify package name remains `dz.fachub.fachub`.
- [ ] Verify the app launches and signs in from the Play-distributed test build.
- [ ] Re-check privacy/deletion URLs.
- [ ] Re-check Data Safety, Ads, App access, Target audience, and Content rating declarations.
- [ ] Review Play Console pre-review warnings and resolve all blockers.

## Remaining release blockers currently known

1. Private Upload Keystore / `key.properties` is not yet created.
2. Signed production AAB has not yet been generated.
3. Play App Signing certificate fingerprints cannot be added to Firebase until Play provides them after the app/release setup.
4. Final Play Console declarations still need to be entered in the Play Console UI.
5. Remaining non-chat external translation usage must be reviewed for Data Safety/reliability before the final submission.
