// Generated callback SHA256 0ac40024be5d6bdf64f970ba14aea5a22f80fe4bcd8ecea2707651d81f51b0f5. Regenerate with the extractor; do not edit.

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

Future<void> invokeForeground(RemoteMessage msg) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || msg.data['recipientId'] is! String ||
          msg.data['recipientId'] != uid ||
          !PushPreferencesService.instance.allows(msg.data['type']?.toString() ?? '')) {
        return;
      }
      final n = msg.notification;
      if (n == null) return;
      await _localNotifs.show(
        msg.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _fcmChannel.id,
            _fcmChannel.name,
            channelDescription: _fcmChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(msg.data),
      );
}

void invokeOpened(RemoteMessage msg) {
      _openFromFcmData(msg.data);
}

void Function() deferredInitial(RemoteMessage initial) => () {
          _openFromFcmData(initial.data);
};

void _handleFcmPayload(String payload) {
  try {
    final data = jsonDecode(payload);
    if (data is Map) {
      _openFromFcmData(Map<String, dynamic>.from(data));
    }
  } catch (e) {
    debugPrint('fcm payload parse failed: $e');
  }
}

void _openFromFcmData(Map<String, dynamic> data) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || data['recipientId'] is! String ||
      data['recipientId'] != uid) {
    return;
  }
  final ctx = unispaceNavigatorKey.currentContext;
  if (ctx == null) return;
  final n = NotificationItem(
    id: (data['notificationId'] ?? '').toString(),
    sender: (data['actorName'] ?? 'طالب').toString(),
    message: (data['message'] ?? '').toString(),
    type: (data['type'] ?? 'comment').toString(),
    actorId: data['actorId']?.toString(),
    postId: data['postId']?.toString(),
    commentId: data['commentId']?.toString(),
    read: false,
  );
  _openNotification(ctx, n);
}
