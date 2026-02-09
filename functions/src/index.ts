import { randomBytes, randomInt, randomUUID, createHash } from "crypto";
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { onCall, HttpsError, onRequest } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { error as logError, info as logInfo, warn as logWarn } from "firebase-functions/logger";
import sgMail from "@sendgrid/mail";

initializeApp();
const db = getFirestore();
const auth = getAuth();

const SUPPORT_EMAIL = "unispace.0.1.0@gmail.com";
const EMAIL_SUBJECT = "[UniSpace] New Contact Message";
const OTP_EMAIL_SUBJECT = "رمز التحقق UniSpace";
const OTP_TTL_MINUTES = 10;
const OTP_ATTEMPT_LIMIT = 5;
const OTP_RESEND_LIMIT = 3;
const OTP_RESEND_COOLDOWN_SECONDS = 60;
const USERNAME_RESERVE_MINUTES = 15;

export const helloWorld = onRequest((req, res) => {
  logger.info("helloWorld function invoked", { path: req.path, method: req.method });
  res.send("Hello from Firebase!");
});

const LOGIN_2FA_TTL_MINUTES = 5;
const LOGIN_2FA_ATTEMPT_LIMIT = 5;
const LOGIN_2FA_RESEND_COOLDOWN_SECONDS = 30;
const LOGIN_2FA_LOCK_MINUTES = 5;

type SupportMessage = {
  name?: string;
  email?: string;
  message?: string;
  createdAt?: { toDate?: () => Date } | string | number | null;
  deviceInfo?: Record<string, unknown> | null;
};

const getCreatedAt = (createdAt: SupportMessage["createdAt"]): string => {
  if (createdAt && typeof createdAt === "object" && "toDate" in createdAt) {
    const date = createdAt.toDate?.();
    if (date) {
      return date.toISOString();
    }
  }
  if (typeof createdAt === "number") {
    return new Date(createdAt).toISOString();
  }
  if (typeof createdAt === "string" && createdAt.trim().length > 0) {
    return createdAt;
  }
  return "unknown";
};

const buildEmailBody = (data: SupportMessage, docId: string): string => {
  const deviceInfo = data.deviceInfo ?? {};
  return [
    `Document ID: ${docId}`,
    `Name: ${data.name ?? "-"}`,
    `Email: ${data.email ?? "-"}`,
    `Created At: ${getCreatedAt(data.createdAt ?? null)}`,
    "",
    "Message:",
    data.message ?? "-",
    "",
    "Device Info:",
    JSON.stringify(deviceInfo, null, 2),
  ].join("\n");
};

type SignupSession = {
  email: string;
  firstName: string;
  lastName: string;
  usernameLower: string;
  otpHash: string;
  otpSalt: string;
  expiresAt: Timestamp;
  attempts: number;
  resendCount: number;
  status: "pending" | "verified" | "expired";
  createdAt: Timestamp;
  lastSentAt: Timestamp;
};

const isValidEmail = (email: string): boolean => {
  return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
};

const normalizeUsername = (username: string): string => {
  return username.trim().toLowerCase();
};

const isValidUsername = (username: string): boolean => {
  return /^[a-zA-Z0-9_]{3,20}$/.test(username);
};

const hashOtp = (otp: string, salt: string): string => {
  return createHash("sha256").update(`${otp}${salt}`).digest("hex");
};

const buildOtpEmailText = (otp: string): string => {
  return [
    "مرحبًا بك في UniSpace!",
    "",
    `رمز التحقق الخاص بك هو: ${otp}`,
    `صلاحية الرمز ${OTP_TTL_MINUTES} دقائق.`,
    "",
    "إذا لم تقم بطلب هذا الرمز، تجاهل هذه الرسالة.",
  ].join("\n");
};

const ensureSendgridConfigured = (): string => {
  const apiKey = process.env.SENDGRID_API_KEY;
  const fromEmail = process.env.SENDGRID_FROM_EMAIL;
  if (!apiKey || !fromEmail) {
    throw new HttpsError(
      "failed-precondition",
      "sendgrid_not_configured",
    );
  }
  sgMail.setApiKey(apiKey);
  return fromEmail;
};

export const onSupportMessageCreate = onDocumentCreated(
  {
    document: "supportMessages/{docId}",
    secrets: ["SENDGRID_API_KEY"],
  },
  async (event) => {
    const data = event.data?.data() as SupportMessage | undefined;
    if (!data) {
      logWarn("Support message missing data payload.", {
        document: event.params.docId,
      });
      return;
    }

    const messageText = data.message?.trim();
    if (!messageText) {
      logWarn("Support message missing required message field.", {
        document: event.params.docId,
      });
      return;
    }

    const apiKey = process.env.SENDGRID_API_KEY;
    if (!apiKey) {
      logError("SENDGRID_API_KEY is not configured.");
      return;
    }

    sgMail.setApiKey(apiKey);

    const emailBody = buildEmailBody({ ...data, message: messageText }, event.params.docId);

    try {
      await sgMail.send({
        to: SUPPORT_EMAIL,
        from: SUPPORT_EMAIL,
        subject: EMAIL_SUBJECT,
        text: emailBody,
        replyTo: data.email ?? undefined,
      });
      logInfo("Support email sent.", { document: event.params.docId });
    } catch (error) {
      logError("Failed to send support email.", {
        document: event.params.docId,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  },
);

export const checkUsername = onCall(async (request) => {
  const username = String(request.data?.username ?? "").trim();
  if (!username || !isValidUsername(username)) {
    throw new HttpsError("invalid-argument", "invalid_username");
  }
  const usernameLower = normalizeUsername(username);
  const doc = await db.doc(`usernames/${usernameLower}`).get();
  if (!doc.exists) {
    return { available: true };
  }
  const data = doc.data() ?? {};
  if (data.uid) {
    return { available: false, reason: "مستعمل" };
  }
  const reservedUntil = data.reservedUntil as Timestamp | undefined;
  if (reservedUntil && reservedUntil.toMillis() > Date.now()) {
    return { available: false, reason: "محجوز مؤقتًا" };
  }
  return { available: true };
});

export const startSignup = onCall(
  {
    secrets: ["SENDGRID_API_KEY", "SENDGRID_FROM_EMAIL"],
  },
  async (request) => {
    const email = String(request.data?.email ?? "").trim();
    const firstName = String(request.data?.firstName ?? "").trim();
    const lastName = String(request.data?.lastName ?? "").trim();
    const username = String(request.data?.username ?? "").trim();

    if (!email || !firstName || !lastName || !username) {
      throw new HttpsError("invalid-argument", "missing_fields");
    }
    if (!isValidEmail(email)) {
      throw new HttpsError("invalid-argument", "invalid_email");
    }
    if (!isValidUsername(username)) {
      throw new HttpsError("invalid-argument", "invalid_username");
    }

    const usernameLower = normalizeUsername(username);
    const sessionId = randomUUID();
    const now = Timestamp.now();
    const expiresAt = Timestamp.fromMillis(
      now.toMillis() + OTP_TTL_MINUTES * 60 * 1000,
    );
    const reservedUntil = Timestamp.fromMillis(
      now.toMillis() + USERNAME_RESERVE_MINUTES * 60 * 1000,
    );

    const otp = String(randomInt(100000, 1000000));
    const otpSalt = randomBytes(16).toString("hex");
    const otpHash = hashOtp(otp, otpSalt);

    const sessionRef = db.doc(`signup_sessions/${sessionId}`);
    const usernameRef = db.doc(`usernames/${usernameLower}`);

    await db.runTransaction(async (tx) => {
      const usernameSnap = await tx.get(usernameRef);
      if (usernameSnap.exists) {
        const data = usernameSnap.data() ?? {};
        if (data.uid) {
          throw new HttpsError("already-exists", "username_taken");
        }
        const existingReservedUntil = data.reservedUntil as Timestamp | undefined;
        if (
          data.reserved === true &&
          existingReservedUntil &&
          existingReservedUntil.toMillis() > now.toMillis()
        ) {
          throw new HttpsError("already-exists", "username_taken");
        }
      }

      tx.set(usernameRef, {
        reserved: true,
        reservedAt: now,
        reservedUntil,
        sessionId,
      });

      const sessionPayload: SignupSession = {
        email,
        firstName,
        lastName,
        usernameLower,
        otpHash,
        otpSalt,
        expiresAt,
        attempts: 0,
        resendCount: 0,
        status: "pending",
        createdAt: now,
        lastSentAt: now,
      };

      tx.set(sessionRef, sessionPayload);
    });

    try {
      const fromEmail = ensureSendgridConfigured();
      await sgMail.send({
        to: email,
        from: fromEmail,
        subject: OTP_EMAIL_SUBJECT,
        text: buildOtpEmailText(otp),
      });
    } catch (error) {
      logError("Failed to send OTP email.", {
        error: error instanceof Error ? error.message : String(error),
      });
      await db.runTransaction(async (tx) => {
        const usernameSnap = await tx.get(usernameRef);
        if (usernameSnap.exists && usernameSnap.data()?.sessionId === sessionId) {
          tx.delete(usernameRef);
        }
        tx.delete(sessionRef);
      });
      throw new HttpsError("internal", "otp_send_failed");
    }

    return {
      sessionId,
      expiresInSeconds: OTP_TTL_MINUTES * 60,
      cooldownSeconds: OTP_RESEND_COOLDOWN_SECONDS,
    };
  },
);

export const resendOtp = onCall(
  {
    secrets: ["SENDGRID_API_KEY", "SENDGRID_FROM_EMAIL"],
  },
  async (request) => {
    const sessionId = String(request.data?.sessionId ?? "").trim();
    if (!sessionId) {
      throw new HttpsError("invalid-argument", "missing_session");
    }
    const sessionRef = db.doc(`signup_sessions/${sessionId}`);
    const now = Timestamp.now();
    let otpToSend = "";
    let recipientEmail = "";

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(sessionRef);
      if (!snap.exists) {
        throw new HttpsError("not-found", "session_not_found");
      }
      const data = snap.data() as SignupSession;
      if (data.status !== "pending") {
        throw new HttpsError("failed-precondition", "session_not_pending");
      }
      if (data.expiresAt.toMillis() <= now.toMillis()) {
        tx.update(sessionRef, { status: "expired" });
        throw new HttpsError("failed-precondition", "otp_expired");
      }
      const resendCount = data.resendCount ?? 0;
      if (resendCount >= OTP_RESEND_LIMIT) {
        throw new HttpsError("resource-exhausted", "resend_limit");
      }
      const lastSentAt = data.lastSentAt;
      if (
        lastSentAt &&
        now.toMillis() - lastSentAt.toMillis() <
          OTP_RESEND_COOLDOWN_SECONDS * 1000
      ) {
        throw new HttpsError("failed-precondition", "cooldown_active");
      }

      otpToSend = String(randomInt(100000, 1000000));
      const salt = randomBytes(16).toString("hex");
      const hash = hashOtp(otpToSend, salt);
      const newExpiresAt = Timestamp.fromMillis(
        now.toMillis() + OTP_TTL_MINUTES * 60 * 1000,
      );

      tx.update(sessionRef, {
        otpHash: hash,
        otpSalt: salt,
        expiresAt: newExpiresAt,
        resendCount: resendCount + 1,
        lastSentAt: now,
      });

      recipientEmail = data.email;
    });

    const fromEmail = ensureSendgridConfigured();
    await sgMail.send({
      to: recipientEmail,
      from: fromEmail,
      subject: OTP_EMAIL_SUBJECT,
      text: buildOtpEmailText(otpToSend),
    });

    return {
      ok: true,
      cooldownSeconds: OTP_RESEND_COOLDOWN_SECONDS,
      expiresInSeconds: OTP_TTL_MINUTES * 60,
    };
  },
);

export const sendEmailVerificationOtp = onCall(
  {
    secrets: ["SENDGRID_API_KEY", "SENDGRID_FROM_EMAIL"],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "auth_required");
    }
    const email = String(
      request.data?.email ?? request.auth.token.email ?? "",
    ).trim();
    if (!email || !isValidEmail(email)) {
      throw new HttpsError("invalid-argument", "invalid_email");
    }

    const uid = request.auth.uid;
    const otpRef = db.doc(`email_verification_otps/${uid}`);
    const now = Timestamp.now();
    const snap = await otpRef.get();
    const existing = snap.data();

    const resendCount = (existing?.resendCount as number | undefined) ?? 0;
    if (resendCount >= OTP_RESEND_LIMIT) {
      throw new HttpsError("resource-exhausted", "resend_limit");
    }
    const lastSentAt = existing?.lastSentAt as Timestamp | undefined;
    if (
      lastSentAt &&
      now.toMillis() - lastSentAt.toMillis() <
        OTP_RESEND_COOLDOWN_SECONDS * 1000
    ) {
      throw new HttpsError("failed-precondition", "cooldown_active");
    }

    const otp = String(randomInt(100000, 1000000));
    const otpSalt = randomBytes(16).toString("hex");
    const otpHash = hashOtp(otp, otpSalt);
    const expiresAt = Timestamp.fromMillis(
      now.toMillis() + OTP_TTL_MINUTES * 60 * 1000,
    );

    await otpRef.set(
      {
        email,
        otpHash,
        otpSalt,
        expiresAt,
        resendCount: resendCount + 1,
        lastSentAt: now,
        createdAt: existing?.createdAt ?? now,
      },
      { merge: true },
    );

    const fromEmail = ensureSendgridConfigured();
    await sgMail.send({
      to: email,
      from: fromEmail,
      subject: OTP_EMAIL_SUBJECT,
      text: buildOtpEmailText(otp),
    });

    return {
      ok: true,
      cooldownSeconds: OTP_RESEND_COOLDOWN_SECONDS,
      expiresInSeconds: OTP_TTL_MINUTES * 60,
    };
  },
);


export const startLoginTwoFactor = onCall(
  {
    secrets: ["SENDGRID_API_KEY", "SENDGRID_FROM_EMAIL"],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "auth_required");
    }

    const uid = request.auth.uid;
    const email = String(request.auth.token.email ?? "").trim();
    if (!email || !isValidEmail(email)) {
      throw new HttpsError("failed-precondition", "invalid_email");
    }

    const challengeRef = db.doc(`login_2fa_challenges/${uid}`);
    const now = Timestamp.now();
    const snap = await challengeRef.get();
    const existing = snap.data() as Record<string, unknown> | undefined;

    const lockedUntil = existing?.lockedUntil as Timestamp | undefined;
    if (lockedUntil && lockedUntil.toMillis() > now.toMillis()) {
      throw new HttpsError("failed-precondition", "otp_attempts_exceeded");
    }

    const lastSentAt = existing?.lastSentAt as Timestamp | undefined;
    if (
      lastSentAt &&
      now.toMillis() - lastSentAt.toMillis() <
        LOGIN_2FA_RESEND_COOLDOWN_SECONDS * 1000
    ) {
      throw new HttpsError("failed-precondition", "cooldown_active");
    }

    const otp = String(randomInt(100000, 1000000));
    const otpSalt = randomBytes(16).toString("hex");
    const otpHash = hashOtp(otp, otpSalt);
    const expiresAt = Timestamp.fromMillis(
      now.toMillis() + LOGIN_2FA_TTL_MINUTES * 60 * 1000,
    );

    await challengeRef.set(
      {
        uid,
        email,
        otpHash,
        otpSalt,
        expiresAt,
        attempts: 0,
        lastSentAt: now,
        createdAt: now,
        verifiedAt: FieldValue.delete(),
        lockedUntil: FieldValue.delete(),
      },
      { merge: true },
    );

    try {
      const fromEmail = ensureSendgridConfigured();
      await sgMail.send({
        to: email,
        from: fromEmail,
        subject: OTP_EMAIL_SUBJECT,
        text: buildOtpEmailText(otp),
      });
    } catch (_error) {
      throw new HttpsError("internal", "otp_send_failed");
    }

    return {
      ok: true,
      cooldownSeconds: LOGIN_2FA_RESEND_COOLDOWN_SECONDS,
      expiresInSeconds: LOGIN_2FA_TTL_MINUTES * 60,
      remainingAttempts: LOGIN_2FA_ATTEMPT_LIMIT,
      lockedForSeconds: 0,
    };
  },
);

export const resendLoginTwoFactor = onCall(
  {
    secrets: ["SENDGRID_API_KEY", "SENDGRID_FROM_EMAIL"],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "auth_required");
    }

    const uid = request.auth.uid;
    const challengeRef = db.doc(`login_2fa_challenges/${uid}`);
    const now = Timestamp.now();
    const snap = await challengeRef.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "challenge_not_found");
    }

    const data = snap.data() as Record<string, unknown>;
    const lockedUntil = data.lockedUntil as Timestamp | undefined;
    if (lockedUntil && lockedUntil.toMillis() > now.toMillis()) {
      throw new HttpsError("failed-precondition", "otp_attempts_exceeded");
    }

    const lastSentAt = data.lastSentAt as Timestamp | undefined;
    if (
      lastSentAt &&
      now.toMillis() - lastSentAt.toMillis() <
        LOGIN_2FA_RESEND_COOLDOWN_SECONDS * 1000
    ) {
      throw new HttpsError("failed-precondition", "cooldown_active");
    }

    const email = String(data.email ?? request.auth.token.email ?? "").trim();
    if (!email || !isValidEmail(email)) {
      throw new HttpsError("failed-precondition", "invalid_email");
    }

    const otp = String(randomInt(100000, 1000000));
    const otpSalt = randomBytes(16).toString("hex");
    const otpHash = hashOtp(otp, otpSalt);
    const expiresAt = Timestamp.fromMillis(
      now.toMillis() + LOGIN_2FA_TTL_MINUTES * 60 * 1000,
    );

    await challengeRef.set(
      {
        otpHash,
        otpSalt,
        expiresAt,
        attempts: 0,
        lastSentAt: now,
        verifiedAt: FieldValue.delete(),
      },
      { merge: true },
    );

    try {
      const fromEmail = ensureSendgridConfigured();
      await sgMail.send({
        to: email,
        from: fromEmail,
        subject: OTP_EMAIL_SUBJECT,
        text: buildOtpEmailText(otp),
      });
    } catch (_error) {
      throw new HttpsError("internal", "otp_send_failed");
    }

    return {
      ok: true,
      cooldownSeconds: LOGIN_2FA_RESEND_COOLDOWN_SECONDS,
      expiresInSeconds: LOGIN_2FA_TTL_MINUTES * 60,
      remainingAttempts: LOGIN_2FA_ATTEMPT_LIMIT,
      lockedForSeconds: 0,
    };
  },
);

export const verifyLoginTwoFactor = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "auth_required");
  }

  const code = String(request.data?.code ?? "").trim();
  if (!/^\d{6}$/.test(code)) {
    throw new HttpsError("invalid-argument", "otp_invalid");
  }

  const uid = request.auth.uid;
  const challengeRef = db.doc(`login_2fa_challenges/${uid}`);
  const now = Timestamp.now();

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(challengeRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "challenge_not_found");
    }

    const data = snap.data() as Record<string, unknown>;
    const lockedUntil = data.lockedUntil as Timestamp | undefined;
    if (lockedUntil && lockedUntil.toMillis() > now.toMillis()) {
      throw new HttpsError("failed-precondition", "otp_attempts_exceeded");
    }

    const expiresAt = data.expiresAt as Timestamp | undefined;
    if (!expiresAt || expiresAt.toMillis() <= now.toMillis()) {
      throw new HttpsError("failed-precondition", "otp_expired");
    }

    const attempts = (data.attempts as number | undefined) ?? 0;
    const otpSalt = String(data.otpSalt ?? "");
    const otpHash = String(data.otpHash ?? "");

    if (hashOtp(code, otpSalt) !== otpHash) {
      const nextAttempts = attempts + 1;
      if (nextAttempts >= LOGIN_2FA_ATTEMPT_LIMIT) {
        tx.update(challengeRef, {
          attempts: nextAttempts,
          lockedUntil: Timestamp.fromMillis(
            now.toMillis() + LOGIN_2FA_LOCK_MINUTES * 60 * 1000,
          ),
        });
        throw new HttpsError("failed-precondition", "otp_attempts_exceeded");
      }
      tx.update(challengeRef, { attempts: nextAttempts });
      throw new HttpsError("permission-denied", "otp_invalid");
    }

    tx.delete(challengeRef);
  });

  return { ok: true };
});

export const verifyOtpAndCreateAccount = onCall(async (request) => {
  const sessionId = String(request.data?.sessionId ?? "").trim();
  const otp = String(request.data?.otp ?? "").trim();
  const password = String(request.data?.password ?? "").trim();

  if (!sessionId || !otp || !password) {
    throw new HttpsError("invalid-argument", "missing_fields");
  }
  if (password.length < 6) {
    throw new HttpsError("invalid-argument", "weak_password");
  }

  const sessionRef = db.doc(`signup_sessions/${sessionId}`);
  const sessionSnap = await sessionRef.get();
  if (!sessionSnap.exists) {
    throw new HttpsError("not-found", "session_not_found");
  }
  const session = sessionSnap.data() as SignupSession;
  const now = Timestamp.now();

  if (session.status !== "pending") {
    throw new HttpsError("failed-precondition", "session_not_pending");
  }
  if (session.expiresAt.toMillis() <= now.toMillis()) {
    await sessionRef.update({ status: "expired" });
    throw new HttpsError("failed-precondition", "otp_expired");
  }
  if ((session.attempts ?? 0) >= OTP_ATTEMPT_LIMIT) {
    throw new HttpsError("failed-precondition", "otp_attempts_exceeded");
  }

  const otpHash = hashOtp(otp, session.otpSalt);
  if (otpHash !== session.otpHash) {
    await sessionRef.update({
      attempts: FieldValue.increment(1),
    });
    throw new HttpsError("permission-denied", "otp_invalid");
  }

  let userRecord;
  try {
    userRecord = await auth.createUser({
      email: session.email,
      password,
      displayName: `${session.firstName} ${session.lastName}`.trim(),
    });
  } catch (error) {
    const authError = error as { code?: string; message?: string };
    if (authError.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "email_in_use");
    }
    if (authError.message?.includes("email")) {
      throw new HttpsError("already-exists", "email_in_use");
    }
    throw new HttpsError("internal", "auth_create_failed");
  }

  const userId = userRecord.uid;
  const userRef = db.doc(`users/${userId}`);
  const usernameRef = db.doc(`usernames/${session.usernameLower}`);

  try {
    await db.runTransaction(async (tx) => {
      const usernameSnap = await tx.get(usernameRef);
      if (!usernameSnap.exists) {
        throw new HttpsError("failed-precondition", "username_missing");
      }
      const usernameData = usernameSnap.data() ?? {};
      if (usernameData.uid) {
        throw new HttpsError("already-exists", "username_taken");
      }
      if (usernameData.sessionId !== sessionId) {
        throw new HttpsError("failed-precondition", "username_not_reserved");
      }

      tx.set(userRef, {
        firstName: session.firstName,
        lastName: session.lastName,
        username: session.usernameLower,
        email: session.email,
        createdAt: FieldValue.serverTimestamp(),
      });

      tx.set(usernameRef, {
        uid: userId,
        createdAt: FieldValue.serverTimestamp(),
      });

      tx.update(sessionRef, {
        status: "verified",
        verifiedAt: FieldValue.serverTimestamp(),
        uid: userId,
      });
    });
  } catch (error) {
    logError("Failed to finalize signup session.", {
      error: error instanceof Error ? error.message : String(error),
    });
    await auth.deleteUser(userId);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "signup_finalize_failed");
  }

  const customToken = await auth.createCustomToken(userId);
  return { customToken };
});
