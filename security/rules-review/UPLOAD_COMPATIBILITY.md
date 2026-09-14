# Upload compatibility slice

Profile/cover crop explicitly outputs JPEG. Existing profile/cover upload adds image/jpeg metadata, nonempty/20 MiB preflight and UID checks before upload and before writing the URL. Comment attachment upload adds extension/kind MIME mapping (JPEG/PNG/GIF/WebP/BMP/HEIC/HEIF/AVIF, MP4/MOV/M4V/WebM/MKV/3GP), nonempty/40 MiB preflight and a UID check before upload. Unsupported extensions and size errors have Arabic messages. Files are not transcoded by this change except existing profile cropping made explicit.

This aligns these editor paths with provisional Storage limits; MIME metadata/extension matching does not verify actual file bytes. Attachment bytes are still loaded into memory before send-time checks. Signup image uploads, post image/video upload limits, chat paths and retry/overwrite handling remain separate follow-ups. No rules deployed, no runtime tests.

Deferred: crop output JPEG, cover/avatar, image/video/GIF/keyboard attachments, size boundaries, unsupported extensions, account changes, server rejection and retry.

## Post and signup follow-up

Shared validation now checks nonempty/20 MiB image and 200 MiB post-video limits in new-post and edit paths, including poll slides. Signup images also get the 20 MiB check and UID checks around upload. Video MIME is selected from supported extensions rather than defaulting every format to MP4; existing poll-edit object suffix remains .mp4 for compatibility, while metadata reflects the actual selected extension. Local validation errors are surfaced in publication/edit UI. Signup image/jpeg metadata remains the existing behavior and actual encoded format still needs verification.

These are send-time checks: earlier objects can remain uploaded if a later attachment fails. SDK retries, immutable object paths and byte-level validation remain unresolved. No runtime tests/deployment; deferred size boundaries, every video type, all poll upload paths and multi-attachment partial failures.

## Upload attempt identities

New-post image/video helpers now allocate a local Firestore random document ID per invocation and include it in the object filename. Calling doc().id generates an ID locally; no document is written. One putData/putFile task retains one object path throughout its SDK retries. A later explicit helper invocation uses a fresh path rather than overwriting the earlier object. Edit images/videos now use the existing per-edit random editUploadId instead of milliseconds, matching the existing poll-edit strategy. Poll-edit video suffix now matches the source extension/MIME. Existing URLs remain untouched. Server validators accept these filenames under the existing images/videos prefixes.

This prevents deterministic/timestamp filename reuse, not exactly-once publication. An upload can finish while its response or publication fails, leaving an orphan. No automatic re-upload loop or deletion after an ambiguous publication result is added; deleting then could remove media referenced by a committed post. Safe cleanup must verify current references, in-flight upload/publication state and a grace period on the server. SDK resume/finalization compatibility with create-only Storage rules remains a deferred integration test.
