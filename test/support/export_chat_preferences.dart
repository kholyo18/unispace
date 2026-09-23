// Exports real production-client payloads for the emulator contract test.
// These are synthetic preferences; no Firebase credentials or real users.
import 'dart:convert';
import '../../lib/services/chat_preferences_client.dart';

Future<void> main() async {
  const uid = '1.preferences.viewer.`dot';
  final writes = <String, Map<String, dynamic>>{};
  var label = '';
  final client = ChatPreferencesClient(
    expectedUid: uid,
    currentUid: () => uid,
    sessionKey: () => 'fixture',
    merge: (data) async {
      writes[label] = data;
    },
    serverTimestamp: () => {'__operation': 'serverTimestamp'},
    deleteField: () => {'__operation': 'delete'},
  );
  label = 'nickname';
  await client.setNickname('  Study friend  ');
  label = 'nicknameEmpty';
  await client.setNickname('');
  label = 'mute';
  await client.setMuted(true);
  label = 'unmute';
  await client.setMuted(false);
  label = 'translate';
  await client.setAutoTranslate(true);
  label = 'translateOff';
  await client.setAutoTranslate(false);
  label = 'solid';
  await client.setBubbleColor(0xFF112233);
  label = 'gradient';
  await client.setBubbleGradient([0xFF001100, 0xFF002200]);
  label = 'preset';
  await client.setWallpaper('ocean');
  label = 'photo';
  await client.setWallpaper('photo', photoUrl: 'https://example.test/photo');
  label = 'clear';
  await client.clearHistory();
  client.dispose();
  print(jsonEncode({'uid': uid, 'writes': writes}));
}
