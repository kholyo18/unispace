import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Opt-in, aggregate timings only: never logs account or content data.
class PerformanceProbe {
  static const enabled = bool.fromEnvironment('UNISPACE_PERF');
  static void install() {
    if (!enabled) return;
    final builds = <int>[];
    final rasters = <int>[];
    SchedulerBinding.instance.addTimingsCallback((frames) {
      for (final frame in frames) {
        builds.add(frame.buildDuration.inMicroseconds);
        rasters.add(frame.rasterDuration.inMicroseconds);
      }
      if (builds.length < 120) return;
      builds.sort();
      rasters.sort();
      final index = ((builds.length - 1) * .95).round();
      debugPrint('[PERF] frames=${builds.length} '
          'build_p95_us=${builds[index]} raster_p95_us=${rasters[index]}');
      builds.clear();
      rasters.clear();
    });
  }

  static void elapsed(String stage, Stopwatch watch) {
    if (enabled) debugPrint('[PERF] $stage ms=${watch.elapsedMilliseconds}');
  }
}
