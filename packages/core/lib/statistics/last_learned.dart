import 'package:path/path.dart' as p;

import '../paths/deck_paths.dart';

/// Returns when [deckPath] was last learned: the newest modification time
/// among its statistics files, or `null` when it has none.
///
/// Core has no `dart:io`, so the caller does the listing. [statisticsFileNames]
/// are the bare file names found in the deck's own folder (as a directory
/// listing returns them); only the ones [DeckPaths.isStatisticsFileFor]
/// recognises as belonging to this deck are considered, so a neighbouring
/// deck's files (`Foo2.sta` next to `Foo.vok`) never count. [timeOf] resolves
/// one of those file names to its modification time, or `null` when it could
/// not be read — such a file is skipped rather than failing the whole lookup.
DateTime? lastLearned({
  required String deckPath,
  required Iterable<String> statisticsFileNames,
  required DateTime? Function(String fileName) timeOf,
  p.Context? context,
}) {
  DateTime? newest;
  for (final String fileName in statisticsFileNames) {
    if (!DeckPaths.isStatisticsFileFor(deckPath, fileName, context: context)) {
      continue;
    }
    final DateTime? time = timeOf(fileName);
    if (time == null) {
      continue;
    }
    if (newest == null || time.isAfter(newest)) {
      newest = time;
    }
  }
  return newest;
}
