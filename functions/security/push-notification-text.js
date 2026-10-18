const pushLocales = ['ar', 'en', 'fr'];
const deliveryLocale = value => pushLocales.includes(value) ? value : 'ar';
const templates = {
  new_post: ['نشر منشوراً جديداً', 'Shared a new post', 'A publié une nouvelle publication'],
  like: ['أعجب بمنشورك', 'Liked your post', 'A aimé votre publication'],
  like_comment: ['أعجب بتعليقك', 'Liked your comment', 'A aimé votre commentaire'],
  comment: ['علّق على منشورك', 'Commented on your post', 'A commenté votre publication'],
  reply: ['رد على تعليقك', 'Replied to your comment', 'A répondu à votre commentaire'],
  repost: ['أعاد نشر محتوى', 'Reposted content', 'A repartagé du contenu'],
  follow: ['بدأ بمتابعتك', 'Started following you', 'A commencé à vous suivre'],
  follow_request: ['طلب متابعتك', 'Requested to follow you', 'A demandé à vous suivre'],
  follow_accepted: ['قبل طلب المتابعة', 'Accepted your follow request', 'A accepté votre demande d’abonnement'],
};
function notificationBody(data, locale) {
  const index = pushLocales.indexOf(deliveryLocale(locale));
  if (Object.hasOwn(templates, data.type)) return templates[data.type][index];
  if (data.postId) return ['لديك تحديث على محتوى تتابعه', 'There is an update to content you follow',
    'Du contenu que vous suivez a été mis à jour'][index];
  // Announcements and exam details may be authored content; keep them verbatim.
  return String(data.message || ['لديك إشعار جديد', 'You have a new notification',
    'Vous avez une nouvelle notification'][index]);
}
module.exports = { pushLocales, deliveryLocale, notificationBody };
