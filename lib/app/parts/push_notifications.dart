part of '../../main.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.data['type'] == 'message' && message.notification == null && message.data['chatActionsVersion'] == '1') {
    await AppSettings.instance.load();
    await _localNotifs.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'), iOS: DarwinInitializationSettings()));
    await _localNotifs.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_fcmChannel);
    await _showChatPush(message);
  }
}

AndroidNotificationChannel get _fcmChannel => AndroidNotificationChannel(
  'unispace_notifications',
  mainTextCurrent('إشعارات UniSpace'),
  description: mainTextCurrent('متابعة، تعليقات، إعجابات'),
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifs =
FlutterLocalNotificationsPlugin();

Future<void> initPushNotifications() async {
  PushPreferencesService.instance.start();
  try {
    final messaging = FirebaseMessaging.instance;

    try {
      await messaging
          .requestPermission(alert: true, badge: true, sound: true)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('FCM permission: $e');
    }

    await _localNotifs
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_fcmChannel);

    await _localNotifs.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _notificationResponse,
    );

    final launch = await _localNotifs.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true && launch?.notificationResponse != null) {
      _notificationResponse(launch!.notificationResponse!);
    }
    // Foreground presentation goes through the local preference check below.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    FirebaseMessaging.onMessage.listen((msg) async {
      if (FirebaseAuth.instance.currentUser == null ||
          (msg.data['recipientId'] != null &&
              msg.data['recipientId'] !=
                  FirebaseAuth.instance.currentUser?.uid) ||
          !PushPreferencesService.instance.allows(msg.data['type']?.toString() ?? '')) return;
      if (msg.data['type'] == 'message') { await _showChatPush(msg); return; }
      final n = msg.notification;
      if (n == null) return;
      await _localNotifs.show(
        chatNotificationLocalId((msg.data['notificationId'] ?? msg.messageId ?? '').toString()),
        n.title,
        localizedNotificationBody(Intl.defaultLocale ?? 'en',
            type: msg.data['type']?.toString() ?? '', fallback: n.body),
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
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _openFromFcmData(msg.data);
    });

    try {
      final initial = await messaging
          .getInitialMessage()
          .timeout(const Duration(seconds: 8));
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openFromFcmData(initial.data);
        });
      }
    } catch (e) {
      debugPrint('FCM initial message: $e');
    }

    await saveFcmToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((t) => saveFcmToken(t));
    FirebaseAuth.instance.authStateChanges().listen((user) {
      saveFcmToken();
    });
  } catch (e, st) {
    debugPrint('initPushNotifications failed: $e');
    debugPrintStack(stackTrace: st);
  }
}

final unispaceNavigatorKey = GlobalKey<NavigatorState>();

Future<void> saveFcmToken([String? token]) =>
    PushPreferencesService.instance.sync(token);

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
  if (uid == null ||
      (data['recipientId'] != null && data['recipientId'] != uid)) return;
  final ctx = unispaceNavigatorKey.currentContext;
  if (ctx == null) return;
  final n = NotificationItem(
    id: (data['notificationId'] ?? '').toString(),
    sender: (data['actorName'] ?? mainTextCurrent("طالب")).toString(),
    message: (data['message'] ?? '').toString(),
    type: (data['type'] ?? 'comment').toString(),
    actorId: data['actorId']?.toString(),
    chatId: data['chatId']?.toString(),
    postId: data['postId']?.toString(),
    commentId: data['commentId']?.toString(),
    read: false,
  );
  _openNotification(ctx, n);
}


String _notificationActionLocale(Map<String, dynamic> data) =>
    (data['locale'] ?? Intl.defaultLocale ?? 'en').toString();

Future<void> _showChatPush(RemoteMessage message) async {
  final data = message.data;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || data['recipientId'] != uid ||
      !PushPreferencesService.instance.allows('message')) return;
  final id = data['notificationId']?.toString() ?? '';
  if (!RegExp(r'^chat_[a-f0-9]{64}$').hasMatch(id)) return;
  final locale = _notificationActionLocale(data);
  await _localNotifs.show(chatNotificationLocalId(id), 'UniSpace',
    chatNotificationActionText(locale, 'You have a new message'),
    NotificationDetails(android: AndroidNotificationDetails(
      _fcmChannel.id, _fcmChannel.name, channelDescription: _fcmChannel.description,
      importance: Importance.high, priority: Priority.high, icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.private, onlyAlertOnce: true, tag: id,
      actions: [
        AndroidNotificationAction('reply', chatNotificationActionText(locale, 'Reply'),
          showsUserInterface: true, cancelNotification: false,
          inputs: [AndroidNotificationActionInput(label: chatNotificationActionText(locale, 'Write a reply'))]),
        AndroidNotificationAction('markRead', chatNotificationActionText(locale, 'Mark as read'),
          showsUserInterface: true, cancelNotification: false),
      ]), iOS: const DarwinNotificationDetails()), payload: jsonEncode(data));
}

class _QueuedNotificationAction {
  _QueuedNotificationAction(this.data, this.action, this.input);
  final Map<String, dynamic> data;
  final String action;
  final String? input;
  final DateTime expires = DateTime.now().add(const Duration(minutes: 2));
  String get key => jsonEncode([data['notificationId'], action, input]);
}

final _queuedNotificationActions = <_QueuedNotificationAction>[];
final _completedNotificationActions = <String>{};
Timer? _notificationActionTimer;
bool _drainingNotificationActions = false;

void _notificationResponse(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  if (!['reply', 'markRead'].contains(response.actionId)) {
    _handleFcmPayload(payload);
    return;
  }
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map) return;
    final action = _QueuedNotificationAction(Map<String, dynamic>.from(decoded), response.actionId!, response.input);
    _queueNotificationAction(action);
  } catch (_) { /* Invalid payloads never initiate a mutation. */ }
}

void _queueNotificationAction(_QueuedNotificationAction action) {
  if (_completedNotificationActions.contains(action.key) ||
      _queuedNotificationActions.any((pending) => pending.key == action.key)) return;
  _queuedNotificationActions.add(action);
  _notificationActionTimer ??= Timer.periodic(const Duration(seconds: 1), (_) => unawaited(_drainNotificationActions()));
  unawaited(_drainNotificationActions());
}

Future<void> _drainNotificationActions() async {
  if (_drainingNotificationActions || _queuedNotificationActions.isEmpty) return;
  _drainingNotificationActions = true;
  try {
    final context = unispaceNavigatorKey.currentContext;
    if (context == null) return;
    final action = _queuedNotificationActions.first;
    final locale = _notificationActionLocale(action.data);
    final user = FirebaseAuth.instance.currentUser;
    if (DateTime.now().isAfter(action.expires) ||
        (user != null && action.data['recipientId'] != user.uid)) {
      _queuedNotificationActions.removeAt(0);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(chatNotificationActionText(locale, 'Sign in to the notified account.'))));
      return;
    }
    if (user == null) return;
    final token = await user.getIdTokenResult();
    if (FirebaseAuth.instance.currentUser?.uid != user.uid ||
        token.claims?['sid'] is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(token.claims!['sid'] as String)) return;
    _queuedNotificationActions.removeAt(0);
    try {
      await ChatNotificationActions().perform(action.data, action.action, input: action.input);
      final id = action.data['notificationId'].toString();
      await _localNotifs.cancel(chatNotificationLocalId(id), tag: id);
      _completedNotificationActions.add(action.key);
      if (_completedNotificationActions.length > 64) _completedNotificationActions.remove(_completedNotificationActions.first);
      if (context.mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(chatNotificationActionText(locale, action.action == 'reply' ? 'Reply sent' : 'Marked as read'))));
      if (action.action == 'reply') _openFromFcmData(action.data);
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(chatNotificationActionText(locale, 'Action failed. Open the conversation to retry.')),
        action: SnackBarAction(label: chatNotificationActionText(locale, 'Retry'), onPressed: () =>
          _queueNotificationAction(_QueuedNotificationAction(action.data, action.action, action.input)))));
    }
  } catch (_) {
    // Session bootstrap may still be settling. Keep the explicit action queued.
  } finally {
    _drainingNotificationActions = false;
    if (_queuedNotificationActions.isEmpty) { _notificationActionTimer?.cancel(); _notificationActionTimer = null; }
  }
}
