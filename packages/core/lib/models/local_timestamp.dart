/// A moment recorded as local wall-clock time plus its UTC offset.
library;

/// A moment as the local time it was recorded at, with that time's UTC offset,
/// to the second: `2026-09-25T16:32:11+02:00`.
///
/// This is the shape of a deck's `lastEdited`. Keeping the offset rather than
/// converting to UTC lets the file say both what the clock read on the machine
/// that made the edit and which instant that was, and it makes the stored text
/// survive a decode and re-encode unchanged on a machine in another time zone.
final class LocalTimestamp {
  const LocalTimestamp._(this.instant, this.offset);

  /// Records [time] as its own wall-clock reading and UTC offset, dropping
  /// anything finer than a second. A UTC [time] records a zero offset.
  factory LocalTimestamp.of(DateTime time) {
    final DateTime whole = time.subtract(
      Duration(
        milliseconds: time.millisecond,
        microseconds: time.microsecond,
      ),
    );
    return LocalTimestamp._(
      whole.toUtc(),
      whole.isUtc ? Duration.zero : whole.timeZoneOffset,
    );
  }

  /// Reads [text] in exactly the shape [toString] writes, or returns `null`.
  ///
  /// Nothing looser is accepted — no `Z`, no fractional seconds, no missing
  /// offset, no calendar date that does not exist — so whatever is accepted
  /// re-encodes to the same text.
  static LocalTimestamp? tryParse(String text) {
    final RegExpMatch? match = _shape.firstMatch(text);
    if (match == null) {
      return null;
    }
    int part(int group) => int.parse(match.group(group)!);
    final int year = part(1);
    final int month = part(2);
    final int day = part(3);
    final int hour = part(4);
    final int minute = part(5);
    final int second = part(6);
    final int offsetHours = part(8);
    final int offsetMinutes = part(9);
    if (hour > 23 || minute > 59 || second > 59 || offsetMinutes > 59) {
      return null;
    }
    // DateTime normalises an impossible date (February 30th becomes March
    // 2nd) instead of refusing it, so a date only counts when it comes back
    // as written.
    final DateTime wallClock = DateTime.utc(
      year,
      month,
      day,
      hour,
      minute,
      second,
    );
    if (wallClock.year != year ||
        wallClock.month != month ||
        wallClock.day != day) {
      return null;
    }
    final Duration magnitude = Duration(
      hours: offsetHours,
      minutes: offsetMinutes,
    );
    final Duration offset = match.group(7) == '-' ? -magnitude : magnitude;
    return LocalTimestamp._(wallClock.subtract(offset), offset);
  }

  static final RegExp _shape = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})([+-])(\d{2}):(\d{2})$',
  );

  /// The moment itself, in UTC.
  final DateTime instant;

  /// How far the recording clock was ahead of UTC (negative when behind).
  final Duration offset;

  /// The moment on this machine's clock, for display.
  DateTime toLocal() => instant.toLocal();

  @override
  bool operator ==(Object other) {
    return other is LocalTimestamp &&
        other.instant == instant &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(instant, offset);

  /// The stored form, e.g. `2026-09-25T16:32:11+02:00`.
  @override
  String toString() {
    String two(int value) => value.toString().padLeft(2, '0');
    final DateTime wallClock = instant.add(offset);
    final int offsetMinutes = offset.inMinutes.abs();
    return '${wallClock.year.toString().padLeft(4, '0')}-'
        '${two(wallClock.month)}-${two(wallClock.day)}'
        'T${two(wallClock.hour)}:${two(wallClock.minute)}:'
        '${two(wallClock.second)}'
        '${offset.isNegative ? '-' : '+'}'
        '${two(offsetMinutes ~/ 60)}:${two(offsetMinutes % 60)}';
  }
}
