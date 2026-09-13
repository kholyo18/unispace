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
