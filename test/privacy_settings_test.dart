import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/ui/settings/profile_settings_patch.dart';
import 'package:UniSpace/ui/settings/app_settings.dart';
import 'package:UniSpace/ui/settings/security_checklist.dart';

void main() {
  test('hiding email preserves MFA, academic data and other privacy settings',
      () {
    final document = <String, dynamic>{
      'twoFactorEnabled': true,
      'academic': {'college': 'Current college'},
      'profileVisibility': 'private',
      'showEmailInProfile': true
    };
    document.addAll(profileSettingsPatch(showEmailInProfile: false));
    expect(document['twoFactorEnabled'], true);
    expect(document['academic'], {'college': 'Current college'});
    expect(document['profileVisibility'], 'private');
    expect(document['showEmailInProfile'], false);
  });
  test(
      'changing visibility preserves email consent and accepts explicit false values',
      () {
    expect(profileSettingsPatch(profileVisibility: ProfileVisibility.private),
        {'profileVisibility': 'private', 'privacy': {'privateAccount': true}});
    expect(profileSettingsPatch(twoFactorEnabled: false),
        {'twoFactorEnabled': false});
    expect(profileSettingsPatch(), isEmpty);
  });
  test('security checklist is complete without an app lock', () {
    const checklist = SecurityChecklist(
        hasEmail: true,
        emailVerified: true,
        hasPhone: true,
        loginAlerts: true,
        twoFactor: true);
    expect(checklist.completed, 5);
    expect(SecurityChecklist.total, 5);
  });
}
