import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyAccountData {
  const PrivacyAccountData({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.lastNameChangeAt,
  });

  final String firstName;
  final String lastName;
  final String email;
  final DateTime? lastNameChangeAt;

  String get fullName => [firstName, lastName].where((item) => item.trim().isNotEmpty).join(' ').trim();

  PrivacyAccountData copyWith({
    String? firstName,
    String? lastName,
    String? email,
    DateTime? lastNameChangeAt,
  }) {
    return PrivacyAccountData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      lastNameChangeAt: lastNameChangeAt ?? this.lastNameChangeAt,
    );
  }
}

class PrivacyAccountRepository {
  static const displayNameKey = 'displayName';
  static const firstNameKey = 'privacy_account_first_name';
  static const lastNameKey = 'privacy_account_last_name';
  static const emailKey = 'privacy_account_email';
  static const lastNameChangeAtKey = 'lastNameChangeAt';

  String? _userScope(User? user) {
    final uid = user?.uid.trim();
    if (uid != null && uid.isNotEmpty) return uid;
    final email = user?.email?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      return email.codeUnits.map((value) => value.toRadixString(16)).join();
    }
    return null;
  }

  String? currentUserScope() => _userScope(FirebaseAuth.instance.currentUser);

  String _scopedKey(String baseKey, User? user) {
    final scope = _userScope(user);
    if (scope == null) return baseKey;
    return '${baseKey}_$scope';
  }

  Future<PrivacyAccountData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final scopedDisplayName = prefs.getString(_scopedKey(displayNameKey, user))?.trim();
    final fallbackName = (scopedDisplayName?.isNotEmpty == true)
        ? scopedDisplayName!
        : user?.displayName?.trim() ?? '';
    final parts = fallbackName.split(RegExp(r'\s+')).where((item) => item.isNotEmpty).toList();

    final first = prefs.getString(_scopedKey(firstNameKey, user))?.trim();
    final last = prefs.getString(_scopedKey(lastNameKey, user))?.trim();

    final firstName = first?.isNotEmpty == true
        ? first!
        : parts.isNotEmpty
            ? parts.first
            : '';
    final lastName = last?.isNotEmpty == true
        ? last!
        : parts.length > 1
            ? parts.sublist(1).join(' ')
            : '';

    final scopedEmail = prefs.getString(_scopedKey(emailKey, user))?.trim();
    final email = (scopedEmail?.isNotEmpty == true)
        ? scopedEmail!
        : (user?.email?.trim() ?? '');

    final rawLastChange = prefs.getString(_scopedKey(lastNameChangeAtKey, user));
    final lastNameChangeAt = rawLastChange == null ? null : DateTime.tryParse(rawLastChange);

    return PrivacyAccountData(
      firstName: firstName,
      lastName: lastName,
      email: email,
      lastNameChangeAt: lastNameChangeAt,
    );
  }

  Future<void> saveName({required String firstName, required String lastName, required DateTime changedAt}) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final first = firstName.trim();
    final last = lastName.trim();

    await prefs.setString(_scopedKey(firstNameKey, user), first);
    await prefs.setString(_scopedKey(lastNameKey, user), last);
    await prefs.setString(_scopedKey(displayNameKey, user), [first, last].where((item) => item.isNotEmpty).join(' ').trim());
    await prefs.setString(_scopedKey(lastNameChangeAtKey, user), changedAt.toIso8601String());

    if (user != null) {
      final fullName = [first, last].where((item) => item.isNotEmpty).join(' ').trim();
      await user.updateDisplayName(fullName);
      await user.reload();
    }
  }

  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    await prefs.setString(_scopedKey(emailKey, user), email.trim());
  }
}
