/// Canonical privacy fields take precedence; old documents remain readable.
class ProfilePrivacy {
  const ProfilePrivacy({required this.isPrivate, required this.showEmail});
  final bool isPrivate;
  final bool showEmail;
  factory ProfilePrivacy.fromDocument(Map<String, dynamic>? data) {
    final raw = data?['privacy'];
    final privacy = raw is Map ? raw : const {};
    return ProfilePrivacy(
      isPrivate: privacy['privateAccount'] is bool
          ? privacy['privateAccount'] as bool : data?['profileVisibility'] == 'private',
      showEmail: privacy['showEmailOnProfile'] is bool
          ? privacy['showEmailOnProfile'] as bool : data?['showEmailInProfile'] == true,
    );
  }
}
