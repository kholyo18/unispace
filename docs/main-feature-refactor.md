# Main feature extraction and duplicate tools cleanup

Date: 2026-10-03

## Scope and outcome

`lib/main.dart` previously contained 45,814 lines after the initial limited cleanup. It now contains about 256 lines: imports, part declarations and bootstrap. Existing application classes and private helpers stay in the same Dart library so cross-feature references, controller ownership and authentication boundaries are preserved.

The remaining implementation is organized under `lib/app/parts/`. These are same-library parts, not independent packages or a runtime lazy-loading scheme. This deliberately avoids changing every public import and introducing circular imports while reducing the entrypoint to startup responsibility.

## Where the code lives

- App root, drawer and notes: `app_shell.dart`, `appearance.dart`, `notes.dart`.
- Authentication: `authentication.dart`.
- Feed, search, post cards/composer and saved content: `feed.dart`, `community_search.dart`, `post_cards.dart`, `post_composer.dart`, `saved_posts.dart`.
- Video: `feed_videos.dart`, `simple_video_viewer.dart`, `fullscreen_video.dart`, `video_controls.dart`. `video_preview.dart` retains only the shared initialization gate.
- Media paging and images: `post_pager.dart`, `fullscreen_media.dart`, `fullscreen_images.dart`, `post_images.dart`, `feed_images.dart`, `media_carousel.dart`.
- Polls: `poll_question.dart`, `poll_builder.dart`, `poll_results.dart`, `poll_models.dart`, `poll_question_card.dart`.
- Comments, profiles, relationships, notifications and moderation have their own named parts.

## Actual deduplication and removal

Pure reusable helpers live in independent files, rather than repeating algorithms inside widgets:

- `lib/features/community/polls/poll_values.dart`: one recursive answer serializer; common slider emoji/color thresholds used by four active renderers; result-scale emoji resampling shared by two result widgets.
- `lib/features/community/media/video_values.dart`: common progress ratio, compact duration formatting and the existing 300 ms completion threshold.
- Removed the shadowed duplicate answer serializer and the unused fullscreen duration formatter.
- Deleted five unreachable widget implementations and their state classes: `PollPostWidget`, `DatePollWidget`, `VideoPreviewTile`, `_VideoListWidget`, `_ModernProgressBar`. Repository searches found no callers beyond their own declarations/state wiring. This is an application with `publish_to: none`; these unused symbols are intentionally removed, not preserved as a public package API.
- Kept `_DateModeChip`, which is used by the active poll builder. It lives with the shared poll card UI.

The active poll grid/answer widgets have different state contracts; input, builder preview and result display are not interchangeable. Feed videos, comment videos and the fullscreen pager also have different authorization and controller lifetimes. Those paths remain separate and use shared helpers only where behavior is equivalent.

## Verification

- AST comparison with the exact pre-edit snapshot: **419 declarations unchanged, 13 intentionally deduplicated, 10 widget/state declarations removed**. Existing appearance/app-shell/notes parts were not edited.
- Flutter regression suite covers new helper boundaries and nested answer encoding, startup, live localization, pager retention, playback source and authorized video cache.
- Targeted Node contracts for relationships, profile privacy, push rendering and streaming: **16 passed** after the final removal.
- Broader seven-file Node contract run: **23 passed, 7 failed**, matching the previously documented pre-existing account lifecycle/notification/upload/candidate-rules failures. Their assertions were not relaxed.
- Analyzer across the extracted parts and new helpers: **zero errors**; 407 pre-existing warnings/style diagnostics remain. Analyzing only `main.dart` is insufficient for reporting diagnostics in its parts, so the parts directory was explicitly analyzed.

No live Firebase changes, deployment or phone installation is part of this patch. Moving source code and deleting unreachable widgets does not establish a runtime speedup. Physical-device video/poll interaction remains unverified.

Exact snapshots and command logs: `C:/Users/user/unispace/main_refactor_v2/`.

Final integration: all **38 Flutter tests passed** after deletion. `flutter build apk --debug --no-pub` succeeded (assembleDebug 80.7 seconds). Independent read-only review found no material media/poll regression; all 40 part directives resolve and the background entrypoint annotation remains attached. Existing diagnostic messages were compared with the prior baseline: no new diagnostic type/message appeared.
