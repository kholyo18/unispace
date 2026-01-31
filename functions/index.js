const functions = require('firebase-functions');
const admin = require('firebase-admin');
const sgMail = require('@sendgrid/mail');

admin.initializeApp();

const config = functions.config();
const SUPPORT_EMAIL =
  process.env.SUPPORT_EMAIL || config.support?.email || 'khaledfoll12@gmail.com';
const SUPPORT_FROM_EMAIL =
  process.env.SUPPORT_FROM_EMAIL ||
  config.support?.from_email ||
  SUPPORT_EMAIL;
const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY || config.sendgrid?.key;

const MAX_PER_HOUR_UID = 3;
const MAX_PER_HOUR_DEVICE = 5;

if (SENDGRID_API_KEY) {
  sgMail.setApiKey(SENDGRID_API_KEY);
}

const ALLOWED_CATEGORIES = new Set([
  'issue',
  'feature',
  'improvement',
  'report',
  'other',
]);

exports.onSupportMessageCreate = functions.firestore
  .document('supportMessages/{id}')
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const messageId = context.params.id;

    const validationError = validateSupportMessage(data);
    if (validationError) {
      await snap.ref.update({
        status: 'failed',
        errorMessage: validationError,
      });
      return;
    }

    const rateLimitError = await enforceRateLimit(data);
    if (rateLimitError) {
      await snap.ref.update({
        status: 'failed',
        errorMessage: rateLimitError,
      });
      return;
    }

    if (!SENDGRID_API_KEY) {
      await snap.ref.update({
        status: 'failed',
        errorMessage: 'SendGrid API key is not configured.',
      });
      return;
    }

    const subject = `[UniSpace] ${data.category} - ${data.subject}`;
    const text = buildEmailBody(data, messageId);

    try {
      await sgMail.send({
        to: SUPPORT_EMAIL,
        from: SUPPORT_FROM_EMAIL,
        subject,
        text,
      });

      await snap.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      await snap.ref.update({
        status: 'failed',
        errorMessage: message,
      });
    }
  });

function validateSupportMessage(data) {
  if (!data.subject || typeof data.subject !== 'string') {
    return 'Missing subject.';
  }
  if (!data.message || typeof data.message !== 'string') {
    return 'Missing message.';
  }
  if (!ALLOWED_CATEGORIES.has(data.category)) {
    return 'Invalid category.';
  }

  const subject = data.subject.trim();
  const message = data.message.trim();

  if (subject.length < 5 || subject.length > 200) {
    return 'Invalid subject length.';
  }
  if (message.length < 5 || message.length > 2000) {
    return 'Invalid message length.';
  }
  if (hasSuspiciousRepetition(message)) {
    return 'Suspicious repeated content detected.';
  }

  return null;
}

function hasSuspiciousRepetition(text) {
  const normalized = text.toLowerCase().trim();
  if (normalized.length < 30) {
    return false;
  }
  if (/(.)\1{20,}/.test(normalized)) {
    return true;
  }
  const words = normalized.split(/\s+/).filter(Boolean);
  if (words.length < 10) {
    return false;
  }
  const counts = new Map();
  for (const word of words) {
    counts.set(word, (counts.get(word) || 0) + 1);
  }
  const maxCount = Math.max(...counts.values());
  return maxCount / words.length > 0.6;
}

async function enforceRateLimit(data) {
  const firestore = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const oneHourAgo = admin.firestore.Timestamp.fromMillis(
    now.toMillis() - 60 * 60 * 1000,
  );

  if (data.uid) {
    const uidSnapshot = await firestore
      .collection('supportMessages')
      .where('uid', '==', data.uid)
      .where('createdAt', '>=', oneHourAgo)
      .get();
    if (uidSnapshot.size > MAX_PER_HOUR_UID) {
      return 'Rate limit exceeded for this account.';
    }
  }

  const deviceId = data.deviceInfo && data.deviceInfo.deviceId;
  if (deviceId) {
    const deviceSnapshot = await firestore
      .collection('supportMessages')
      .where('deviceInfo.deviceId', '==', deviceId)
      .where('createdAt', '>=', oneHourAgo)
      .get();
    if (deviceSnapshot.size > MAX_PER_HOUR_DEVICE) {
      return 'Rate limit exceeded for this device.';
    }
  }

  return null;
}

function buildEmailBody(data, messageId) {
  const createdAt = data.createdAt && data.createdAt.toDate
    ? data.createdAt.toDate().toISOString()
    : 'unknown';
  const deviceInfo = data.deviceInfo || {};

  return [
    `Message ID: ${messageId}`,
    `Category: ${data.category}`,
    `Subject: ${data.subject}`,
    '',
    'Message:',
    data.message,
    '',
    '---',
    'Account Info:',
    `UID: ${data.uid || '-'}`,
    `Email: ${data.email || '-'}`,
    `Phone: ${data.phone || '-'}`,
    `Name: ${data.displayName || '-'}`,
    '',
    'Metadata:',
    `App Version: ${data.appVersion || '-'}`,
    `Platform: ${data.platform || '-'}`,
    `Locale: ${data.locale || '-'}`,
    `Created At: ${createdAt}`,
    `Device ID: ${deviceInfo.deviceId || '-'}`,
    `OS Version: ${deviceInfo.osVersion || '-'}`,
  ].join('\n');
}
