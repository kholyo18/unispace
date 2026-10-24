const {createGroupAccessHandlers}=require('./chat-group-access');
const {assertChatAccount}=require('./chat-account');
const {
  HttpsError
} = require('firebase-functions/v2/https');
const {
  assertActiveSession
} = require('./device-sessions');
const {
  createHash
} = require('node:crypto');
const validId = v => typeof v === 'string' && /^[A-Za-z0-9_-]{1,260}$/.test(v);
const fail = (code, message) => {
  throw new HttpsError(code, message);
};
const brief = d => ({
  name: [d.firstName, d.lastName].filter(Boolean).join(' ') || d.displayName || d.userName || '',
  photoUrl: d.profileImageUrl || null
});
const unavailable = d => !d || ['disabled', 'deleted'].includes(d.accountStatus) || d.security?.frozen === true;
async function groupPair({
  db,
  tx,
  sender,
  receiver,
  invitation = false,
  directAdd = false
}) {
  const refs = [db.doc(`users/${sender}`), db.doc(`users/${receiver}`), db.doc(`users/${receiver}/followers/${sender}`), db.doc(`users/${sender}/followers/${receiver}`)];
  for (const [a, b] of [[sender, receiver], [receiver, sender]]) for (const key of ['blocked_accounts', 'blocked_users', 'blocked_by']) refs.push(db.doc(`users/${a}/${key}/${b}`));
  const [own, other, follows, reverse, ...blocks] = await tx.getAll(...refs);
  if (unavailable(own.data()) || unavailable(other.data()) || blocks.some(s => s.exists)) fail('permission-denied', 'Group messaging unavailable.');
  await assertChatAccount({db,tx,uid:sender,profile:own.data()});
  await assertChatAccount({db,tx,uid:receiver,profile:other.data()});
  const p = other.data().privacy || {},
    who = p.whoCanMessage || 'mutual';
  const direct = who === 'everyone' || who === 'followers' && follows.exists || who === 'mutual' && follows.exists && reverse.exists;
  if (directAdd && !direct) fail('permission-denied', 'Recipient privacy does not allow direct group membership.');
  if (who === 'none' || invitation && !direct && p.messageRequests === false) fail('permission-denied', 'Recipient does not accept group invitations.');
  return {
    own: own.data(),
    other: other.data()
  };
}
async function assertGroupMessage({
  db,
  tx,
  token,
  chat,
  enforcePosting = true
}) {
  await assertActiveSession({
    db,
    token,
    reader: tx
  });
  if (chat.type !== 'group' || !Array.isArray(chat.memberIds) || !chat.memberIds.includes(token.uid)) fail('permission-denied', 'Group unavailable.');
  if(enforcePosting&&chat.adminsOnlyMessaging===true&&!chat.adminIds?.includes(token.uid))fail('permission-denied','Only administrators may send messages.');
  const self = await tx.get(db.doc(`users/${token.uid}`));
  await assertChatAccount({db,tx,uid:token.uid,profile:self.data()});
  for (const receiver of chat.memberIds.filter(uid => uid !== token.uid)) await groupPair({
    db,
    tx,
    sender: token.uid,
    receiver
  });
}
function createGroupHandlers({
  db,
  auth,
  FieldValue,
  bucket
}) {
  async function identity(request) {
    const uid = request.auth?.uid,
      header = request.rawRequest?.headers?.authorization;
    if (!validId(uid) || !header?.startsWith('Bearer ')) fail('unauthenticated', 'Sign in first.');
    let token;
    try {
      token = await auth.verifyIdToken(header.slice(7), true);
    } catch (_) {
      fail('unauthenticated', 'Sign in again.');
    }
    if (token.uid !== uid) fail('unauthenticated', 'Invalid session.');
    return {
      uid,
      token
    };
  }
  async function available(uid) {
    let user;
    try {
      user = await auth.getUser(uid);
    } catch (_) {
      fail('permission-denied', 'Account unavailable.');
    }
    if (user.disabled) fail('permission-denied', 'Account unavailable.');
  }
  function name(value) {
    if (typeof value !== 'string' || !value.trim() || value.trim().length > 80) fail('invalid-argument', 'Group name must contain 1 to 80 characters.');
    return value.trim();
  }
  function groupId(value) {
    if (!validId(value) || !value.startsWith('group_')) fail('invalid-argument', 'Group id must use group_ prefix.');
    return value;
  }
  async function budget(tx, uid, count) {
    const ref = db.doc(`groupInviteLimits/${uid}`),
      limit = (await tx.get(ref)).data(),
      now = Date.now(),
      active = limit && now - limit.windowStart < 60000;
    const used = active ? limit.count : 0;
    if (used + count > 32) fail('resource-exhausted', 'Please wait before sending more invitations.');
    return {
      ref,
      data: {
        windowStart: active ? limit.windowStart : now,
        count: used + count
      }
    };
  }
  const create = async request => {
    const {
        uid,
        token
      } = await identity(request),
      input = request.data || {},
      chatId = groupId(input.groupId),
      groupName = name(input.name);
    if (!Array.isArray(input.memberIds) || input.memberIds.length > 31 || input.memberIds.some(x => !validId(x) || x === uid) || new Set(input.memberIds).size !== input.memberIds.length) fail('invalid-argument', 'Choose up to 31 distinct people.');
    const invited = [...input.memberIds].sort(),
      fingerprint = createHash('sha256').update(JSON.stringify([uid, groupName, invited])).digest('hex');
    return db.runTransaction(async tx => {
      await assertActiveSession({
        db,
        token,
        reader: tx
      });
      const ref = db.doc(`chats/${chatId}`),
        existing = await tx.get(ref);
      if (existing.exists) {
        const d = existing.data();
        if (d.type !== 'group' || d.creationFingerprint !== fingerprint || !d.memberIds.includes(uid)) fail('already-exists', 'Group id in use.');
        return {
          chatId,
          status: 'open'
        };
      }
      await Promise.all(invited.map(available));
      const self = await tx.get(db.doc(`users/${uid}`));
      await assertChatAccount({db,tx,uid:uid,profile:self.data()});
      const pendingMembers = {};
      for (const receiver of invited) {
        const checked = await groupPair({
          db,
          tx,
          sender: uid,
          receiver,
          invitation: true,
          directAdd: true
        });
        pendingMembers[receiver] = brief(checked.other);
      }
      for (let a = 0; a < invited.length; a++) {
        for (let b = a + 1; b < invited.length; b++) {
          await groupPair({db, tx, sender: invited[a], receiver: invited[b]});
        }
      }
      const limit = await budget(tx, uid, Math.max(1, invited.length));
      tx.set(limit.ref, limit.data);
      tx.create(ref, {
        type: 'group',
        name: groupName,
        creatorId: uid,
        creationFingerprint: fingerprint,
        memberIds: [uid, ...invited],
        adminIds: [uid],
        pendingMemberIds: [],
        pendingMembers: {},
        members: { [uid]: brief(self.data()), ...pendingMembers },
        unread: Object.fromEntries([uid, ...invited].map(id => [id, 0])),
        createdAt: FieldValue.serverTimestamp(),
        lastMessageAt: FieldValue.serverTimestamp()
      });

      return {
        chatId,
        status: 'open'
      };
    });
  };
  const manage = async request => {
    const {
        uid,
        token
      } = await identity(request),
      i = request.data || {},
      chatId = groupId(i.chatId),
      action = i.action;
    if (!['invite', 'rename', 'photo', 'promote', 'demote', 'remove', 'leave'].includes(action)) fail('invalid-argument', 'Invalid group action.');
    const target = action === 'leave' ? uid : i.memberId;
    if (!['rename', 'photo'].includes(action) && !validId(target)) fail('invalid-argument', 'Member required.');
    if (action === 'invite') await available(target);
    if (action === 'photo') {
      if (!bucket) fail('unavailable', 'Storage unavailable.');
      const storage = bucket();
      const {parseProtectedMediaSource} = require('./protected-media');
      const {path, parts} = parseProtectedMediaSource(i.photoUrl, storage.name);
      if (parts.length !== 4 || parts[0] !== 'chats' || parts[1] !== chatId || parts[2] !== 'images') fail('invalid-argument', 'Choose an uploaded group image.');
      let metadata;
      try { [metadata] = await storage.file(path).getMetadata(); }
      catch (_) { fail('not-found', 'Upload the image first.'); }
      const {publishedUploadMatches} = require('./published-upload');
      if (!publishedUploadMatches(metadata, new URL(i.photoUrl), uid) ||
          metadata.metadata?.uploadedBy !== uid || !['image/jpeg', 'image/png', 'image/webp'].includes(metadata.contentType)) fail('permission-denied', 'Image upload does not belong to this account.');
    }
    return db.runTransaction(async tx => {
      await assertActiveSession({
        db,
        token,
        reader: tx
      });
      const ref = db.doc(`chats/${chatId}`),
        snap = await tx.get(ref),
        c = snap.data();
      if (c?.type !== 'group' || !c.memberIds.includes(uid) || action !== 'leave' && !c.adminIds.includes(uid)) fail('permission-denied', 'Group administrator required.');
      if (action !== 'leave') {
        const self = await tx.get(db.doc(`users/${uid}`));
        await assertChatAccount({db,tx,uid:uid,profile:self.data()});
      }
      if (action === 'photo') {
        tx.update(ref, {photoUrl: i.photoUrl});
        return {chatId, status: 'open'};
      }
      if (action === 'rename') {
        const nextName = name(i.name);
        tx.update(ref, {
          name: nextName
        });
        for (const receiver of c.pendingMemberIds || []) tx.update(db.doc(`groupInvites/${chatId}_${receiver}`), {
          groupName: nextName
        });
        return {
          chatId,
          status: 'open'
        };
      }
      const members = [...c.memberIds],
        admins = [...c.adminIds],
        pending = [...(c.pendingMemberIds || [])];
      if (action === 'invite') {
        if (members.includes(target)) return {
          chatId,
          status: 'open'
        };

        const checked = await groupPair({
          db,
          tx,
          sender: uid,
          receiver: target,
          invitation: true,
          directAdd: true
        });
        const inviteRef = db.doc(`groupInvites/${chatId}_${target}`),
          old = await tx.get(inviteRef);
        if (old.data()?.status === 'rejected') fail('permission-denied', 'This invitation was declined.');
        for (const peer of members.filter(id => id !== uid)) {
          await groupPair({db, tx, sender: target, receiver: peer});
        }
        const limit = await budget(tx, uid, 1);
        tx.set(limit.ref, limit.data);
        if (old.exists) tx.update(inviteRef, {status: 'accepted', updatedAt: FieldValue.serverTimestamp()});
        tx.update(ref, {
          memberIds: [...members, target],
          pendingMemberIds: pending.filter(id => id !== target),
          [`pendingMembers.${target}`]: FieldValue.delete(),
          [`members.${target}`]: brief(checked.other),
          [`unread.${target}`]: 0
        });
        return {
          chatId,
          status: 'open'
        };
      }
      if (!members.includes(target) && !(action === 'remove' && pending.includes(target))) fail('not-found', 'Member not found.');
      if (action === 'promote') {
        if (!admins.includes(target)) tx.update(ref, {
          adminIds: [...admins, target]
        });
        return {
          chatId,
          status: 'open'
        };
      }
      if (admins.includes(target) && admins.length === 1 && (action === 'demote' || members.length > 1)) fail('failed-precondition', 'Promote another administrator first.');
      // Role changes revoke pending invitations from the departing administrator.
      const inviteRefs = [...new Set([target, ...pending])].map(x => db.doc(`groupInvites/${chatId}_${x}`));
      const invites = await tx.getAll(...inviteRefs);
      const inviteLinkRef = db.doc(`groupInviteLinks/${chatId}`);
      const inviteLink = await tx.get(inviteLinkRef);
      const empty = action !== 'demote' && members.length === 1 && target === uid;
      const cancelled = invites.filter(invite => invite.exists && invite.data().status === 'pending' && (empty || invite.data().receiverId === target || invite.data().senderId === target));
      const cancelledIds = new Set(cancelled.map(invite => invite.data().receiverId));
      const nextPending = pending.filter(x => x !== target && !cancelledIds.has(x));
      const changes = {
        adminIds: admins.filter(x => x !== target),
        pendingMemberIds: nextPending,
        pendingMembers: Object.fromEntries(Object.entries(c.pendingMembers || {}).filter(([x]) => nextPending.includes(x)))
      };
      if (action !== 'demote') {
        changes.memberIds = members.filter(x => x !== target);
        changes[`members.${target}`] = FieldValue.delete();
        changes[`unread.${target}`] = FieldValue.delete();
      }
      tx.update(ref, changes);
      if(inviteLink.data()?.issuerUid===target&&inviteLink.data()?.active)tx.update(inviteLinkRef,{active:false,updatedAt:FieldValue.serverTimestamp()});
      for (const invite of invites) {
        if (invite.exists && (cancelledIds.has(invite.data().receiverId) || action !== 'demote' && invite.data().receiverId === target)) {
          tx.update(invite.ref, {
            status: 'removed',
            updatedAt: FieldValue.serverTimestamp()
          });
        }
      }
      return {
        chatId,
        status: action === 'leave' ? 'left' : 'open'
      };
    });
  };
  const respond = async request => {
    const {
        uid,
        token
      } = await identity(request),
      {
        chatId: raw,
        action
      } = request.data || {},
      chatId = groupId(raw);
    if (!['accept', 'reject'].includes(action)) fail('invalid-argument', 'Invalid response.');
    return db.runTransaction(async tx => {
      await assertActiveSession({
        db,
        token,
        reader: tx
      });
      const ref = db.doc(`chats/${chatId}`),
        inviteRef = db.doc(`groupInvites/${chatId}_${uid}`),
        [snap, invite] = await tx.getAll(ref, inviteRef),
        c = snap.data(),
        i = invite.data();
      if (c?.type !== 'group' || i?.chatId !== chatId || i.receiverId !== uid || !validId(i.senderId)) fail('permission-denied', 'Invitation unavailable.');
      if (action === 'accept' && i.status === 'accepted' && c.memberIds.includes(uid)) return {
        chatId,
        status: 'open'
      };
      if (action === 'reject' && i.status === 'rejected') return {
        chatId,
        status: 'rejected'
      };
      if (i.status !== 'pending' || !c.pendingMemberIds?.includes(uid) || !c.memberIds.length) fail('failed-precondition', 'Invitation is no longer pending.');
      if (action === 'accept') {
        if (!c.adminIds.includes(i.senderId)) fail('permission-denied', 'Inviting administrator is unavailable.');
        await groupPair({
          db,
          tx,
          sender: i.senderId,
          receiver: uid,
          invitation: true
        });
        for (const peer of c.memberIds) await groupPair({
          db,
          tx,
          sender: uid,
          receiver: peer
        });
        const self = await tx.get(db.doc(`users/${uid}`));
        tx.update(ref, {
          memberIds: [...c.memberIds, uid],
          pendingMemberIds: c.pendingMemberIds.filter(x => x !== uid),
          [`pendingMembers.${uid}`]: FieldValue.delete(),
          [`members.${uid}`]: brief(self.data()),
          [`unread.${uid}`]: 0
        });
      } else tx.update(ref, {
        pendingMemberIds: c.pendingMemberIds.filter(x => x !== uid),
        [`pendingMembers.${uid}`]: FieldValue.delete()
      });
      tx.update(inviteRef, {
        status: action === 'accept' ? 'accepted' : 'rejected',
        updatedAt: FieldValue.serverTimestamp()
      });
      return {
        chatId,
        status: action === 'accept' ? 'open' : 'rejected'
      };
    });
  };
  return {
    ...createGroupAccessHandlers({db,FieldValue,identity,groupId,available,groupPair,assertChatAccount}),
    create,
    manage,
    respond
  };
}
module.exports = {
  createGroupHandlers,
  assertGroupMessage,
  groupPair
};
