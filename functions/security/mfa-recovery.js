const { randomBytes, createHash, timingSafeEqual } = require('node:crypto');
const { HttpsError } = require('firebase-functions/v2/https');

const digest = value => createHash('sha256').update(value).digest('hex');
const denied = () => new HttpsError('permission-denied', 'Could not verify recovery credentials.');
const factorIds = user => (user.multiFactor?.enrolledFactors || []).map(f => `${f.factorId}:${f.uid}`).sort();
const matches = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const sameHash = (a, b) => typeof a === 'string' && /^[a-f0-9]{64}$/.test(a) && timingSafeEqual(Buffer.from(a, 'hex'), Buffer.from(b, 'hex'));

// Credentials go only to this project's Identity Toolkit endpoint, never to logs.
function createFirstFactorVerifier({ apiKey, fetchImpl = fetch }) {
  return async data => {
    const key = apiKey();
    if (!key) throw new HttpsError('unavailable', 'Recovery is not configured.');
    const google = data.provider === 'google';
    const body = google ? {
      postBody: new URLSearchParams({ id_token: data.googleIdToken, providerId: 'google.com' }).toString(),
      requestUri: 'http://localhost', autoCreate: false, returnSecureToken: true,
    } : { email: data.email, password: data.password, returnSecureToken: true };
    let response;
    try {
      response = await fetchImpl(`https://identitytoolkit.googleapis.com/v1/accounts:${google ? 'signInWithIdp' : 'signInWithPassword'}?key=${encodeURIComponent(key)}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body), signal: AbortSignal.timeout(15000), redirect: 'error',
      });
    } catch (_) { throw new HttpsError('unavailable', 'Try again later.'); }
    if (!response.ok) throw denied();
    const result = await response.json();
    if (result.needConfirmation || result.error || (!result.mfaPendingCredential && !result.idToken)) throw denied();
    return result;
  };
}

function createRecoveryHandlers({ auth, db, FieldValue, verifyFirstFactor, now = Date.now }) {
  async function activeUser(request) {
    const header = request.rawRequest?.headers?.authorization || '';
    if (!request.auth?.uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in again.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); } catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== request.auth.uid || token.firebase?.tenant || !Number.isFinite(token.auth_time) ||
        now() / 1000 - token.auth_time > 300 || token.auth_time > now() / 1000 + 30 ||
        token.firebase?.sign_in_second_factor !== 'totp') {
      throw new HttpsError('failed-precondition', 'Confirm your identity with your authenticator first.');
    }
    const cutoff = await db.doc(`authRevocations/${token.uid}`).get();
    if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Sign in again.');
    const user = await auth.getUser(token.uid);
    const ids = factorIds(user);
    if (user.disabled || !user.emailVerified || !ids.length || ids.some(id => !id.startsWith('totp:'))) throw denied();
    return user;
  }

  async function generate(request) {
    if (request.data != null && (typeof request.data !== 'object' || Array.isArray(request.data) || Object.keys(request.data).length)) {
      throw new HttpsError('invalid-argument', 'No parameters accepted.');
    }
    const user = await activeUser(request);
    const key = randomBytes(16).toString('hex').toUpperCase();
    const ref = db.doc(`mfaRecovery/${user.uid}`);
    await db.runTransaction(async tx => {
      const old = (await tx.get(ref)).data();
      if (old?.status === 'processing' && old.leaseUntilMs > now()) throw new HttpsError('failed-precondition', 'Finish recovery first.');
      if (old && now() - old.createdAtMs < 60000) throw new HttpsError('resource-exhausted', 'Wait before replacing your key.');
      tx.set(ref, { version: 1, status: 'ready', keyHash: digest(key), factorIds: factorIds(user),
        createdAtMs: now(), updatedAt: FieldValue.serverTimestamp() });
    });
    return { key: key.match(/.{4}/g).join('-') };
  }

  async function revoke(uid) {
    await auth.revokeRefreshTokens(uid);
    const user = await auth.getUser(uid);
    const cutoff = Math.floor(Date.parse(user.tokensValidAfterTime) / 1000);
    if (!Number.isFinite(cutoff)) throw new HttpsError('internal', 'Could not revoke sessions.');
    const ref = db.doc(`authRevocations/${uid}`);
    await db.runTransaction(async tx => {
      const old = await tx.get(ref);
      tx.set(ref, { revokedBefore: Math.max(cutoff, old.data()?.revokedBefore || 0), updatedAt: FieldValue.serverTimestamp() });
    });
  }

  async function recover(request) {
    const data = request.data;
    const allowed = ['provider', 'email', 'password', 'googleIdToken', 'key'];
    if (!data || typeof data !== 'object' || Array.isArray(data) || Object.keys(data).some(k => !allowed.includes(k)) ||
        !['password', 'google'].includes(data.provider) || typeof data.email !== 'string' || data.email.length > 254 ||
        !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email) || typeof data.key !== 'string' || data.key.length > 50 ||
        (data.provider === 'password' ? typeof data.password !== 'string' || !data.password.length || data.password.length > 4096 || data.googleIdToken != null :
          typeof data.googleIdToken !== 'string' || !data.googleIdToken.length || data.googleIdToken.length > 8192 || data.password != null)) {
      throw new HttpsError('invalid-argument', 'Check the recovery fields.');
    }
    const key = data.key.replace(/[-\s]/g, '').toUpperCase();
    if (!/^[0-9A-F]{32}$/.test(key)) throw denied();
    const email = data.email.trim().toLowerCase();
    const attemptsRef = db.doc(`mfaRecoveryAttempts/${digest(email)}`);
    const permitted = await db.runTransaction(async tx => {
      const previous = (await tx.get(attemptsRef)).data();
      const current = previous && now() - previous.startedAtMs < 900000 ? previous : { startedAtMs: now(), count: 0 };
      if (current.count >= 10) return false;
      tx.set(attemptsRef, { startedAtMs: current.startedAtMs, count: current.count + 1 });
      return true;
    });
    if (!permitted) throw new HttpsError('resource-exhausted', 'Wait 15 minutes before trying again.');
    const proof = await verifyFirstFactor({ ...data, email });
    let user;
    try { user = await auth.getUserByEmail(email); } catch (_) { throw denied(); }
    if (user.disabled || !user.emailVerified || user.tenantId) throw denied();
    if (proof.localId && proof.localId !== user.uid) throw denied();
    const ids = factorIds(user);
    if (proof.mfaPendingCredential) {
      // Some MFA responses omit localId. Bind the server's enrollment IDs to the Admin user record.
      const proven = (proof.mfaInfo || []).map(f => f.mfaEnrollmentId).sort();
      const actual = (user.multiFactor?.enrolledFactors || []).map(f => f.uid).sort();
      if (!actual.length || !matches(proven, actual)) throw denied();
    } else {
      let token;
      try { token = await auth.verifyIdToken(proof.idToken, true); } catch (_) { throw denied(); }
      if (token.uid !== user.uid || token.firebase?.tenant) throw denied();
    }
    const ref = db.doc(`mfaRecovery/${user.uid}`);
    const lease = randomBytes(16).toString('hex');
    const keyHash = digest(key);
    const state = await db.runTransaction(async tx => {
      const record = (await tx.get(ref)).data();
      if (!record || record.version !== 1 || !sameHash(record.keyHash, keyHash)) throw denied();
      if (record.status === 'complete') {
        // A lost success response can be acknowledged briefly, without repeating side effects.
        if (now() - record.completedAtMs <= 600000) return { complete: true };
        throw denied();
      }
      if (!['ready', 'processing'].includes(record.status)) throw denied();
      if (record.leaseUntilMs > now()) throw new HttpsError('aborted', 'Recovery is already running. Try again shortly.');
      const sameFactors = matches(ids, record.factorIds);
      if (record.status === 'ready' && (!proof.mfaPendingCredential || !sameFactors)) throw denied();
      if (record.status === 'processing' && !sameFactors && ids.length !== 0) throw denied();
      if (!record.factorIds.length || record.factorIds.some(id => !id.startsWith('totp:'))) throw denied();
      tx.update(ref, { status: 'processing', lease, leaseUntilMs: now() + 120000, updatedAt: FieldValue.serverTimestamp() });
      return record;
    });
    if (state.complete) return { recovered: true };
    try {
      // Publish revocation before removing the lost factor. No tokens are returned to the caller.
      await revoke(user.uid);
      user = await auth.getUser(user.uid);
      const currentIds = factorIds(user);
      if (user.disabled || (currentIds.length && !matches(currentIds, state.factorIds))) throw denied();
      if (currentIds.length) await auth.updateUser(user.uid, { multiFactor: { enrolledFactors: [] } });
      await revoke(user.uid);
      await db.runTransaction(async tx => {
        const current = (await tx.get(ref)).data();
        if (current?.lease !== lease) throw new HttpsError('aborted', 'Try again shortly.');
        tx.update(ref, { status: 'complete', leaseUntilMs: 0, completedAtMs: now(), updatedAt: FieldValue.serverTimestamp() });
      });
      return { recovered: true };
    } catch (_) {
      await db.runTransaction(async tx => {
        const current = (await tx.get(ref)).data();
        if (current?.lease === lease && current.status === 'processing') tx.update(ref, { leaseUntilMs: 0 });
      });
      throw new HttpsError('unavailable', 'Recovery was interrupted. Retry with the same key and credentials.');
    }
  }
  return { generate, recover };
}

module.exports = { createRecoveryHandlers, createFirstFactorVerifier };
