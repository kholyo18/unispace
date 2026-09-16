const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

setGlobalOptions({ region: "europe-west1" });
initializeApp();

const { createPushNotificationHandler } = require('./security/push-notification');
exports.pushOnNotification = onDocumentCreated(
  "users/{userId}/notifications/{notifId}",
  event => createPushNotificationHandler({db:getFirestore(),auth:getAuth(),messaging:getMessaging()})(event),
);
// Keep session security in the configured CommonJS entry point.
const { onCall } = require('firebase-functions/v2/https');
const { getAuth } = require('firebase-admin/auth');
const { FieldValue } = require('firebase-admin/firestore');
const { createRevokeAllSessionsHandler } = require('./security/revoke-all-sessions');

exports.revokeAllUserSessions = onCall(
  { region: 'europe-west1' },
  createRevokeAllSessionsHandler({ auth: getAuth(), db: getFirestore(), FieldValue }),
);

const { defineString } = require('firebase-functions/params');
const { HttpsError } = require('firebase-functions/v2/https');
const { createRecoveryHandlers, createFirstFactorVerifier } = require('./security/mfa-recovery');
const recoveryApiKey = defineString('RECOVERY_AUTH_API_KEY', { default: '' });
const recoveryHandlers = createRecoveryHandlers({
  auth: getAuth(), db: getFirestore(), FieldValue,
  verifyFirstFactor: createFirstFactorVerifier({ apiKey: () => recoveryApiKey.value() }),
});
// A missing configuration must not issue unusable recovery keys.
exports.generateTotpRecoveryKey = onCall({ region: 'europe-west1', timeoutSeconds: 60 }, request => {
  if (!recoveryApiKey.value()) throw new HttpsError('unavailable', 'Recovery is not configured.');
  return recoveryHandlers.generate(request);
});
exports.recoverTotpAccount = onCall({ region: 'europe-west1', timeoutSeconds: 60 }, request => {
  if (!recoveryApiKey.value()) throw new HttpsError('unavailable', 'Recovery is not configured.');
  return recoveryHandlers.recover(request);
});

const { createPublicProfileHandler } = require('./security/public-profile');
exports.readPublicProfile = onCall({ region: 'europe-west1' },
  createPublicProfileHandler({ auth: getAuth(), db: getFirestore() }));

const { createFollowHandler } = require('./security/follow-relationships');
exports.manageFollow = onCall({ region: 'europe-west1' },
  createFollowHandler({ auth: getAuth(), db: getFirestore(), FieldValue }));

const { createSearchPeopleHandler } = require('./security/search-people');
exports.searchPeople = onCall({ region: 'europe-west1', timeoutSeconds: 60 },
  createSearchPeopleHandler({ auth: getAuth(), db: getFirestore() }));

const { createFollowListHandler } = require('./security/follow-lists');
exports.readFollowList = onCall({ region: 'europe-west1', timeoutSeconds: 60 },
  createFollowListHandler({ auth: getAuth(), db: getFirestore() }));

const { createContentSearchPageHandler } = require('./security/content-search-page');
exports.readContentSearchPage = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createContentSearchPageHandler({ auth: getAuth(), db: getFirestore() }));

exports.readContentFeedPage = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createContentSearchPageHandler({ auth: getAuth(), db: getFirestore() }, false, true));

exports.readOwnReactionPosts = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createContentSearchPageHandler({ auth: getAuth(), db: getFirestore() }, false, 'reactions'));

exports.readProfileComments = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createContentSearchPageHandler({ auth: getAuth(), db: getFirestore() }, false, 'comments'));

exports.readProfilePosts = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createContentSearchPageHandler({ auth: getAuth(), db: getFirestore() }, false, 'profile'));

const { createPollResultsHandler } = require('./security/poll-results');
exports.readOwnPollResponses = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createPollResultsHandler({ auth: getAuth(), db: getFirestore() }));

exports.readAuthorizedPost = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createContentSearchPageHandler({ auth: getAuth(), db: getFirestore() }, true));

const { createPostVoteHandler } = require('./security/post-votes');
exports.setPostVote = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createPostVoteHandler({ auth: getAuth(), db: getFirestore(), FieldValue }));

const { createCommentMutationHandler } = require('./security/comment-mutations');
exports.mutateComment = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createCommentMutationHandler({ auth: getAuth(), db: getFirestore(), FieldValue }));

const { createCommentHandler } = require('./security/create-comment');
const { getStorage } = require('firebase-admin/storage');
const { Timestamp } = require('firebase-admin/firestore');
const commentMediaBucket = defineString('COMMENT_MEDIA_BUCKET', { default: 'fachub-c631c.firebasestorage.app' });
exports.createComment = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createCommentHandler({ auth: getAuth(), db: getFirestore(), FieldValue, Timestamp,
    bucket: () => getStorage().bucket(commentMediaBucket.value()) }));

const { createDeletePostHandler } = require('./security/delete-post');
exports.deleteOwnPost = onCall({ region: 'europe-west1' },
  createDeletePostHandler({ auth: getAuth(), db: getFirestore(), FieldValue }));

const { createEditPostHandler } = require('./security/edit-post');
exports.editOwnPost = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createEditPostHandler({ auth: getAuth(), db: getFirestore(), FieldValue,
    bucket: () => getStorage().bucket(commentMediaBucket.value()) }));

const { createPostHandler } = require('./security/create-post');
const postCreationDependencies = { auth: getAuth(), db: getFirestore(), FieldValue,
  bucket: () => getStorage().bucket(commentMediaBucket.value()) };
exports.reserveOwnPost = onCall({ region: 'europe-west1' }, createPostHandler(postCreationDependencies));
exports.publishOwnPost = onCall({ region: 'europe-west1', timeoutSeconds: 120 }, createPostHandler(postCreationDependencies, true));

const { createRepostHandler } = require('./security/repost');
exports.publishRepost = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createRepostHandler({ auth: getAuth(), db: getFirestore(), FieldValue }));

const { createSyncPushDeviceHandler } = require('./security/push-preferences');
exports.syncPushDevice = onCall({region:'europe-west1'},
  createSyncPushDeviceHandler({auth:getAuth(),db:getFirestore(),FieldValue}));

exports.detachPushDevice = onCall({region:'europe-west1'},
  createSyncPushDeviceHandler({auth:getAuth(),db:getFirestore(),FieldValue},true));

const { createPollAnswerHandler } = require('./security/poll-answers');
exports.submitPollAnswers = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createPollAnswerHandler({ auth: getAuth(), db: getFirestore(), FieldValue }));

const { createPostReportHandler } = require('./security/post-reports');
exports.submitPostReport = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createPostReportHandler({ auth: getAuth(), db: getFirestore(), FieldValue }));

const { createCommentReportHandler } = require('./security/comment-reports');
const { createAccountReportHandler } = require('./security/account-reports');
exports.submitCommentReport = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createCommentReportHandler({ auth: getAuth(), db: getFirestore(), FieldValue }));
exports.submitAccountReport = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createAccountReportHandler({ auth: getAuth(), db: getFirestore(), FieldValue }));

const { createModerationActionHandler } = require('./security/moderation-actions');
exports.moderateCommunityReport = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createModerationActionHandler({ auth: getAuth(), db: getFirestore(), FieldValue }));

const { createModerationInboxHandler } = require('./security/moderation-inbox');
exports.readModerationInbox = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createModerationInboxHandler({ auth: getAuth(), db: getFirestore() }));

const { createModerationPreviewHandler } = require('./security/moderation-preview');
exports.readModerationPreview = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createModerationPreviewHandler({ auth: getAuth(), db: getFirestore() }));

const { createOwnReportStatusHandler } = require('./security/own-report-status');
exports.readOwnReportStatus = onCall({ region: 'europe-west1', timeoutSeconds: 60 },
  createOwnReportStatusHandler({ auth: getAuth(), db: getFirestore() }));

const { createOwnProfileCountsHandler } = require('./security/own-profile-counts');
exports.readOwnProfileCounts = onCall({ region: 'europe-west1', timeoutSeconds: 60 },
  createOwnProfileCountsHandler({ auth: getAuth(), db: getFirestore() }));

const { createSyncAuthorPrivacyHandler } = require('./security/sync-author-privacy');
exports.syncOwnPostPrivacy = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createSyncAuthorPrivacyHandler({ auth: getAuth(), db: getFirestore() }));

const { createSyncAuthorIdentityHandler } = require('./security/sync-author-identity');
exports.syncOwnPostIdentity = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createSyncAuthorIdentityHandler({ auth: getAuth(), db: getFirestore() }));

const { createOwnPostExportHandler } = require('./security/own-post-export');
exports.readOwnPostExportPage = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createOwnPostExportHandler({ auth: getAuth(), db: getFirestore() }));

const { createOwnProfileExportHandler } = require('./security/own-profile-export');
exports.readOwnProfileExport = onCall({ region: 'europe-west1', timeoutSeconds: 60 },
  createOwnProfileExportHandler({ auth: getAuth(), db: getFirestore() }));

const { createOwnListExportHandler } = require('./security/own-list-export');
exports.readOwnListExportPage = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createOwnListExportHandler({ auth: getAuth(), db: getFirestore() }));

const { createMediaDownloadHandler } = require('./security/media-download');
exports.readPostMediaDownload = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createMediaDownloadHandler({ auth: getAuth(), db: getFirestore(),
    bucket: () => getStorage().bucket(commentMediaBucket.value()) }));

exports.readPostMediaBatch = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createMediaDownloadHandler({ auth: getAuth(), db: getFirestore(),
    bucket: () => getStorage().bucket(commentMediaBucket.value()) }, true));

exports.readCommentMediaDownload = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createMediaDownloadHandler({ auth: getAuth(), db: getFirestore(),
    bucket: () => getStorage().bucket(commentMediaBucket.value()) }, false, true));

exports.verifyCommentMediaAccess = onCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createMediaDownloadHandler({ auth: getAuth(), db: getFirestore(),
    bucket: () => getStorage().bucket(commentMediaBucket.value()) }, false, true, {verifyOnly:true}));

const { createUsernameCheckHandler } = require('./security/username-check');
exports.checkSignupUsername = onCall({ region: 'europe-west1', timeoutSeconds: 60 },
  createUsernameCheckHandler({auth:getAuth(), db:getFirestore()}));

const { createCompleteSignupHandler } = require('./security/complete-signup');
exports.completeSignupProfile = onCall({region:'europe-west1',timeoutSeconds:60},
  createCompleteSignupHandler({auth:getAuth(),db:getFirestore(),bucketName:()=>commentMediaBucket.value()}));

const { createSessionBootstrapHandler } = require('./security/session-bootstrap');
exports.markCurrentSession = onCall({region:'europe-west1',timeoutSeconds:60},
  createSessionBootstrapHandler({auth:getAuth(),db:getFirestore()}));

// Staged consent record-keeping only; no production policy is enabled by this export.
const { createConsentHandlers } = require('./legal/consent');
const legalConsentHandlers = createConsentHandlers({
  auth: getAuth(), db: getFirestore(), FieldValue, HttpsError,
});
exports.readLegalConsentStatus = onCall({ region: 'europe-west1', timeoutSeconds: 60 },
  legalConsentHandlers.status);
exports.acceptLegalDocuments = onCall({ region: 'europe-west1', timeoutSeconds: 60 },
  legalConsentHandlers.accept);
