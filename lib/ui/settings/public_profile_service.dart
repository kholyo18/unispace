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
      final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('readPublicProfile')
          .call<Map<String, dynamic>>({'userId': userId});
      final data = Map<String, dynamic>.from(response.data);
      final lastSeen = data['lastSeenAt'];
      if (lastSeen is num && lastSeen.isFinite) {
        data['lastSeenAt'] = Timestamp.fromMillisecondsSinceEpoch(lastSeen.toInt());
      }
      return data;
    },
  );

  static Future<Map<String, dynamic>> load(String userId) => _reader.load(userId);
  static Future<bool> isUnavailable(String userId) => _reader.isUnavailable(userId);
  static Future<Set<String>> unavailableUserIds(Iterable<String> ids) =>
      _reader.unavailableUserIds(ids);
  static Stream<Map<String, dynamic>> watch(String userId) => _reader.watch(userId);
}

/// Uses only the authorized photo URL; never opens the private user document.
class PublicProfilePhoto extends StatelessWidget {
  const PublicProfilePhoto(
      {super.key,
      required this.userId,
      this.fallbackUrl,
      required this.size,
      required this.radius,
      required this.iconSize});
  final String userId;
  final String? fallbackUrl;
  final double size, radius, iconSize;
  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(Icons.person, size: iconSize);
    return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: size,
          height: size,
          child: fallbackUrl == null || fallbackUrl!.isEmpty
              ? placeholder
              : Image.network(fallbackUrl!,
                  fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
        ));
  }
}
