import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/ui/settings/profile_privacy.dart';
import 'package:UniSpace/ui/settings/profile_settings_patch.dart';
import 'package:UniSpace/ui/settings/app_settings.dart';
void main() {
  test('old private and hidden email settings remain effective', () {
    final p = ProfilePrivacy.fromDocument({'profileVisibility': 'private', 'showEmailInProfile': false});
    expect(p.isPrivate, true); expect(p.showEmail, false);
  });
  test('canonical settings override stale legacy copies', () {
    final p = ProfilePrivacy.fromDocument({'profileVisibility': 'public', 'showEmailInProfile': true,
      'privacy': {'privateAccount': true, 'showEmailOnProfile': false}});
    expect(p.isPrivate, true); expect(p.showEmail, false);
  });
  test('email requires explicit consent', () {
    expect(ProfilePrivacy.fromDocument(null).showEmail, false);
    expect(ProfilePrivacy.fromDocument({'privacy': {'showEmailOnProfile': 'true'}}).showEmail, false);
  });
  test('legacy settings writer drives actual profile visibility and email', () {
    final patch = profileSettingsPatch(profileVisibility: ProfileVisibility.private, showEmailInProfile: false);
    final p = ProfilePrivacy.fromDocument(patch);
    expect(p.isPrivate, true); expect(p.showEmail, false);
    final public = ProfilePrivacy.fromDocument(profileSettingsPatch(profileVisibility: ProfileVisibility.public, showEmailInProfile: true));
    expect(public.isPrivate, false); expect(public.showEmail, true);
  });
}
