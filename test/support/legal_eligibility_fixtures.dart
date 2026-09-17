import 'dart:convert';
import 'package:crypto/crypto.dart';

// In-memory synthetic fixtures only. These are not publishable legal documents,
// identity evidence or real representative approvals. No fixture reaches Firebase.
Map<String, dynamic> eligibilityResponse(String state, {
  String uid = 'test-alice', String version = 'test-1',
  String? phase, bool? representativeVerified,
}) {
  final common = <String, dynamic>{
    'schemaVersion': 2, 'uid': uid, 'rulesVersion': 'dz-18-19-v1',
    'timeZone': 'Africa/Algiers',
  };
  if (state == 'not_configured') {
    return {...common, 'enabled': false, 'state': state, 'canAccept': false,
      'canProceed': false, 'userAccepted': false};
  }
  final documents = ['terms', 'community', 'privacy'].map((id) {
    final body = 'نص اختبار فقط $id $version';
    return <String, dynamic>{'id': id, 'version': version, 'title': 'وثيقة $id',
      'body': body, 'sha256': sha256.convert(utf8.encode(body)).toString()};
  }).toList();
  final identity = <String, dynamic>{'schemaVersion': 1, 'language': 'ar',
    'operatorName': 'مشغّل اختبار — ليس جهة فعلية',
    'publishedAt': '2026-09-15T12:00:00.000Z', 'documents': documents};
  final fingerprint = sha256.convert(utf8.encode(jsonEncode(identity))).toString();
  final policy = {...identity, 'fingerprint': fingerprint};
  final publication = <String, dynamic>{'enabled': true, 'state': state,
    'policy': policy, 'declarationContext': sha256.convert(utf8.encode('$uid:$version:date')).toString()};
  if (state == 'birth_date_required' || state == 'under_minimum_age') {
    return {...common, ...publication, 'canAccept': false,
      'canProceed': false, 'userAccepted': false};
  }
  final actualPhase = phase ??
      (state == 'personal_consent_required' || state == 'representative_required'
          ? 'represented' : 'independent');
  return {...common, ...publication, 'phase': actualPhase, 'canAccept': true,
    'canProceed': state == 'ready',
    'userAccepted': state == 'ready' || state == 'representative_required',
    'representativeVerified': representativeVerified ??
        (state == 'ready' && actualPhase == 'represented'),
    'acceptanceContext': sha256.convert(utf8.encode('$uid:$version:$actualPhase')).toString()};
}
