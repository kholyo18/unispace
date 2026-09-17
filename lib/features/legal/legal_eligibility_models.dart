import 'legal_consent_models.dart';

/// A strict consumer of the V2 server contract. Never infer eligibility locally.
enum LegalEligibilityStep {
  notConfigured,
  birthDateRequired,
  underMinimumAge,
  personalConsentRequired,
  independentConsentRequired,
  representativeRequired,
  ready,
}

class LegalEligibilityStatus {
  const LegalEligibilityStatus._({
    required this.uid,
    required this.step,
    this.policy,
    this.declarationContext,
    this.acceptanceContext,
    this.phase,
  });

  final String uid;
  final LegalEligibilityStep step;
  final LegalPolicy? policy;
  final String? declarationContext;
  final String? acceptanceContext;
  final String? phase;

  bool get canProceed => step == LegalEligibilityStep.ready;
  bool get needsPersonalAcceptance =>
      step == LegalEligibilityStep.personalConsentRequired ||
      step == LegalEligibilityStep.independentConsentRequired;

  factory LegalEligibilityStatus.fromMap(Object? raw) {
    final data = legalEligibilityMap(raw);
    final uid = data['uid'];
    if (uid is! String || uid.isEmpty || uid.length > 128 ||
        uid.trim() != uid || uid.contains('/') || uid == '.' || uid == '..' ||
        data['schemaVersion'] != 2 || data['rulesVersion'] != 'dz-18-19-v1' ||
        data['timeZone'] != 'Africa/Algiers') {
      throw const FormatException('Unsupported eligibility identity or rules.');
    }
    const states = <String, LegalEligibilityStep>{
      'not_configured': LegalEligibilityStep.notConfigured,
      'birth_date_required': LegalEligibilityStep.birthDateRequired,
      'under_minimum_age': LegalEligibilityStep.underMinimumAge,
      'personal_consent_required': LegalEligibilityStep.personalConsentRequired,
      'independent_consent_required': LegalEligibilityStep.independentConsentRequired,
      'representative_required': LegalEligibilityStep.representativeRequired,
      'ready': LegalEligibilityStep.ready,
    };
    final step = states[data['state']];
    if (step == null || data['enabled'] is! bool || data['canAccept'] is! bool ||
        data['canProceed'] is! bool || data['userAccepted'] is! bool) {
      throw const FormatException('Invalid eligibility state.');
    }
    if (step == LegalEligibilityStep.notConfigured) {
      if (data['enabled'] != false || data['canAccept'] != false ||
          data['canProceed'] != false || data['userAccepted'] != false ||
          data['policy'] != null || data['phase'] != null ||
          data['declarationContext'] != null || data['acceptanceContext'] != null ||
          data['representativeVerified'] != null) {
        throw const FormatException('Inconsistent disabled eligibility state.');
      }
      return LegalEligibilityStatus._(uid: uid, step: step);
    }
    if (data['enabled'] != true) {
      throw const FormatException('Disabled eligibility cannot grant access.');
    }
    final policy = LegalPolicy.fromMap(data['policy']);
    final declarationContext = _hash(data['declarationContext']);
    if (step == LegalEligibilityStep.birthDateRequired ||
        step == LegalEligibilityStep.underMinimumAge) {
      if (data['canAccept'] != false || data['canProceed'] != false ||
          data['userAccepted'] != false || data['phase'] != null ||
          data['acceptanceContext'] != null || data['representativeVerified'] != null) {
        throw const FormatException('Inconsistent birth-date restriction.');
      }
      return LegalEligibilityStatus._(uid: uid, step: step, policy: policy,
          declarationContext: declarationContext);
    }
    final phase = data['phase'];
    final represented = phase == 'represented';
    if ((!represented && phase != 'independent') || data['canAccept'] != true ||
        data['representativeVerified'] is! bool ||
        (!represented && data['representativeVerified'] != false)) {
      throw const FormatException('Invalid eligibility phase.');
    }
    final accepted = data['userAccepted'] == true;
    final verified = data['representativeVerified'] == true;
    final proceed = accepted && (!represented || verified);
    final expectedStep = proceed ? LegalEligibilityStep.ready : accepted
        ? LegalEligibilityStep.representativeRequired : represented
        ? LegalEligibilityStep.personalConsentRequired
        : LegalEligibilityStep.independentConsentRequired;
    if (step != expectedStep || data['canProceed'] != proceed) {
      throw const FormatException('Inconsistent eligibility decisions.');
    }
    return LegalEligibilityStatus._(
      uid: uid, step: step, policy: policy, phase: phase as String,
      declarationContext: declarationContext,
      acceptanceContext: _hash(data['acceptanceContext']),
    );
  }
}

Map<String, dynamic> legalEligibilityMap(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Invalid eligibility response.');
  }
  return Map<String, dynamic>.from(value);
}

String _hash(Object? value) {
  if (value is! String || value.length != 64 ||
      !RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
    throw const FormatException('Invalid eligibility context.');
  }
  return value;
}

/// Normalizes digits and validates calendar syntax only. The server determines
/// future dates, the user's age and the 18/19 thresholds using its own calendar.
String? legalBirthDateFromFields({
  required String year,
  required String month,
  required String day,
}) {
  String normalize(String text) => String.fromCharCodes(text.trim().runes.map((c) {
    if (c >= 0x660 && c <= 0x669) return c - 0x660 + 0x30;
    if (c >= 0x6f0 && c <= 0x6f9) return c - 0x6f0 + 0x30;
    return c;
  }));
  final y = normalize(year), m = normalize(month), d = normalize(day);
  if (y.length != 4 || m.isEmpty || m.length > 2 || d.isEmpty || d.length > 2 ||
      !RegExp(r'^[0-9]+$').hasMatch(y + m + d)) return null;
  final yy = int.parse(y), mm = int.parse(m), dd = int.parse(d);
  if (yy < 1900 || yy > 9999 || mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;
  final date = DateTime.utc(yy, mm, dd);
  if (date.year != yy || date.month != mm || date.day != dd) return null;
  return '$y-${m.padLeft(2, '0')}-${d.padLeft(2, '0')}';
}

class LegalEligibilityReloadRequired implements Exception {
  const LegalEligibilityReloadRequired();
}

class LegalBirthDateRejected implements Exception {
  const LegalBirthDateRejected();
}
