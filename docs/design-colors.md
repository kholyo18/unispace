# UniSpace UI color system

The approved university identity uses forest green and warm ivory. `lib/core/brand_palette.dart` owns shared color values; `lib/ui/theme.dart` maps them to Flutter Material roles. Use `Theme.of(context).colorScheme` for new UI, and pair primary/onPrimary, surface/onSurface and error/onError. Do not assign white text to a theme primary: the dark theme primary is mint and needs forest text.

| Role | Light | Dark |
|---|---|---|
| Page | #F4F6F3 | #101914 |
| Card / sheet | #FFFFFF | #1B2720 |
| Input | #EDF1EE | #152019 |
| Primary | #00483F | #83CBB2 |
| Main text | #202D25 | #EDF3EE |
| Secondary text | #59675F | #AFBDB3 |
| Container | #E2EEE7 | #2B3D32 |

## Integration

- Global Material theme covers dialogs, sheets, app bars, tabs, navigation, fields, selection, cards, chips, drawers and menus. Exams, study planning, legal readers and chat subpages that already consume Material roles inherit this palette.
- Migrated explicit neutral and brand overrides in feed/search, posts/composer/polls/comments, profiles/relationships, settings/security, chat/emoji/reactions and academic calculators.
- Login, account setup and launch reuse the shared palette, preserving the approved composition.
- Quick calculator now respects the active theme instead of imposing black; numeric calculations, saved data and gestures are unchanged.
- Default primary/accent colors and reset use forest green. Saved user-selected accents remain available.
- Default chat bubble uses forest green. Existing saved chat bubble colors, gradients and wallpapers remain untouched.

## Intentional exceptions

Keep semantic error/warning/success distinctions, chart/category colors, reaction/vote colors, custom wallpaper palettes, photo drawing colors and original artwork. Full-screen image/video/crop/editor canvases retain black for viewing media; their content must not be tinted. Brand artwork must not be recolored by user accent preferences.

## Checks

`test/brand_theme_test.dart` checks normal-text contrast >= 4.5, control outline contrast >= 3, custom accent/reset and the real quick calculator's calculation/save in Arabic, English and French, light/dark. Other regression suites cover login/account setup, chat preferences/context/details, exams and poll serialization.

Optional `CAPTURE_PALETTE_PREVIEWS=true` captures calculator previews using bundled Tajawal in the test harness for readable text. It does not change production typography.

Local widget tests do not replace device visual acceptance. No Firebase deployment or store release is part of this color update.

## Surface balance revision

Keep forest/ivory in the logo and launch identity. General pages use low-saturation neutrals; readable body text is neutral rather than brand green. Reserve primary green for calls to action, active navigation, focus and selection. Secondary actions use muted sage. Cards are flat white or a raised dark neutral, with subtle borders rather than a green tint over the whole page.

Use distinct low/container/high/highest roles for inputs, cards, raised controls and selected surfaces. Login and signup gradients move gently from page to field colors. Avoid decorative gradients behind dense text. Error and warning colors, user-selected accents, chat wallpapers and artwork keep their semantics and customization.

Optional preview command: flutter test --dart-define=CAPTURE_BALANCED_PALETTE=true test/palette_balance_preview_test.dart. Captures the real notification screen in both modes with the bundled Tajawal font for legible test rendering.
