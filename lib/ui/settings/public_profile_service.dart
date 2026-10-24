import '../../services/protected_media_service.dart';
import '../../widgets/protected_avatar_image.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'public_profile_reader.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PublicProfileService {
  static StreamSubscription<User?>? _authSubscription;
  static String? _viewerId;
  static int _sessionRevision = 0;

  static void _recordViewer(String? uid) {
    if (_viewerId == uid) return;
    _viewerId = uid;
    _sessionRevision++;
  }

  /// Process-memory scope only; not a token or an authorization credential.
  static String? get viewerSession {
    final auth = FirebaseAuth.instance;
    if (_authSubscription == null) {
      _viewerId = auth.currentUser?.uid;
      _authSubscription = auth.authStateChanges().listen((user) {
        _recordViewer(user?.uid);
      });
    }
    // Also handle synchronous account changes before their stream event arrives.
    _recordViewer(auth.currentUser?.uid);
    return _viewerId == null ? null : '$_viewerId:$_sessionRevision';
  }

  static final _reader = PublicProfileReader(
    sessionKey: () => viewerSession,
    fetchProfile: (userId) async {
      final response =
          await FirebaseFunctions.instanceFor(region: 'europe-west1')
              .httpsCallable('readPublicProfile')
              .call<Map<String, dynamic>>({'userId': userId});
      final data = Map<String, dynamic>.from(response.data);
      final lastSeen = data['lastSeenAt'];
      if (lastSeen is num && lastSeen.isFinite) {
        data['lastSeenAt'] =
            Timestamp.fromMillisecondsSinceEpoch(lastSeen.toInt());
      }
      return data;
    },
  );

  static Future<Map<String, dynamic>> load(String userId) =>
      _reader.load(userId);
  static Future<bool> isUnavailable(String userId) =>
      _reader.isUnavailable(userId);
  static Future<Set<String>> unavailableUserIds(Iterable<String> ids) =>
      _reader.unavailableUserIds(ids);
  static Stream<Map<String, dynamic>> watch(String userId,
      {bool Function()? shouldRefresh}) =>
      _reader.watch(userId, shouldRefresh: shouldRefresh);
}

/// Resolves the current viewer's authorized identity before displaying a photo.
class PublicProfilePhoto extends StatefulWidget {
  const PublicProfilePhoto(
      {super.key,
      required this.userId,
      this.fallbackUrl,
      required this.size,
      required this.radius,
      required this.iconSize,
      this.profileStream});
  final String userId;
  // Retained for source compatibility; stored URLs are never authorization.
  final String? fallbackUrl;
  final double size, radius, iconSize;
  @visibleForTesting
  final Stream<Map<String, dynamic>>? profileStream;

  @override
  State<PublicProfilePhoto> createState() => _PublicProfilePhotoState();
}

class _PublicProfilePhotoState extends State<PublicProfilePhoto> with WidgetsBindingObserver {
  bool? _visible;
  late Stream<Map<String, dynamic>> _profile;

  Stream<Map<String, dynamic>> _watch() async* {
    yield* PublicProfileService.watch(widget.userId, shouldRefresh: () =>
        mounted && _visible == true &&
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profile = widget.profileStream ?? _watch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.of(context) && ModalRoute.of(context)?.isCurrent != false;
    if (_visible == false && visible && widget.profileStream == null) _profile = _watch();
    _visible = visible;
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted && _visible == true && widget.profileStream == null && state == AppLifecycleState.resumed) {
      setState(() => _profile = _watch());
    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PublicProfilePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.profileStream != widget.profileStream) {
      _profile = widget.profileStream ?? _watch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(Icons.person, size: widget.iconSize);
    return StreamBuilder<Map<String, dynamic>>(
      key: ValueKey((widget.userId, ProtectedMediaService.instance.scope)),
      stream: _profile,
      builder: (context, snapshot) {
        // Retain this viewer's already displayed photo during revalidation.
        // A changed target/session gets a new builder; denial clears it below.
        final url = !snapshot.hasError
            ? (snapshot.data?['profileImageUrl']?.toString().trim() ?? '')
            : '';
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: url.startsWith('https://')
                ? ProtectedAvatarImage(url: url, size: widget.size, revalidate: false,
                    placeholder: placeholder)
                : placeholder,
          ),
        );
      },
    );
  }
}
