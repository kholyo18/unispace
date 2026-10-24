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
// Sign-out, own deletion, token detach and session display bootstrap stay
// available through their own verified-token handlers during suspension.
const { onCall: rawOnCall } = require('firebase-functions/v2/https');
const { beforeUserSignedIn } = require('firebase-functions/v2/identity');
const { createSessionGuard, createSignInSessionHandler, createRevokeDeviceSessionsHandler } = require('./security/device-sessions');
const sessionGuard = createSessionGuard({ db: getFirestore() });
const lifecycleExemptOnCall = (options, handler) => rawOnCall(options, sessionGuard(handler));
const { createAccountAccessGuard } = require('./security/account-access-guard');
const accountAccessGuard = createAccountAccessGuard({ db: getFirestore() });
const { createReleasePolicyReader, createReleaseVersionGuard } = require('./security/release-policy');
const releaseVersionGuard = createReleaseVersionGuard({db:getFirestore()});
exports.readReleasePolicy = rawOnCall({region:'europe-west1'}, createReleasePolicyReader({db:getFirestore()}));
const onCall = (options, handler) => lifecycleExemptOnCall(options, accountAccessGuard(releaseVersionGuard(handler)));
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getAuth } = require('firebase-admin/auth');
const { FieldValue } = require('firebase-admin/firestore');
exports.issueDeviceSession = beforeUserSignedIn({ region: 'europe-west1' },
  createSignInSessionHandler({ db: getFirestore(), FieldValue }));
exports.revokeDeviceSessions = lifecycleExemptOnCall({ region: 'europe-west1', timeoutSeconds: 120 },
  createRevokeDeviceSessionsHandler({ auth: getAuth(), db: getFirestore(), FieldValue }));
const { createRevokeAllSessionsHandler } = require('./security/revoke-all-sessions');

exports.revokeAllUserSessions = lifecycleExemptOnCall(
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
exports.recoverTotpAccount = lifecycleExemptOnCall({ region: 'europe-west1', timeoutSeconds: 60 }, request => {
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

exports.detachPushDevice = lifecycleExemptOnCall({region:'europe-west1'},
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
// Onboarding handlers verify revocation themselves and support existing logins.
// Enforce selective session revocation as well when the sign-in token has sid.
const onboardingOnCall = (options, handler) => rawOnCall(options, accountAccessGuard(
  request => request.auth?.token?.sid != null ? sessionGuard(handler)(request) : handler(request)));
exports.checkSignupUsername = onboardingOnCall({ region: 'europe-west1', timeoutSeconds: 60 },
  createUsernameCheckHandler({auth:getAuth(), db:getFirestore()}));

const { createCompleteSignupHandler } = require('./security/complete-signup');
exports.completeSignupProfile = onboardingOnCall({region:'europe-west1',timeoutSeconds:60},
  createCompleteSignupHandler({auth:getAuth(),db:getFirestore(),bucketName:()=>commentMediaBucket.value()}));

const { createSessionBootstrapHandler } = require('./security/session-bootstrap');
exports.markCurrentSession = lifecycleExemptOnCall({region:'europe-west1',timeoutSeconds:60},
  createSessionBootstrapHandler({auth:getAuth(),db:getFirestore()}));

const { createAccountDeletionRequestHandler } = require('./security/account-deletion-request');
const accountDeletionRequestHandler = createAccountDeletionRequestHandler({
  auth: getAuth(),
  db: getFirestore(),
  FieldValue,
  Timestamp,
  revokeAllSessions: createRevokeAllSessionsHandler({
    auth: getAuth(),
    db: getFirestore(),
    FieldValue,
  }),
});
exports.requestAccountDeletion = lifecycleExemptOnCall(
  { region: 'europe-west1', timeoutSeconds: 60 },
  accountDeletionRequestHandler,
);

const { createAccountDeletionWorker } = require('./security/account-deletion-worker');
exports.processAccountDeletions = onSchedule(
  {
    region: 'europe-west1',
    schedule: 'every 15 minutes',
    timeZone: 'Etc/UTC',
    timeoutSeconds: 540,
    memory: '1GiB',
    maxInstances: 1,
  },
  createAccountDeletionWorker({
    auth: getAuth(),
    db: getFirestore(),
    bucket: () => getStorage().bucket(commentMediaBucket.value()),
    FieldValue,
    Timestamp,
  }),
);

// Account lifecycle: self-service state cannot clear administrative restrictions.
const { createAccountStateHandlers } = require('./security/account-state');
const accountStateHandlers = createAccountStateHandlers({ auth: getAuth(), db: getFirestore(), FieldValue });
exports.setOwnAccountState = onCall({ region: 'europe-west1', timeoutSeconds: 60 }, accountStateHandlers.own);
exports.setAdministrativeAccountRestriction = onCall(
  { region: 'europe-west1', timeoutSeconds: 60 }, accountStateHandlers.administrative);

const { createStorageUploadHandler } = require('./security/storage-upload');
exports.prepareStorageUpload = onCall({ region: 'europe-west1', timeoutSeconds: 60 },
  createStorageUploadHandler({ auth: getAuth(), db: getFirestore(), FieldValue, Timestamp,
    bucketName: () => commentMediaBucket.value() }));

// Private optimized playback pipeline; original media remains unchanged.
Object.assign(exports, require('./security/playback-functions'));

const {createChatViewOnceHandlers}=require('./security/chat-view-once');
const chatViewOnceHandlers=createChatViewOnceHandlers({db:getFirestore(),auth:getAuth(),FieldValue,Timestamp,
  bucket:()=>getStorage().bucket(commentMediaBucket.value()),
  prepareUpload:createStorageUploadHandler({auth:getAuth(),db:getFirestore(),FieldValue,Timestamp,bucketName:()=>commentMediaBucket.value()})});
const { createChatHandlers } = require('./security/chat-service');
const chatHandlers = createChatHandlers({db:getFirestore(),auth:getAuth(),FieldValue,viewOnce:chatViewOnceHandlers});
exports.openChat = onCall({region:'europe-west1'},chatHandlers.open);
exports.sendChatMessage = onCall({region:'europe-west1'},chatHandlers.send);
exports.voteChatPoll = onCall({region:'europe-west1'},chatHandlers.vote);
exports.respondChatEvent = onCall({region:'europe-west1'},chatHandlers.respondEvent);
exports.respondChatRequest = onCall({region:'europe-west1'},chatHandlers.respond);
exports.mutateChatMessage = onCall({region:'europe-west1'},chatHandlers.mutate);

const {createChatNotificationHandler}=require('./security/chat-push');
exports.pushOnChatMessage=onDocumentCreated('chats/{chatId}/messages/{messageId}',createChatNotificationHandler({db:getFirestore(),FieldValue}));
const {createGroupHandlers}=require('./security/chat-groups');
const groupHandlers=createGroupHandlers({db:getFirestore(),auth:getAuth(),FieldValue,bucket:()=>getStorage().bucket(commentMediaBucket.value())});
exports.createChatGroup=onCall({region:'europe-west1'},groupHandlers.create);
exports.manageChatGroup=onCall({region:'europe-west1'},groupHandlers.manage);
exports.respondGroupInvite=onCall({region:'europe-west1'},groupHandlers.respond);
exports.manageGroupAccess=onCall({region:'europe-west1'},groupHandlers.access);
exports.requestGroupJoin=onCall({region:'europe-west1'},groupHandlers.requestJoin);
exports.listGroupJoinRequests=onCall({region:'europe-west1'},groupHandlers.listJoinRequests);
exports.reviewGroupJoinRequest=onCall({region:'europe-west1'},groupHandlers.reviewJoinRequest);

// Private documents use short-lived signed transfers, never broad Storage writes.
const {createChatDocumentHandlers}=require('./security/chat-documents');
const chatDocumentHandlers=createChatDocumentHandlers({db:getFirestore(),auth:getAuth(),FieldValue,Timestamp,
  bucket:()=>getStorage().bucket(commentMediaBucket.value()),
  prepareUpload:createStorageUploadHandler({auth:getAuth(),db:getFirestore(),FieldValue,Timestamp,bucketName:()=>commentMediaBucket.value()})});
exports.prepareChatDocumentUpload=onCall({region:'europe-west1'},chatDocumentHandlers.prepare);
exports.readChatDocumentDownload=onCall({region:'europe-west1'},chatDocumentHandlers.read);

exports.prepareChatViewOnceUpload=onCall({region:'europe-west1'},chatViewOnceHandlers.prepare);
const {onRequest}=require('firebase-functions/v2/https');
const {pipeline}=require('node:stream/promises');
exports.consumeChatViewOncePhoto=onRequest({region:'europe-west1',timeoutSeconds:120,memory:'256MiB'},async(req,res)=>{
  res.set({'Cache-Control':'private, no-store, max-age=0','Pragma':'no-cache','X-Content-Type-Options':'nosniff'});
  if(req.method!=='POST'){res.status(405).end();return;}
  try {
    const photo=await chatViewOnceHandlers.consume(req);
    res.set({'Content-Type':photo.contentType,'Content-Length':String(photo.size)});
    await pipeline(photo.file.createReadStream(),res);
  } catch(error) {
    if(res.headersSent||res.destroyed){res.destroy();return;}
    const status=({'unauthenticated':401,'permission-denied':403,'not-found':404,'already-exists':410,'failed-precondition':410,'invalid-argument':400})[error.code]||503;
    res.removeHeader('Content-Length');res.status(status).json({error:'Photo unavailable'});
  }
});
exports.cleanupChatViewOncePhotos=onSchedule({schedule:'every 24 hours',region:'europe-west1',timeoutSeconds:120},()=>chatViewOnceHandlers.cleanup());

exports.confirmChatViewOnceUpload=onCall({region:'europe-west1'},chatViewOnceHandlers.confirmUpload);

const {createChatNotificationActionHandler}=require('./security/chat-notification-actions');
exports.handleChatNotificationAction=onCall({region:'europe-west1'},createChatNotificationActionHandler({db:getFirestore(),auth:getAuth(),chatHandlers}));

// Protected media locators never carry permanent download tokens.
const {createProtectedMediaHandler}=require('./security/protected-media');
exports.readProtectedMedia=onCall({region:'europe-west1',timeoutSeconds:60},
  createProtectedMediaHandler({auth:getAuth(),db:getFirestore(),bucket:()=>getStorage().bucket(commentMediaBucket.value())}));
const {createProtectedUploadHandlers}=require('./security/protected-upload');
const protectedUploads=createProtectedUploadHandlers({auth:getAuth(),db:getFirestore(),FieldValue,Timestamp,
  bucket:()=>getStorage().bucket(commentMediaBucket.value()),
  prepareUpload:createStorageUploadHandler({auth:getAuth(),db:getFirestore(),FieldValue,Timestamp,bucketName:()=>commentMediaBucket.value()})});
exports.prepareProtectedUpload=onCall({region:'europe-west1',timeoutSeconds:60},protectedUploads.prepare);
exports.finalizeProtectedUpload=onCall({region:'europe-west1',timeoutSeconds:120},protectedUploads.finalize);
const {createProtectedUploadCleanup}=require('./security/protected-upload-cleanup');
exports.cleanupProtectedUploadStaging=onSchedule({schedule:'every 24 hours',region:'europe-west1',timeoutSeconds:120},
 createProtectedUploadCleanup({db:getFirestore(),bucket:()=>getStorage().bucket(commentMediaBucket.value())}));