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
  static const firstNameKey = 'privacy_account_first_name';
  static const lastNameKey = 'privacy_account_last_name';
  static const emailKey = 'privacy_account_email';
  static const lastNameChangeAtKey = 'privacy_account_last_name_change_at';

  Future<PrivacyAccountData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final fallbackName = user?.displayName?.trim() ?? '';
    final parts = fallbackName.split(RegExp(r'\s+')).where((item) => item.isNotEmpty).toList();

    final first = prefs.getString(firstNameKey)?.trim();
    final last = prefs.getString(lastNameKey)?.trim();

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

    final email = (prefs.getString(emailKey)?.trim().isNotEmpty == true)
        ? prefs.getString(emailKey)!.trim()
        : (user?.email?.trim() ?? '');

    final rawLastChange = prefs.getString(lastNameChangeAtKey);
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
    await prefs.setString(firstNameKey, firstName.trim());
    await prefs.setString(lastNameKey, lastName.trim());
    await prefs.setString(lastNameChangeAtKey, changedAt.toIso8601String());
  }

  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(emailKey, email.trim());
  }
}
