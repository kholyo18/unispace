import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/ui/settings/algerian_phone.dart';

void main() {
  test('normalizes supported Algerian mobile formats', () {
    expect(normalizeAlgerianMobile('0555 12 34 56'), '+213555123456');
    expect(normalizeAlgerianMobile('6 61 23 45 67'), '+213661234567');
    expect(normalizeAlgerianMobile('+213 770 12 34 56'), '+213770123456');
    expect(normalizeAlgerianMobile('00213 (0) 555-123-456'), '+213555123456');
    expect(normalizeAlgerianMobile('٠٦٦١٢٣٤٥٦٧'), '+213661234567');
  });

  test('rejects foreign, landline, malformed and short numbers', () {
    expect(normalizeAlgerianMobile('+33612345678'), isNull);
    expect(normalizeAlgerianMobile('021123456'), isNull);
    expect(normalizeAlgerianMobile('+213123'), isNull);
    expect(normalizeAlgerianMobile('+213855123456'), isNull);
    expect(normalizeAlgerianMobile(''), isNull);
  });
}
