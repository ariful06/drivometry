import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Measures screen build and DB query timing. Logs only in debug.
class PerformanceService {
  PerformanceService();

  final _buildStops = <String, DateTime>{};
  final _queryStops = <String, DateTime>{};

  /// Call when starting a screen build. Pair with [endBuild].
  void startBuild(String screenName) {
    if (!kDebugMode) return;
    _buildStops[screenName] = DateTime.now();
  }

  /// Call when the screen build finishes. Logs duration in debug.
  void endBuild(String screenName) {
    if (!kDebugMode) return;
    final start = _buildStops.remove(screenName);
    if (start != null) {
      final ms = DateTime.now().difference(start).inMilliseconds;
      dev.log('Build $screenName: ${ms}ms', name: 'PerformanceService');
    }
  }

  /// Call when starting a DB query. Pair with [endQuery].
  void startQuery(String queryName) {
    if (!kDebugMode) return;
    _queryStops[queryName] = DateTime.now();
  }

  /// Call when the query finishes. Logs duration in debug.
  void endQuery(String queryName) {
    if (!kDebugMode) return;
    final start = _queryStops.remove(queryName);
    if (start != null) {
      final ms = DateTime.now().difference(start).inMilliseconds;
      dev.log('Query $queryName: ${ms}ms', name: 'PerformanceService');
    }
  }
}
