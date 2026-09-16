import 'dart:convert';
import 'package:crypto/crypto.dart';

Map<String, dynamic> _map(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Invalid legal response object.');
  }
  return Map<String, dynamic>.from(value);
}

String _text(Map<String, dynamic> map, String key, {int maximum = 131072}) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty || value.length > maximum) {
    throw FormatException('Invalid legal field: $key');
  }
  return value;
}

String _hash(Map<String, dynamic> map, String key) {
  final value = _text(map, key, maximum: 64);
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
    throw FormatException('Invalid legal hash: $key');
  }
  return value;
}

class LegalDocument {
  const LegalDocument({required this.id, required this.version, required this.title,
    required this.body, required this.contentHash});
  final String id;
  final String version;
  final String title;
  final String body;
  final String contentHash;

  factory LegalDocument.fromMap(Object? raw) {
    final data = _map(raw);
    final id = _text(data, 'id');
    final version = _text(data, 'version', maximum: 80);
    final body = _text(data, 'body');
    final hash = _hash(data, 'sha256');
    if (!const ['terms', 'community', 'privacy'].contains(id) ||
        !RegExp(r'^[A-Za-z0-9._-]{1,80}$').hasMatch(version) || version.trim() != version ||
        sha256.convert(utf8.encode(body)).toString() != hash) {
      throw const FormatException('Invalid legal document identity.');
    }
    return LegalDocument(id: id, version: version,
      title: _text(data, 'title', maximum: 300), body: body, contentHash: hash);
  }
}

class LegalPolicy {
  LegalPolicy({required this.fingerprint, required this.operatorName,
    required this.publishedAt, required List<LegalDocument> documents})
      : documents = List.unmodifiable(documents);
  final String fingerprint;
  final String operatorName;
  final DateTime publishedAt;
  final List<LegalDocument> documents;

  factory LegalPolicy.fromMap(Object? raw) {
    final data = _map(raw);
    final list = data['documents'];
    if (data['schemaVersion'] != 1 || data['language'] != 'ar' || list is! List || list.length != 3 ||
        utf8.encode(jsonEncode(data)).length > 132000) {
      throw const FormatException('Invalid legal publication.');
    }
    final documents = list.map(LegalDocument.fromMap).toList();
    if (documents.map((d) => d.id).toSet().length != 3) {
      throw const FormatException('Duplicate legal document.');
    }
    final date = _text(data, 'publishedAt');
    final published = DateTime.tryParse(date);
    if (published == null || !published.isUtc || published.toIso8601String() != date) {
      throw const FormatException('Invalid publication time.');
    }
    return LegalPolicy(fingerprint: _hash(data, 'fingerprint'),
      operatorName: _text(data, 'operatorName', maximum: 300), publishedAt: published,
      documents: ['terms', 'community', 'privacy'].map((id) => documents.singleWhere((d) => d.id == id)).toList());
  }
}

class LegalConsentStatus {
  const LegalConsentStatus({required this.uid, required this.enabled, required this.required,
    this.policy, this.acceptanceContext});
  final String uid;
  final bool enabled;
  final bool required;
  final LegalPolicy? policy;
  final String? acceptanceContext;

  factory LegalConsentStatus.fromMap(Object? raw) {
    final data = _map(raw);
    final uid = _text(data, 'uid', maximum: 128);
    if (uid.contains('/') || data['enabled'] is! bool || data['required'] is! bool) {
      throw const FormatException('Invalid consent state.');
    }
    if (data['enabled'] == false) {
      if (data['required'] != false || data['policy'] != null || data['acceptanceContext'] != null) {
        throw const FormatException('Inconsistent disabled consent state.');
      }
      return LegalConsentStatus(uid: uid, enabled: false, required: false);
    }
    return LegalConsentStatus(uid: uid, enabled: true, required: data['required'] as bool,
      policy: LegalPolicy.fromMap(data['policy']), acceptanceContext: _hash(data, 'acceptanceContext'));
  }
}

class LegalConsentReloadRequired implements Exception {
  const LegalConsentReloadRequired();
}
