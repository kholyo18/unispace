const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

setGlobalOptions({ region: "europe-west1" });
initializeApp();

exports.pushOnNotification = onDocumentCreated(
  "users/{userId}/notifications/{notifId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const userId = event.params.userId;
    const notifId = event.params.notifId;

    const tokensSnap = await getFirestore()
      .collection("users")
      .doc(userId)
      .collection("fcm_tokens")
      .get();

    const tokens = tokensSnap.docs
      .map((d) => d.data().token)
      .filter((t) => typeof t === "string" && t.length > 0);

    if (tokens.length === 0) return;

    const title = data.actorName || "UniSpace";
    const body = data.message || "لديك إشعار جديد";

    const res = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: {
        type: String(data.type || ""),
        actorId: String(data.actorId || ""),
        actorName: String(data.actorName || ""),
        message: String(body),
        postId: String(data.postId || ""),
        commentId: String(data.commentId || ""),
        notificationId: String(notifId),
      },
      android: {
        priority: "high",
        notification: { channelId: "unispace_notifications" },
      },
    });

    const stale = [];
    res.responses.forEach((r, i) => {
      if (
        !r.success &&
        r.error &&
        (r.error.code === "messaging/registration-token-not-registered" ||
          r.error.code === "messaging/invalid-registration-token")
      ) {
        stale.push(tokensSnap.docs[i].ref);
      }
    });
    await Promise.all(stale.map((ref) => ref.delete()));
  }
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
