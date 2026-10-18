/// Normalizes an Algerian mobile number to E.164 (`+213XXXXXXXXX`).
///
/// Accepts the common local (`05/06/07...`) and international (`+213...`,
/// `00213...`) forms. Landlines and non-Algerian numbers are rejected because
/// this value is used for SMS verification and account recovery.
String? normalizeAlgerianMobile(String input) {
  const localizedDigits = <String, String>{
    '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
    '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
    '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
  };

  var value = input.trim().split('').map((character) =>
      localizedDigits[character] ?? character).join();
  value = value.replaceAll(RegExp(r'[\s\-().]'), '');
  if (value.startsWith('+')) value = value.substring(1);

  if (value.startsWith('00213')) {
    value = value.substring(5);
  } else if (value.startsWith('213')) {
    value = value.substring(3);
  } else if (value.startsWith('0')) {
    value = value.substring(1);
  }

  // Some users enter the national trunk prefix after +213.
  if (value.startsWith('0')) value = value.substring(1);
  if (!RegExp(r'^[567][0-9]{8}$').hasMatch(value)) return null;
  return '+213$value';
}
