import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/ui/settings/account_profile_fields.dart';

void main() {
  test('signup document populates account fields and keeps the reserved handle',
      () {
    final data = <String, dynamic>{
      'username': 'amine_42',
      'firstName': 'Amine',
      'lastName': 'B',
      'college': 'Science',
      'department': 'Computer science',
      'level': 'L2',
      'birthDate': Timestamp.fromDate(DateTime(2003, 5, 12)),
    };
    final profile = AccountProfileFields(data);
    expect(profile.username, 'amine_42');
    expect(profile.faculty, 'Science');
    expect(profile.department, 'Computer science');
    expect(profile.studyLevel, 'L2');
    expect(profile.birthDate, '2003-05-12');
    data.addAll(
        {'firstName': 'New', 'lastName': 'Name', 'displayName': 'New Name'});
    expect(AccountProfileFields(data).username, 'amine_42');
  });

  test(
      'existing editor values take precedence including deliberate empty values',
      () {
    final profile = AccountProfileFields({
      'faculty': '',
      'college': 'Old college',
      'studyLevel': 'M1',
      'level': 'L2',
      'birthDate': '2002-04-03',
    });
    expect(profile.faculty, '');
    expect(profile.studyLevel, 'M1');
    expect(profile.birthDate, '2002-04-03');
  });

  test(
      'legacy academic fields and absent username are handled without guessing',
      () {
    final profile = AccountProfileFields({
      'displayName': 'Full Name',
      'userName': 'Full Name',
      'academic': {'college': 'Science', 'level': 'L3'},
    });
    expect(profile.username, '');
    expect(profile.faculty, 'Science');
    expect(profile.studyLevel, 'L3');
    expect(profile.birthDate, '');
    expect(AccountProfileFields(null).username, '');
  });
}
