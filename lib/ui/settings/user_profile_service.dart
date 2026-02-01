import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'app_settings.dart';

@immutable
class UserProfileData {
  const UserProfileData({
    required this.profileVisibility,
    required this.showEmailInProfile,
    required this.twoFactorEnabled,
    required this.college,
    required this.major,
    required this.level,
  });

  final ProfileVisibility profileVisibility;
  final bool showEmailInProfile;
  final bool twoFactorEnabled;
  final String college;
  final String major;
  final String level;

  factory UserProfileData.initial() => const UserProfileData(
        profileVisibility: ProfileVisibility.public,
        showEmailInProfile: true,
        twoFactorEnabled: false,
        college: '',
        major: '',
        level: '',
      );

  UserProfileData copyWith({
    ProfileVisibility? profileVisibility,
    bool? showEmailInProfile,
    bool? twoFactorEnabled,
    String? college,
    String? major,
    String? level,
  }) {
    return UserProfileData(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showEmailInProfile: showEmailInProfile ?? this.showEmailInProfile,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      college: college ?? this.college,
      major: major ?? this.major,
      level: level ?? this.level,
    );
  }

  static UserProfileData fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return UserProfileData.initial();
    final profileVisibilityRaw = data['profileVisibility'] as String?;
    final academic = data['academic'] as Map<String, dynamic>?;
    return UserProfileData(
      profileVisibility: profileVisibilityRaw == 'private'
          ? ProfileVisibility.private
          : ProfileVisibility.public,
      showEmailInProfile: data['showEmailInProfile'] as bool? ?? true,
      twoFactorEnabled: data['twoFactorEnabled'] as bool? ?? false,
      college: academic?['college'] as String? ?? '',
      major: academic?['major'] as String? ?? '',
      level: academic?['level'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'profileVisibility':
          profileVisibility == ProfileVisibility.private ? 'private' : 'public',
      'showEmailInProfile': showEmailInProfile,
      'twoFactorEnabled': twoFactorEnabled,
      'academic': {
        'college': college,
        'major': major,
        'level': level,
      },
    };
  }
}

class UserProfileService {
  UserProfileService._();

  static final UserProfileService instance = UserProfileService._();

  final ValueNotifier<UserProfileData> notifier =
      ValueNotifier<UserProfileData>(UserProfileData.initial());

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  StreamSubscription<User?>? _authSub;

  Future<void> initialize() async {
    _authSub ??=
        FirebaseAuth.instance.authStateChanges().listen(_handleAuthChange);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _subscribeToProfile(user.uid);
    }
  }

  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  Future<void> _handleAuthChange(User? user) async {
    await _profileSub?.cancel();
    _profileSub = null;
    if (user == null) {
      notifier.value = UserProfileData.initial();
      return;
    }
    await _subscribeToProfile(user.uid);
  }

  Future<void> _subscribeToProfile(String uid) async {
    _profileSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        notifier.value = UserProfileData.initial();
        return;
      }
      notifier.value = UserProfileData.fromFirestore(snapshot.data());
    });
  }

  Future<void> updateProfile({
    ProfileVisibility? profileVisibility,
    bool? showEmailInProfile,
    bool? twoFactorEnabled,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final next = notifier.value.copyWith(
      profileVisibility: profileVisibility,
      showEmailInProfile: showEmailInProfile,
      twoFactorEnabled: twoFactorEnabled,
    );
    notifier.value = next;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(
          next.toFirestore(),
          SetOptions(merge: true),
        );
  }

  Future<void> updateAcademic({
    required String college,
    required String major,
    required String level,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final next = notifier.value.copyWith(
      college: college,
      major: major,
      level: level,
    );
    notifier.value = next;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(
          {
            'academic': {
              'college': college,
              'major': major,
              'level': level,
            },
          },
          SetOptions(merge: true),
        );
  }

  void dispose() {
    _profileSub?.cancel();
    _authSub?.cancel();
  }
}
