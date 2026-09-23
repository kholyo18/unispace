// Copy the actual Dart callback bodies; never reimplement their decision logic.
// FirebaseAuth, the native renderer and navigation are test boundaries only.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const args = process.argv.slice(2);
let sourcePath = path.join(root, 'lib/main.dart');
let output = path.join(root, 'test/support/generated_push_recipient_callbacks.dart');
for (let i = 0; i < args.length; i += 2) {
  if (!args[i + 1]) throw Error('Missing argument value');
  if (args[i] === '--source') sourcePath = path.resolve(args[i + 1]);
  else if (args[i] === '--output') output = path.resolve(args[i + 1]);
  else throw Error('Unknown argument: ' + args[i]);
}
const source = fs.readFileSync(sourcePath, 'utf8');
function between(text, start, end) {
  const i = text.indexOf(start);
  if (i < 0 || text.indexOf(start, i + start.length) >= 0) throw Error('Missing/ambiguous start marker: ' + start);
  const j = text.indexOf(end, i + start.length);
  if (j < 0) throw Error('Missing end marker: ' + end);
  return text.slice(i + start.length, j);
}
const foreground = between(source,
  '    FirebaseMessaging.onMessage.listen((msg) async {\n',
  '\n    });\n\n    FirebaseMessaging.onMessageOpenedApp.listen');
const opened = between(source,
  '    FirebaseMessaging.onMessageOpenedApp.listen((msg) {\n', '\n    });');
const initialArea = between(source, '          .getInitialMessage()\n', "      debugPrint('FCM initial message:");
const initial = between(initialArea,
  '        WidgetsBinding.instance.addPostFrameCallback((_) {\n', '\n        });');
const local = 'void _handleFcmPayload(String payload) {' + between(source,
  'void _handleFcmPayload(String payload) {', '\nvoid _openFromFcmData(');
const open = 'void _openFromFcmData(Map<String, dynamic> data) {' + between(source,
  'void _openFromFcmData(Map<String, dynamic> data) {', '\nclass HiddenPostsScreen');
const digest = crypto.createHash('sha256').update(source).digest('hex');
const callbackDigest = crypto.createHash('sha256').update(
  [foreground, opened, initial, local, open].join('\n')).digest('hex');
const scaffold = `// Generated callback SHA256 ${callbackDigest}. Regenerate with the extractor; do not edit.\n` + String.raw`
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:UniSpace/ui/settings/push_preferences_service.dart';

// Controlled external boundaries. Real preference service and SDK value types.
class HarnessUser { HarnessUser(this.uid); final String uid; }
class FirebaseAuth {
  static final instance = FirebaseAuth();
  HarnessUser? currentUser;
}
void setHarnessUser(String? uid) {
  FirebaseAuth.instance.currentUser = uid == null ? null : HarnessUser(uid);
}
final displayed = <Map<String, dynamic>>[];
final openedNotifications = <NotificationItem>[];
class _NavigatorKey { Object? currentContext = Object(); }
final unispaceNavigatorKey = _NavigatorKey();
void resetHarness(String? uid) {
  setHarnessUser(uid);
  displayed.clear();
  openedNotifications.clear();
  unispaceNavigatorKey.currentContext = Object();
}
class _Renderer {
  Future<void> show(int id, String? title, String? body,
      NotificationDetails details, {String? payload}) async {
    displayed.add({'id': id, 'title': title, 'body': body,
      'details': details, 'payload': payload});
  }
}
final _localNotifs = _Renderer();
const _fcmChannel = AndroidNotificationChannel(
  'unispace_notifications', 'test channel', description: 'test');
class NotificationItem {
  const NotificationItem({required this.id, required this.sender,
    required this.message, required this.type, this.actorId,
    this.postId, this.commentId, required this.read});
  final String id, sender, message, type;
  final String? actorId, postId, commentId;
  final bool read;
}
void _openNotification(Object context, NotificationItem item) {
  openedNotifications.add(item);
}
void invokeLocal(String payload) => _handleFcmPayload(payload);
`;
// The following strings are inserted verbatim, including the existing gates.
const generated = scaffold +
  `\nFuture<void> invokeForeground(RemoteMessage msg) async {\n${foreground}\n}\n` +
  `\nvoid invokeOpened(RemoteMessage msg) {\n${opened}\n}\n` +
  `\nvoid Function() deferredInitial(RemoteMessage initial) => () {\n${initial}\n};\n` +
  '\n' + local + '\n' + open + '\n';
fs.mkdirSync(path.dirname(output), {recursive: true});
fs.writeFileSync(output, generated);
console.log(JSON.stringify({source: sourcePath, sourceSha256: digest,
  extractedSha256: crypto.createHash('sha256').update(generated).digest('hex'), output}));
