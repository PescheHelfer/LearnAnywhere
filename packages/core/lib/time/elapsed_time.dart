/// The one text form every time readout uses.
library;

/// Formats [elapsed] as `m:ss` below an hour and `h:mm:ss` from an hour on,
/// dropping any part second.
///
/// Every time pill — unit, sitting, statistics and total time — shows its
/// figure this way, so a learner reads all clocks alike.
String formatElapsedTime(Duration elapsed) {
  final int seconds = elapsed.inSeconds % 60;
  final int minutes = elapsed.inMinutes % 60;
  final int hours = elapsed.inHours;
  final String ss = seconds.toString().padLeft(2, '0');
  if (hours == 0) {
    return '$minutes:$ss';
  }
  return '$hours:${minutes.toString().padLeft(2, '0')}:$ss';
}
