"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserDeleted = exports.verifyOtpAndCreateAccount = exports.verifyLoginTwoFactor = exports.resendLoginTwoFactor = exports.startLoginTwoFactor = exports.sendEmailVerificationOtp = exports.resendOtp = exports.startSignup = exports.checkUsername = exports.onSupportMessageCreate = exports.helloWorld = void 0;
const crypto_1 = require("crypto");
const app_1 = require("firebase-admin/app");
const auth_1 = require("firebase-admin/auth");
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const firestore_2 = require("firebase-functions/v2/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const logger_1 = require("firebase-functions/logger");
const mail_1 = __importDefault(require("@sendgrid/mail"));
const storage_1 = require("firebase-admin/storage");
const functionsV1 = __importStar(require("firebase-functions/v1"));
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
const auth = (0, auth_1.getAuth)();
const SUPPORT_EMAIL = "unispace.0.1.0@gmail.com";
const EMAIL_SUBJECT = "[UniSpace] New Contact Message";
const OTP_EMAIL_SUBJECT = "رمز التحقق UniSpace";
const OTP_TTL_MINUTES = 10;
const OTP_ATTEMPT_LIMIT = 5;
const OTP_RESEND_LIMIT = 3;
const OTP_RESEND_COOLDOWN_SECONDS = 60;
const USERNAME_RESERVE_MINUTES = 15;
exports.helloWorld = (0, https_1.onRequest)((req, res) => {
    logger.info("helloWorld function invoked", { path: req.path, method: req.method });
    res.send("Hello from Firebase!");
});
const LOGIN_2FA_TTL_MINUTES = 5;
const LOGIN_2FA_ATTEMPT_LIMIT = 5;
const LOGIN_2FA_RESEND_COOLDOWN_SECONDS = 30;
const LOGIN_2FA_LOCK_MINUTES = 5;
const getCreatedAt = (createdAt) => {
    var _a;
    if (createdAt && typeof createdAt === "object" && "toDate" in createdAt) {
        const date = (_a = createdAt.toDate) === null || _a === void 0 ? void 0 : _a.call(createdAt);
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
const buildEmailBody = (data, docId) => {
    var _a, _b, _c, _d, _e;
    const deviceInfo = (_a = data.deviceInfo) !== null && _a !== void 0 ? _a : {};
    return [
        `Document ID: ${docId}`,
        `Name: ${(_b = data.name) !== null && _b !== void 0 ? _b : "-"}`,
        `Email: ${(_c = data.email) !== null && _c !== void 0 ? _c : "-"}`,
        `Created At: ${getCreatedAt((_d = data.createdAt) !== null && _d !== void 0 ? _d : null)}`,
        "",
        "Message:",
        (_e = data.message) !== null && _e !== void 0 ? _e : "-",
        "",
        "Device Info:",
        JSON.stringify(deviceInfo, null, 2),
    ].join("\n");
};
const isValidEmail = (email) => {
    return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
};
const normalizeUsername = (username) => {
    return username.trim().toLowerCase();
};
const isValidUsername = (username) => {
    return /^[a-zA-Z0-9_]{3,20}$/.test(username);
};
const hashOtp = (otp, salt) => {
    return (0, crypto_1.createHash)("sha256").update(`${otp}${salt}`).digest("hex");
};
const buildOtpEmailText = (otp) => {
    return [
        "مرحبًا بك في UniSpace!",
        "",
        `رمز التحقق الخاص بك هو: ${otp}`,
        `صلاحية الرمز ${OTP_TTL_MINUTES} دقائق.`,
        "",
        "إذا لم تقم بطلب هذا الرمز، تجاهل هذه الرسالة.",
    ].join("\n");
};
const ensureSendgridConfigured = () => {
    const apiKey = process.env.SENDGRID_API_KEY;
    const fromEmail = process.env.SENDGRID_FROM_EMAIL;
    if (!apiKey || !fromEmail) {
        throw new https_1.HttpsError("failed-precondition", "sendgrid_not_configured");
    }
    mail_1.default.setApiKey(apiKey);
    return fromEmail;
};
exports.onSupportMessageCreate = (0, firestore_2.onDocumentCreated)({
    document: "supportMessages/{docId}",
    secrets: ["SENDGRID_API_KEY"],
}, async (event) => {
    var _a, _b, _c;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data) {
        (0, logger_1.warn)("Support message missing data payload.", {
            document: event.params.docId,
        });
        return;
    }
    const messageText = (_b = data.message) === null || _b === void 0 ? void 0 : _b.trim();
    if (!messageText) {
        (0, logger_1.warn)("Support message missing required message field.", {
            document: event.params.docId,
        });
        return;
    }
    const apiKey = process.env.SENDGRID_API_KEY;
    if (!apiKey) {
        (0, logger_1.error)("SENDGRID_API_KEY is not configured.");
        return;
    }
    mail_1.default.setApiKey(apiKey);
    const emailBody = buildEmailBody({ ...data, message: messageText }, event.params.docId);
    try {
        await mail_1.default.send({
            to: SUPPORT_EMAIL,
            from: SUPPORT_EMAIL,
            subject: EMAIL_SUBJECT,
            text: emailBody,
            replyTo: (_c = data.email) !== null && _c !== void 0 ? _c : undefined,
        });
        (0, logger_1.info)("Support email sent.", { document: event.params.docId });
    }
    catch (error) {
        (0, logger_1.error)("Failed to send support email.", {
            document: event.params.docId,
            error: error instanceof Error ? error.message : String(error),
        });
    }
});
exports.checkUsername = (0, https_1.onCall)(async (request) => {
    var _a, _b, _c;
    const username = String((_b = (_a = request.data) === null || _a === void 0 ? void 0 : _a.username) !== null && _b !== void 0 ? _b : "").trim();
    if (!username || !isValidUsername(username)) {
        throw new https_1.HttpsError("invalid-argument", "invalid_username");
    }
    const usernameLower = normalizeUsername(username);
    const doc = await db.doc(`usernames/${usernameLower}`).get();
    if (!doc.exists) {
        return { available: true };
    }
    const data = (_c = doc.data()) !== null && _c !== void 0 ? _c : {};
    if (data.uid) {
        return { available: false, reason: "مستعمل" };
    }
    const reservedUntil = data.reservedUntil;
    if (reservedUntil && reservedUntil.toMillis() > Date.now()) {
        return { available: false, reason: "محجوز مؤقتًا" };
    }
    return { available: true };
});
exports.startSignup = (0, https_1.onCall)({
    secrets: ["SENDGRID_API_KEY", "SENDGRID_FROM_EMAIL"],
}, async (request) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const email = String((_b = (_a = request.data) === null || _a === void 0 ? void 0 : _a.email) !== null && _b !== void 0 ? _b : "").trim();
    const firstName = String((_d = (_c = request.data) === null || _c === void 0 ? void 0 : _c.firstName) !== null && _d !== void 0 ? _d : "").trim();
    const lastName = String((_f = (_e = request.data) === null || _e === void 0 ? void 0 : _e.lastName) !== null && _f !== void 0 ? _f : "").trim();
    const username = String((_h = (_g = request.data) === null || _g === void 0 ? void 0 : _g.username) !== null && _h !== void 0 ? _h : "").trim();
    if (!email || !firstName || !lastName || !username) {
        throw new https_1.HttpsError("invalid-argument", "missing_fields");
    }
    if (!isValidEmail(email)) {
        throw new https_1.HttpsError("invalid-argument", "invalid_email");
    }
    if (!isValidUsername(username)) {
        throw new https_1.HttpsError("invalid-argument", "invalid_username");
    }
    const usernameLower = normalizeUsername(username);
    const sessionId = (0, crypto_1.randomUUID)();
    const now = firestore_1.Timestamp.now();
    const expiresAt = firestore_1.Timestamp.fromMillis(now.toMillis() + OTP_TTL_MINUTES * 60 * 1000);
    const reservedUntil = firestore_1.Timestamp.fromMillis(now.toMillis() + USERNAME_RESERVE_MINUTES * 60 * 1000);
    const otp = String((0, crypto_1.randomInt)(100000, 1000000));
    const otpSalt = (0, crypto_1.randomBytes)(16).toString("hex");
    const otpHash = hashOtp(otp, otpSalt);
    const sessionRef = db.doc(`signup_sessions/${sessionId}`);
    const usernameRef = db.doc(`usernames/${usernameLower}`);
    await db.runTransaction(async (tx) => {
        var _a;
        const usernameSnap = await tx.get(usernameRef);
        if (usernameSnap.exists) {
            const data = (_a = usernameSnap.data()) !== null && _a !== void 0 ? _a : {};
            if (data.uid) {
                throw new https_1.HttpsError("already-exists", "username_taken");
            }
            const existingReservedUntil = data.reservedUntil;
            if (data.reserved === true &&
                existingReservedUntil &&
                existingReservedUntil.toMillis() > now.toMillis()) {
                throw new https_1.HttpsError("already-exists", "username_taken");
            }
        }
        tx.set(usernameRef, {
            reserved: true,
            reservedAt: now,
            reservedUntil,
            sessionId,
        });
        const sessionPayload = {
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
        await mail_1.default.send({
            to: email,
            from: fromEmail,
            subject: OTP_EMAIL_SUBJECT,
            text: buildOtpEmailText(otp),
        });
    }
    catch (error) {
        (0, logger_1.error)("Failed to send OTP email.", {
            error: error instanceof Error ? error.message : String(error),
        });
        await db.runTransaction(async (tx) => {
            var _a;
            const usernameSnap = await tx.get(usernameRef);
            if (usernameSnap.exists && ((_a = usernameSnap.data()) === null || _a === void 0 ? void 0 : _a.sessionId) === sessionId) {
                tx.delete(usernameRef);
            }
            tx.delete(sessionRef);
        });
        throw new https_1.HttpsError("internal", "otp_send_failed");
    }
    return {
        sessionId,
        expiresInSeconds: OTP_TTL_MINUTES * 60,
        cooldownSeconds: OTP_RESEND_COOLDOWN_SECONDS,
    };
});
exports.resendOtp = (0, https_1.onCall)({
    secrets: ["SENDGRID_API_KEY", "SENDGRID_FROM_EMAIL"],
}, async (request) => {
    var _a, _b;
    const sessionId = String((_b = (_a = request.data) === null || _a === void 0 ? void 0 : _a.sessionId) !== null && _b !== void 0 ? _b : "").trim();
    if (!sessionId) {
        throw new https_1.HttpsError("invalid-argument", "missing_session");
    }
    const sessionRef = db.doc(`signup_sessions/${sessionId}`);
    const now = firestore_1.Timestamp.now();
    let otpToSend = "";
    let recipientEmail = "";
    await db.runTransaction(async (tx) => {
        var _a;
        const snap = await tx.get(sessionRef);
        if (!snap.exists) {
            throw new https_1.HttpsError("not-found", "session_not_found");
        }
        const data = snap.data();
        if (data.status !== "pending") {
            throw new https_1.HttpsError("failed-precondition", "session_not_pending");
        }
        if (data.expiresAt.toMillis() <= now.toMillis()) {
            tx.update(sessionRef, { status: "expired" });
            throw new https_1.HttpsError("failed-precondition", "otp_expired");
        }
        const resendCount = (_a = data.resendCount) !== null && _a !== void 0 ? _a : 0;
        if (resendCount >= OTP_RESEND_LIMIT) {
            throw new https_1.HttpsError("resource-exhausted", "resend_limit");
        }
        const lastSentAt = data.lastSentAt;
        if (lastSentAt &&
            now.toMillis() - lastSentAt.toMillis() <
                OTP_RESEND_COOLDOWN_SECONDS * 1000) {
            throw new https_1.HttpsError("failed-precondition", "cooldown_active");
        }
        otpToSend = String((0, crypto_1.randomInt)(100000, 1000000));
        const salt = (0, crypto_1.randomBytes)(16).toString("hex");
        const hash = hashOtp(otpToSend, salt);
        const newExpiresAt = firestore_1.Timestamp.fromMillis(now.toMillis() + OTP_TTL_MINUTES * 60 * 1000);
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
    await mail_1.default.send({
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
});
exports.sendEmailVerificationOtp = (0, https_1.onCall)({
    secrets: ["SENDGRID_API_KEY", "SENDGRID_FROM_EMAIL"],
}, async (request) => {
    var _a, _b, _c, _d, _e;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "auth_required");
    }
    const email = String((_c = (_b = (_a = request.data) === null || _a === void 0 ? void 0 : _a.email) !== null && _b !== void 0 ? _b : request.auth.token.email) !== null && _c !== void 0 ? _c : "").trim();
    if (!email || !isValidEmail(email)) {
        throw new https_1.HttpsError("invalid-argument", "invalid_email");
    }
    const uid = request.auth.uid;
    const otpRef = db.doc(`email_verification_otps/${uid}`);
    const now = firestore_1.Timestamp.now();
    const snap = await otpRef.get();
    const existing = snap.data();
    const resendCount = (_d = existing === null || existing === void 0 ? void 0 : existing.resendCount) !== null && _d !== void 0 ? _d : 0;
    if (resendCount >= OTP_RESEND_LIMIT) {
        throw new https_1.HttpsError("resource-exhausted", "resend_limit");
    }
    const lastSentAt = existing === null || existing === void 0 ? void 0 : existing.lastSentAt;
    if (lastSentAt &&
        now.toMillis() - lastSentAt.toMillis() <
            OTP_RESEND_COOLDOWN_SECONDS * 1000) {
        throw new https_1.HttpsError("failed-precondition", "cooldown_active");
    }
    const otp = String((0, crypto_1.randomInt)(100000, 1000000));
    const otpSalt = (0, crypto_1.randomBytes)(16).toString("hex");
    const otpHash = hashOtp(otp, otpSalt);
    const expiresAt = firestore_1.Timestamp.fromMillis(now.toMillis() + OTP_TTL_MINUTES * 60 * 1000);
    await otpRef.set({
        email,
        otpHash,
        otpSalt,
        expiresAt,
        resendCount: resendCount + 1,
        lastSentAt: now,
        createdAt: (_e = existing === null || existing === void 0 ? void 0 : existing.createdAt) !== null && _e !== void 0 ? _e : now,
    }, { merge: true });
    const fromEmail = ensureSendgridConfigured();
    await mail_1.default.send({
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
});
exports.startLoginTwoFactor = (0, https_1.onCall)({
    secrets: ["SENDGRID_API_KEY", "SENDGRID_FROM_EMAIL"],
}, async (request) => {
    var _a;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "auth_required");
    }
    const uid = request.auth.uid;
    const email = String((_a = request.auth.token.email) !== null && _a !== void 0 ? _a : "").trim();
    if (!email || !isValidEmail(email)) {
        throw new https_1.HttpsError("failed-precondition", "invalid_email");
    }
    const challengeRef = db.doc(`login_2fa_challenges/${uid}`);
    const now = firestore_1.Timestamp.now();
    const snap = await challengeRef.get();
    const existing = snap.data();
    const lockedUntil = existing === null || existing === void 0 ? void 0 : existing.lockedUntil;
    if (lockedUntil && lockedUntil.toMillis() > now.toMillis()) {
        throw new https_1.HttpsError("failed-precondition", "otp_attempts_exceeded");
    }
    const lastSentAt = existing === null || existing === void 0 ? void 0 : existing.lastSentAt;
    if (lastSentAt &&
        now.toMillis() - lastSentAt.toMillis() <
            LOGIN_2FA_RESEND_COOLDOWN_SECONDS * 1000) {
        throw new https_1.HttpsError("failed-precondition", "cooldown_active");
    }
    const otp = String((0, crypto_1.randomInt)(100000, 1000000));
    const otpSalt = (0, crypto_1.randomBytes)(16).toString("hex");
    const otpHash = hashOtp(otp, otpSalt);
    const expiresAt = firestore_1.Timestamp.fromMillis(now.toMillis() + LOGIN_2FA_TTL_MINUTES * 60 * 1000);
    await challengeRef.set({
        uid,
        email,
        otpHash,
        otpSalt,
        expiresAt,
        attempts: 0,
        lastSentAt: now,
        createdAt: now,
        verifiedAt: firestore_1.FieldValue.delete(),
        lockedUntil: firestore_1.FieldValue.delete(),
    }, { merge: true });
    try {
        const fromEmail = ensureSendgridConfigured();
        await mail_1.default.send({
            to: email,
            from: fromEmail,
            subject: OTP_EMAIL_SUBJECT,
            text: buildOtpEmailText(otp),
        });
    }
    catch (_error) {
        throw new https_1.HttpsError("internal", "otp_send_failed");
    }
    return {
        ok: true,
        cooldownSeconds: LOGIN_2FA_RESEND_COOLDOWN_SECONDS,
        expiresInSeconds: LOGIN_2FA_TTL_MINUTES * 60,
        remainingAttempts: LOGIN_2FA_ATTEMPT_LIMIT,
        lockedForSeconds: 0,
    };
});
exports.resendLoginTwoFactor = (0, https_1.onCall)({
    secrets: ["SENDGRID_API_KEY", "SENDGRID_FROM_EMAIL"],
}, async (request) => {
    var _a, _b;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "auth_required");
    }
    const uid = request.auth.uid;
    const challengeRef = db.doc(`login_2fa_challenges/${uid}`);
    const now = firestore_1.Timestamp.now();
    const snap = await challengeRef.get();
    if (!snap.exists) {
        throw new https_1.HttpsError("not-found", "challenge_not_found");
    }
    const data = snap.data();
    const lockedUntil = data.lockedUntil;
    if (lockedUntil && lockedUntil.toMillis() > now.toMillis()) {
        throw new https_1.HttpsError("failed-precondition", "otp_attempts_exceeded");
    }
    const lastSentAt = data.lastSentAt;
    if (lastSentAt &&
        now.toMillis() - lastSentAt.toMillis() <
            LOGIN_2FA_RESEND_COOLDOWN_SECONDS * 1000) {
        throw new https_1.HttpsError("failed-precondition", "cooldown_active");
    }
    const email = String((_b = (_a = data.email) !== null && _a !== void 0 ? _a : request.auth.token.email) !== null && _b !== void 0 ? _b : "").trim();
    if (!email || !isValidEmail(email)) {
        throw new https_1.HttpsError("failed-precondition", "invalid_email");
    }
    const otp = String((0, crypto_1.randomInt)(100000, 1000000));
    const otpSalt = (0, crypto_1.randomBytes)(16).toString("hex");
    const otpHash = hashOtp(otp, otpSalt);
    const expiresAt = firestore_1.Timestamp.fromMillis(now.toMillis() + LOGIN_2FA_TTL_MINUTES * 60 * 1000);
    await challengeRef.set({
        otpHash,
        otpSalt,
        expiresAt,
        attempts: 0,
        lastSentAt: now,
        verifiedAt: firestore_1.FieldValue.delete(),
    }, { merge: true });
    try {
        const fromEmail = ensureSendgridConfigured();
        await mail_1.default.send({
            to: email,
            from: fromEmail,
            subject: OTP_EMAIL_SUBJECT,
            text: buildOtpEmailText(otp),
        });
    }
    catch (_error) {
        throw new https_1.HttpsError("internal", "otp_send_failed");
    }
    return {
        ok: true,
        cooldownSeconds: LOGIN_2FA_RESEND_COOLDOWN_SECONDS,
        expiresInSeconds: LOGIN_2FA_TTL_MINUTES * 60,
        remainingAttempts: LOGIN_2FA_ATTEMPT_LIMIT,
        lockedForSeconds: 0,
    };
});
exports.verifyLoginTwoFactor = (0, https_1.onCall)(async (request) => {
    var _a, _b;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "auth_required");
    }
    const code = String((_b = (_a = request.data) === null || _a === void 0 ? void 0 : _a.code) !== null && _b !== void 0 ? _b : "").trim();
    if (!/^\d{6}$/.test(code)) {
        throw new https_1.HttpsError("invalid-argument", "otp_invalid");
    }
    const uid = request.auth.uid;
    const challengeRef = db.doc(`login_2fa_challenges/${uid}`);
    const now = firestore_1.Timestamp.now();
    await db.runTransaction(async (tx) => {
        var _a, _b, _c;
        const snap = await tx.get(challengeRef);
        if (!snap.exists) {
            throw new https_1.HttpsError("not-found", "challenge_not_found");
        }
        const data = snap.data();
        const lockedUntil = data.lockedUntil;
        if (lockedUntil && lockedUntil.toMillis() > now.toMillis()) {
            throw new https_1.HttpsError("failed-precondition", "otp_attempts_exceeded");
        }
        const expiresAt = data.expiresAt;
        if (!expiresAt || expiresAt.toMillis() <= now.toMillis()) {
            throw new https_1.HttpsError("failed-precondition", "otp_expired");
        }
        const attempts = (_a = data.attempts) !== null && _a !== void 0 ? _a : 0;
        const otpSalt = String((_b = data.otpSalt) !== null && _b !== void 0 ? _b : "");
        const otpHash = String((_c = data.otpHash) !== null && _c !== void 0 ? _c : "");
        if (hashOtp(code, otpSalt) !== otpHash) {
            const nextAttempts = attempts + 1;
            if (nextAttempts >= LOGIN_2FA_ATTEMPT_LIMIT) {
                tx.update(challengeRef, {
                    attempts: nextAttempts,
                    lockedUntil: firestore_1.Timestamp.fromMillis(now.toMillis() + LOGIN_2FA_LOCK_MINUTES * 60 * 1000),
                });
                throw new https_1.HttpsError("failed-precondition", "otp_attempts_exceeded");
            }
            tx.update(challengeRef, { attempts: nextAttempts });
            throw new https_1.HttpsError("permission-denied", "otp_invalid");
        }
        tx.delete(challengeRef);
    });
    return { ok: true };
});
exports.verifyOtpAndCreateAccount = (0, https_1.onCall)(async (request) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const sessionId = String((_b = (_a = request.data) === null || _a === void 0 ? void 0 : _a.sessionId) !== null && _b !== void 0 ? _b : "").trim();
    const otp = String((_d = (_c = request.data) === null || _c === void 0 ? void 0 : _c.otp) !== null && _d !== void 0 ? _d : "").trim();
    const password = String((_f = (_e = request.data) === null || _e === void 0 ? void 0 : _e.password) !== null && _f !== void 0 ? _f : "").trim();
    if (!sessionId || !otp || !password) {
        throw new https_1.HttpsError("invalid-argument", "missing_fields");
    }
    if (password.length < 6) {
        throw new https_1.HttpsError("invalid-argument", "weak_password");
    }
    const sessionRef = db.doc(`signup_sessions/${sessionId}`);
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) {
        throw new https_1.HttpsError("not-found", "session_not_found");
    }
    const session = sessionSnap.data();
    const now = firestore_1.Timestamp.now();
    if (session.status !== "pending") {
        throw new https_1.HttpsError("failed-precondition", "session_not_pending");
    }
    if (session.expiresAt.toMillis() <= now.toMillis()) {
        await sessionRef.update({ status: "expired" });
        throw new https_1.HttpsError("failed-precondition", "otp_expired");
    }
    if (((_g = session.attempts) !== null && _g !== void 0 ? _g : 0) >= OTP_ATTEMPT_LIMIT) {
        throw new https_1.HttpsError("failed-precondition", "otp_attempts_exceeded");
    }
    const otpHash = hashOtp(otp, session.otpSalt);
    if (otpHash !== session.otpHash) {
        await sessionRef.update({
            attempts: firestore_1.FieldValue.increment(1),
        });
        throw new https_1.HttpsError("permission-denied", "otp_invalid");
    }
    let userRecord;
    try {
        userRecord = await auth.createUser({
            email: session.email,
            password,
            displayName: `${session.firstName} ${session.lastName}`.trim(),
        });
    }
    catch (error) {
        const authError = error;
        if (authError.code === "auth/email-already-exists") {
            throw new https_1.HttpsError("already-exists", "email_in_use");
        }
        if ((_h = authError.message) === null || _h === void 0 ? void 0 : _h.includes("email")) {
            throw new https_1.HttpsError("already-exists", "email_in_use");
        }
        throw new https_1.HttpsError("internal", "auth_create_failed");
    }
    const userId = userRecord.uid;
    const userRef = db.doc(`users/${userId}`);
    const usernameRef = db.doc(`usernames/${session.usernameLower}`);
    try {
        await db.runTransaction(async (tx) => {
            var _a;
            const usernameSnap = await tx.get(usernameRef);
            if (!usernameSnap.exists) {
                throw new https_1.HttpsError("failed-precondition", "username_missing");
            }
            const usernameData = (_a = usernameSnap.data()) !== null && _a !== void 0 ? _a : {};
            if (usernameData.uid) {
                throw new https_1.HttpsError("already-exists", "username_taken");
            }
            if (usernameData.sessionId !== sessionId) {
                throw new https_1.HttpsError("failed-precondition", "username_not_reserved");
            }
            tx.set(userRef, {
                firstName: session.firstName,
                lastName: session.lastName,
                username: session.usernameLower,
                email: session.email,
                createdAt: firestore_1.FieldValue.serverTimestamp(),
            });
            tx.set(usernameRef, {
                uid: userId,
                createdAt: firestore_1.FieldValue.serverTimestamp(),
            });
            tx.update(sessionRef, {
                status: "verified",
                verifiedAt: firestore_1.FieldValue.serverTimestamp(),
                uid: userId,
            });
        });
    }
    catch (error) {
        (0, logger_1.error)("Failed to finalize signup session.", {
            error: error instanceof Error ? error.message : String(error),
        });
        await auth.deleteUser(userId);
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        throw new https_1.HttpsError("internal", "signup_finalize_failed");
    }
    const customToken = await auth.createCustomToken(userId);
    return { customToken };
});
async function deleteCollection(collectionRef) {
    const batchSize = 400;
    for (;;) {
        const snap = await collectionRef.limit(batchSize).get();
        if (snap.empty)
            break;
        const batch = db.batch();
        snap.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        if (snap.size < batchSize)
            break;
    }
}
/**
 * يُستدعى تلقائياً بعد user.delete() من التطبيق
 */
exports.onUserDeleted = functionsV1.auth.user().onDelete(async (user) => {
    var _a, _b;
    const uid = user.uid;
    const email = (user.email || "").trim().toLowerCase();
    const bucket = (0, storage_1.getStorage)().bucket();
    logger.info("onUserDeleted start", { uid, email });
    // منشورات المستخدم — غيّر authorId إن لزم
    try {
        const postsSnap = await db
            .collection("community_posts")
            .where("authorId", "==", uid)
            .get();
        for (const postDoc of postsSnap.docs) {
            const postId = postDoc.id;
            await deleteCollection(db.collection("community_posts").doc(postId).collection("poll_responses"));
            try {
                await bucket.deleteFiles({ prefix: `community_posts/${postId}/` });
            }
            catch (e) {
                (0, logger_1.warn)("storage post cleanup", {
                    postId,
                    error: e instanceof Error ? e.message : String(e),
                });
            }
            await postDoc.ref.delete();
        }
        logger.info("posts deleted", { count: postsSnap.size, uid });
    }
    catch (e) {
        (0, logger_1.error)("posts cleanup failed", {
            uid,
            error: e instanceof Error ? e.message : String(e),
        });
    }
    // username
    try {
        const userDoc = await db.doc(`users/${uid}`).get();
        const username = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.username;
        if (username) {
            const uname = String(username).trim().toLowerCase();
            const unameRef = db.doc(`usernames/${uname}`);
            const unameSnap = await unameRef.get();
            if (unameSnap.exists && ((_b = unameSnap.data()) === null || _b === void 0 ? void 0 : _b.uid) === uid) {
                await unameRef.delete();
            }
        }
        else {
            const byUid = await db
                .collection("usernames")
                .where("uid", "==", uid)
                .limit(5)
                .get();
            for (const d of byUid.docs) {
                await d.ref.delete();
            }
        }
    }
    catch (e) {
        (0, logger_1.warn)("username cleanup", {
            error: e instanceof Error ? e.message : String(e),
        });
    }
    try {
        await deleteCollection(db.collection("users").doc(uid).collection("sessions"));
    }
    catch (_) { }
    try {
        await db.doc(`login_2fa_challenges/${uid}`).delete();
    }
    catch (_) { }
    try {
        await db.doc(`email_verification_otps/${uid}`).delete();
    }
    catch (_) { }
    try {
        await db.doc(`users/${uid}`).delete();
    }
    catch (e) {
        (0, logger_1.warn)("users doc delete", {
            error: e instanceof Error ? e.message : String(e),
        });
    }
    try {
        await bucket.deleteFiles({ prefix: `users/${uid}/` });
    }
    catch (_) { }
    logger.info("onUserDeleted done", { uid });
});
//# sourceMappingURL=index.js.map