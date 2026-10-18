import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/community/media/video_values.dart';
import 'package:UniSpace/features/community/polls/poll_values.dart';

void main() {
  group('video controls preserve existing timing', () {
    test('compact labels retain minute wrapping', () {
      expect(compactVideoDuration(Duration.zero), '0:00');
      expect(compactVideoDuration(const Duration(seconds: 65)), '1:05');
      expect(
          compactVideoDuration(
              const Duration(hours: 1, minutes: 2, seconds: 3)),
          '2:03');
    });
    test('progress handles zero duration, bounds and intermediate position',
        () {
      expect(videoProgressRatio(const Duration(seconds: 1), Duration.zero), 0);
      expect(
          videoProgressRatio(
              const Duration(seconds: -1), const Duration(seconds: 10)),
          0);
      expect(
          videoProgressRatio(
              const Duration(seconds: 4), const Duration(seconds: 10)),
          .4);
      expect(
          videoProgressRatio(
              const Duration(seconds: 12), const Duration(seconds: 10)),
          1);
    });
    test('completion retains 300 ms boundary and rejects unknown duration', () {
      expect(videoPlaybackEnded(Duration.zero, Duration.zero), isFalse);
      expect(
          videoPlaybackEnded(
              const Duration(milliseconds: 9699), const Duration(seconds: 10)),
          isFalse);
      expect(
          videoPlaybackEnded(
              const Duration(milliseconds: 9700), const Duration(seconds: 10)),
          isTrue);
      expect(
          videoPlaybackEnded(
              const Duration(seconds: 11), const Duration(seconds: 10)),
          isTrue);
      expect(
          videoPlaybackEnded(Duration.zero, const Duration(milliseconds: 200)),
          isTrue);
    });
  });
  group('poll presentation preserves input and result scales', () {
    test('slider emoji boundaries', () {
      final cases = <double, String>{
        0: '😣',
        19.99: '😣',
        20: '😕',
        39.99: '😕',
        40: '😐',
        59.99: '😐',
        60: '🙂',
        79.99: '🙂',
        80: '😍',
        100: '😍'
      };
      for (final entry in cases.entries) {
        expect(pollSliderEmoji(entry.key), entry.value);
      }
    });
    test('slider color boundaries', () {
      expect(pollSliderColor(24.99), Colors.redAccent);
      expect(pollSliderColor(25), Colors.orangeAccent);
      expect(pollSliderColor(49.99), Colors.orangeAccent);
      expect(pollSliderColor(50), const Color(0xFF26A69A));
      expect(pollSliderColor(74.99), const Color(0xFF26A69A));
      expect(pollSliderColor(75), const Color(0xFF00BFA5));
      expect(pollSliderColor(100), const Color(0xFF00BFA5));
    });
    test('result emoji resampling preserves midpoint, endpoints and size clamp',
        () {
      expect(pollScaleEmojis(1), ['🙂']);
      expect(pollScaleEmojis(0), ['🙂']);
      expect(pollScaleEmojis(1, alternate: true), ['😐']);
      expect(pollScaleEmojis(3), ['😠', '🙂', '😁']);
      expect(pollScaleEmojis(3, alternate: true), ['😭', '😐', '😄']);
      expect(
          pollScaleEmojis(5, alternate: true), ['😭', '😢', '😐', '🙂', '😄']);
      expect(pollScaleEmojis(11).length, 10);
    });
  });
  group('poll answer callable schema', () {
    test('scalars remain unchanged', () {
      for (final value in [null, 'answer', 0, 50.5, false]) {
        expect(serializePollAnswer(value), value);
      }
    });
    test('nested dates, times and grid selections preserve their wire shape',
        () {
      final input = {
        0: DateTime.utc(2026, 10, 3),
        1: const TimeOfDay(hour: 8, minute: 7),
        2: {
          0: {1, 3},
          1: <int>{}
        },
        3: [true, null, DateTime.utc(2026, 10, 4)],
      };
      expect(serializePollAnswer(input), {
        '0': '2026-10-03T00:00:00.000Z',
        '1': {'hour': 8, 'minute': 7},
        '2': {
          '0': [1, 3],
          '1': <int>[]
        },
        '3': [true, null, '2026-10-04T00:00:00.000Z'],
      });
      expect(input[2], {
        0: {1, 3},
        1: <int>{}
      });
    });
    test('unsupported values preserve fallback string behavior', () {
      expect(serializePollAnswer(const Duration(seconds: 1)), '0:00:01.000000');
    });
  });
}
