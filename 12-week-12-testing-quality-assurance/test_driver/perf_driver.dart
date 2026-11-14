import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

// Menyimpan ringkasan timeline profile mode ke build/perf/<label>.json.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final label = Platform.environment['PERF_LABEL'] ?? 'run';
    final dir = Directory('build/perf')..createSync(recursive: true);
    for (final entry in data.entries) {
      if (entry.value is! Map<String, dynamic>) continue;
      final value = entry.value as Map<String, dynamic>;
      if (value.containsKey('traceEvents')) {
        final summary = driver.TimelineSummary.summarize(
          driver.Timeline.fromJson(value),
        );
        await summary.writeTimelineToFile(
          '$label-${entry.key}',
          destinationDirectory: dir.path,
          pretty: true,
          includeSummary: true,
        );
      } else {
        File(
          '${dir.path}/$label-${entry.key}.json',
        ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(value));
      }
    }
  },
);
