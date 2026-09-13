class SecurityChecklist {
  const SecurityChecklist(
      {required this.hasEmail,
      required this.emailVerified,
      required this.hasPhone,
      required this.loginAlerts,
      required this.twoFactor});
  final bool hasEmail, emailVerified, hasPhone, loginAlerts, twoFactor;
  static const total = 5;
  int get completed => [
        hasEmail,
        hasEmail && emailVerified,
        hasPhone,
        loginAlerts,
        twoFactor
      ].where((value) => value).length;
}
